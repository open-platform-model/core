package core

import (
	"list"
)

/////////////////////////////////////////////////////////////////
//// Example Transformer Implementations
/////////////////////////////////////////////////////////////////
// These are examples showing how platform-specific transformers
// could be implemented. Actual implementations would be in
// platform-specific provider packages.

// Example: Kubernetes Deployment Transformer
#DeploymentTransformer: #Transformer & {
	#kind:       "Deployment"
	#apiVersion: "k8s.io/api/apps/v1"

	// This transformer specifically handles StatelessWorkload
	required: ["elements.opm.dev/core/v1alpha1.StatelessWorkload"]
	optional: [
		"elements.opm.dev/core/v1alpha1.SidecarContainers",
		"elements.opm.dev/core/v1alpha1.InitContainers",
		"elements.opm.dev/core/v1alpha1.Replicas",
		"elements.opm.dev/core/v1alpha1.UpdateStrategy",
		"elements.opm.dev/core/v1alpha1.HealthCheck",
	]

	// Default values for various traits.
	// These are automatically included for optional traits if not specified in the component.
	defaults: {...} // see #Transformer interface

	transform: {
		component: #Component
		context:   #ProviderContext

		// Extract elements with CUE defaults
		let _workload = component.stateless

		let _sidecarContainers = component.sidecarContainers | *[]
		let _initContainers = component.initContainers | *[]
		let _replicas = component.replicas | *defaults.replicas
		let _updateStrategy = component.updateStrategy | *defaults.updateStrategy
		let _healthCheck = component.healthCheck | *defaults.healthCheck

		output: {
			apiVersion: #apiVersion
			kind:       #kind
			metadata: {
				name:        context.componentMetadata.name
				namespace:   context.namespace
				labels:      context.unifiedLabels
				annotations: context.unifiedAnnotations
			}
			spec: {
				replicas: _replicas.count
				strategy: _updateStrategy
				template: {
					spec: {
						_container: _workload.container & {
							livenessProbe: _healthCheck.liveness
						}
						containers: list.Concat([_container, _sidecarContainers])
						initContainers: _initContainers
					}
				}
			}
		}
	}
}

// Example: Kubernetes PersistentVolumeClaim Transformer
#PersistentVolumeClaimTransformer: #Transformer & {
	#kind:       "PersistentVolumeClaim"
	#apiVersion: "k8s.io/api/core/v1"

	// This transformer specifically handles Volume primitive
	required: ["elements.opm.dev/core/v1alpha1.Volume"]
	optional: [
		"elements.opm.dev/core/v1alpha1.BackupPolicy",
		"elements.opm.dev/core/v1alpha1.ResourceQuota",
	]

	// Default values for various traits.
	// These are automatically included for optional traits if not specified in the component.
	defaults: {...} // see #Transformer interface

	transform: {
		component: #Component
		context:   #ProviderContext

		// Extract elements with CUE defaults
		let _volumes = component.volumes
		// let _backupPolicy = component.backupPolicy | *defaults.backupPolicy
		// let _resourceQuota = component.resourceQuota | *defaults.resourceQuota

		output: [
			for volumeName, volumeSpec in _volumes {
				if volumeSpec.persistentClaim != _|_ {
					apiVersion: #apiVersion
					kind:       #kind
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

// Example: Kubernetes Provider Implementation
#KubernetesProvider: #Provider & {
	#metadata: {
		name:        "kubernetes"
		description: "Kubernetes platform provider"
		version:     "1.0.0"
		minVersion:  "1.27.0"
	}

	#registry: #CoreElementRegistry

	// Register all transformers
	// for tk, tv in transformers: {
	// 	(tk): (tv) & {_registry: #registry}
	// }
	transformers: {
		"k8s.io/api/apps/v1.Deployment": #DeploymentTransformer & {_registry: #registry}
		// "k8s.io/api/apps/v1.StatefulSet":           #StatefulSetTransformer & {_registry: #registry}
		// "k8s.io/api/apps/v1.DaemonSet":             #DaemonSetTransformer & {_registry: #registry}
		// "k8s.io/api/batch/v1.Job":                  #JobTransformer & {_registry: #registry}
		// "k8s.io/api/batch/v1.CronJob":              #CronJobTransformer & {_registry: #registry}
		"k8s.io/api/core/v1.PersistentVolumeClaim": #PersistentVolumeClaimTransformer & {_registry: #registry}
		// "k8s.io/api/core/v1.Service":                    #ServiceTransformer
		// ... more transformers
	}

	// Provider-specific render implementation
	render: {
		module: myApp

		// Process each component and generate resources
		resources: [
			for _, component in module.components {
				let selection = #SelectTransformer & {
					component:             component
					availableTransformers: transformers
				}

				for sel in selection.selectedTransformers {
					let transformer = transformers[sel.transformer]
					transformer & {

						transform: {
							component: component
							context: #ProviderContext & {
								name:       module.#metadata.name
								namespace:  module.#metadata.namespace
								_module:    module
								_component: component
							}
						}
					}.output
				}
			},
		]

		// Kubernetes List format
		output: {
			apiVersion: "v1"
			kind:       "List"
			items:      resources
		}
	}
}
