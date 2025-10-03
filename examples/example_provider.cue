package examples

import (
	"list"

	opm "github.com/open-platform-model/core"
	elements "github.com/open-platform-model/core/elements"
)

//////////////////////////////////////////////////////////////////
// Example Provider
//////////////////////////////////////////////////////////////////

// Example: Kubernetes Provider Implementation
#KubernetesProvider: opm.#Provider & {
	#metadata: {
		name:        "kubernetes"
		description: "Kubernetes platform provider"
		version:     "1.0.0"
		minVersion:  "1.27.0"
	}

	// Register all transformers
	// No need to inject registry - transformers just declare requirements
	transformers: {
		"k8s.io/api/apps/v1.Deployment": #DeploymentTransformer
		// "k8s.io/api/apps/v1.StatefulSet":           #StatefulSetTransformer
		// "k8s.io/api/apps/v1.DaemonSet":             #DaemonTransformer
		// "k8s.io/api/batch/v1.Job":                  #JobTransformer
		// "k8s.io/api/batch/v1.CronJob":              #CronJobTransformer
		"k8s.io/api/core/v1.PersistentVolumeClaim": #PersistentVolumeClaimTransformer
		// "k8s.io/api/core/v1.Service":                    #ServiceTransformer
		// ... more transformers
	}

	// Provider-specific render implementation
	render: {
		// module: myApp
		module: opm.#Module

		// Optimized: Build primitive->transformer index once for all components
		_primitiveToTransformer: {
			for tName, transformer in transformers {
				for req in transformer.required {
					(req): tName
				}
			}
		}

		// Process each component and generate resources
		resources: list.FlattenN([
			for _, component in module.components {
				// Optimized: Use pre-built index instead of #SelectTransformer
				let primitives = component.#primitiveElements
				[
					for primitiveFQN in primitives
					if _primitiveToTransformer[primitiveFQN] != _|_ {
						let tName = _primitiveToTransformer[primitiveFQN]
						let transformer = transformers[tName]
						(transformer & {
							transform: {
								component: component
								context: opm.#ProviderContext & {
									name:       module.#metadata.name
									namespace:  module.#metadata.namespace
									_module:    module
									_component: component
								}
							}
						}).transform.output
					},
				]
			},
		], 1)

		// Kubernetes List format
		output: {
			#apiVersion: "v1"
			#kind:       "List"
			items:       resources
		}
	}
}

/////////////////////////////////////////////////////////////////
//// Example Transformer Implementations
/////////////////////////////////////////////////////////////////
// These are examples showing how platform-specific transformers
// could be implemented. Actual implementations would be in
// platform-specific provider packages.

// Example: Kubernetes Deployment Transformer
#DeploymentTransformer: opm.#Transformer & {
	#kind:       "Deployment"
	#apiVersion: "k8s.io/api/apps/v1"

	// This transformer specifically handles StatelessWorkload primitive
	required: ["elements.opm.dev/core/v1alpha1.Container"]
	optional: [
		"elements.opm.dev/core/v1alpha1.SidecarContainers",
		"elements.opm.dev/core/v1alpha1.InitContainers",
		"elements.opm.dev/core/v1alpha1.Replicas",
		"elements.opm.dev/core/v1alpha1.RestartPolicy",
		"elements.opm.dev/core/v1alpha1.UpdateStrategy",
		"elements.opm.dev/core/v1alpha1.HealthCheck",
	]

	transform: {
		component: opm.#Component
		context:   opm.#ProviderContext

		// Extract elements (simplified example)
		let _workload = component.stateless
		let _sidecarContainers = component.sidecarContainers | *[]
		let _initContainers = component.initContainers | *[]
		let _replicas = component.replicas | *{count: 1}

		output: {
			#apiVersion: #apiVersion
			#kind:       #kind
			metadata: {
				name:        context.componentMetadata.name
				namespace:   context.namespace
				labels:      context.unifiedLabels
				annotations: context.unifiedAnnotations
			}
			spec: {
				replicas: _replicas.count
				template: {
					spec: {
						containers: list.Concat([[_workload.container], _sidecarContainers])
						if len(_initContainers) > 0 {
							initContainers: _initContainers
						}
					}
				}
			}
		}
	}
}

// Example: Kubernetes PersistentVolumeClaim Transformer
#PersistentVolumeClaimTransformer: opm.#Transformer & {
	#kind:       "PersistentVolumeClaim"
	#apiVersion: "k8s.io/api/core/v1"

	// This transformer specifically handles Volume primitive
	required: ["elements.opm.dev/core/v1alpha1.Volume"]
	optional: []

	transform: {
		component: opm.#Component
		context:   opm.#ProviderContext

		// Extract volumes
		let _volumes = component.volumes

		output: [
			for volumeName, volumeSpec in _volumes {
				if volumeSpec.persistentClaim != _|_ {
					#apiVersion: #apiVersion
					#kind:       #kind
					metadata: {
						name:        "\(context.componentMetadata.name)-\(volumeName)"
						namespace:   context.namespace
						labels:      context.unifiedLabels
						annotations: context.unifiedAnnotations
					}
					spec: {
						accessModes: volumeSpec.accessModes
						resources: requests: storage: volumeSpec.size
						storageClassName: volumeSpec.storageClass
					}
				}
			},
		]
	}
}

//////////////////////////////////////////////////////////////////
//// Platform Catalog Example
//////////////////////////////////////////////////////////////////

// Example Platform Catalog with Kubernetes provider
examplePlatformCatalog: opm.#PlatformCatalog & {
	#metadata: {
		name:        "example-k8s-platform"
		version:     "1.0.0"
		description: "Example Kubernetes platform with core elements"
		labels: {
			"platform.opm.dev/type": "kubernetes"
			environment:             "production"
		}
	}

	// All available elements in this platform
	#availableElements: elements.#CoreElementRegistry

	// Available providers
	providers: {
		kubernetes: #KubernetesProvider
	}

	// Modules registered in catalog
	modules: {
		"my-app": {
			module:         myApp
			targetProvider: "kubernetes"
		}

		"ecommerce-app": {
			module:         ecommerceApp
			targetProvider: "kubernetes"
		}

		"monitoring-stack": {
			module:         monitoringStack
			targetProvider: "kubernetes"
		}
	}
}

//////////////////////////////////////////////////////////////////
//// Validation Examples
//////////////////////////////////////////////////////////////////

// Example 1: Validate compatible module admission
validateCompatibleModule: opm.#ValidateModuleAdmission & {
	module:   compatibleModule
	catalog:  examplePlatformCatalog
	provider: "kubernetes"
}

// Example 2: Validate incompatible module with custom element
validateIncompatibleCustomElement: opm.#ValidateModuleAdmission & {
	module:   incompatibleModuleCustomElement
	catalog:  examplePlatformCatalog
	provider: "kubernetes"
}

// Example 3: Validate incompatible module with unsupported workload
validateIncompatibleUnsupportedWorkload: opm.#ValidateModuleAdmission & {
	module:   incompatibleModuleUnsupportedWorkload
	catalog:  examplePlatformCatalog
	provider: "kubernetes"
}

// Example 4: Validate mixed compatibility module
validateMixedCompatibility: opm.#ValidateModuleAdmission & {
	module:   mixedCompatibilityModule
	catalog:  examplePlatformCatalog
	provider: "kubernetes"
}
