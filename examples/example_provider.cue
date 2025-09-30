package examples

import (
	"list"

	core "github.com/open-platform-model/core"
	elements "github.com/open-platform-model/core/elements"
)

/////////////////////////////////////////////////////////////////
//// Example Transformer Implementations
/////////////////////////////////////////////////////////////////
// These are examples showing how platform-specific transformers
// could be implemented. Actual implementations would be in
// platform-specific provider packages.

// Example: Kubernetes Provider Implementation
#KubernetesProvider: core.#Provider & {
	#metadata: {
		name:        "kubernetes"
		description: "Kubernetes platform provider"
		version:     "1.0.0"
		minVersion:  "1.27.0"
	}

	#registry: elements.#CoreElementRegistry

	// Register all transformers
	transformers: {
		"k8s.io/api/apps/v1.Deployment": #DeploymentTransformer & {_registry: #registry}
		// "k8s.io/api/apps/v1.StatefulSet":           #StatefulSetTransformer & {_registry: #registry}
		// "k8s.io/api/apps/v1.DaemonSet":             #DaemonSetTransformer & {_registry: #registry}
		// "k8s.io/api/batch/v1.Job":                  #JobTransformer & {_registry: #registry}
		// "k8s.io/api/batch/v1.CronJob":              #CronJobTransformer & {_registry: #registry}
		"k8s.io/api/core/v1.PersistentVolumeClaim": #PersistentVolumeClaimTransformer & {_registry: #registry}
		// "k8s.io/api/core/v1.Service":                    #ServiceTransformer & {_registry: #registry}
		// ... more transformers
	}

	// Provider-specific render implementation
	render: {
		// module: myApp
		module: core.#Module

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
								context: core.#ProviderContext & {
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

// Example: Kubernetes Deployment Transformer
#DeploymentTransformer: core.#Transformer & {
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
		component: core.#Component
		context:   core.#ProviderContext

		// Extract elements with CUE defaults
		let _workload = component.stateless

		let _sidecarContainers = component.sidecarContainers | *[]
		let _initContainers = component.initContainers | *[]
		let _replicas = component.replicas | *defaults.replicas
		let _updateStrategy = component.updateStrategy | *defaults.updateStrategy
		let _healthCheck = component.healthCheck | *defaults.healthCheck

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
#PersistentVolumeClaimTransformer: core.#Transformer & {
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
		component: core.#Component
		context:   core.#ProviderContext

		// Extract elements with CUE defaults
		let _volumes = component.volumes
		// let _backupPolicy = component.backupPolicy | *defaults.backupPolicy
		// let _resourceQuota = component.resourceQuota | *defaults.resourceQuota

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

// Test Module 1: Compatible module
#TestCompatibleModule: core.#Module & {
	#metadata: {
		name:    "web-app"
		version: "1.0.0"
	}

	moduleDefinition: {
		#apiVersion: "core.opm.dev/v1"
		#kind:       "ModuleDefinition"
		#metadata: {
			name:    "web-app"
			version: "1.0.0"
		}
		components: {
			frontend: {
				#metadata: {
					#id:  "frontend"
					name: "frontend"
				}

				// Add traits that are supported by the provider
				elements.#Container
				elements.#Replicas
				elements.#UpdateStrategy
				elements.#Expose

				container: {
					image: "nginx:latest"
					name:  "frontend"
					ports: http: {targetPort: 80}
				}

				replicas: {
					count: 3
				}

				updateStrategy: {
					type: "RollingUpdate"
					rollingUpdate: {
						maxUnavailable: 1
						maxSurge:       1
					}
				}

				expose: {
					ports: http: {
						targetPort: 80
						name:       "http"
					}
					type: "LoadBalancer"
				}
			}
		}
		values: {}
	}

	#context: {}
}

// Test Module 2: Incompatible module (missing element support)
#TestIncompatibleModule: core.#Module & {
	#metadata: {
		name:    "data-pipeline"
		version: "1.0.0"
	}

	moduleDefinition: {
		#apiVersion: "core.opm.dev/v1"
		#kind:       "ModuleDefinition"
		#metadata: {
			name:    "data-pipeline"
			version: "1.0.0"
		}
		components: {
			processor: {
				#metadata: {
					#id:  "processor"
					name: "processor"
				}

				// Use some supported traits
				elements.#Container
				elements.#RestartPolicy

				container: {
					image: "data-processor:latest"
					name:  "processor"
				}

				restartPolicy: {
					policy: "OnFailure"
				}
			}
			db: {
				#metadata: {
					#id:  "db"
					name: "db"
				}

				// Add a custom trait that doesn't exist in the provider
				// Define a custom element inline (simulating org.example.com/v1.SQLDatabase)
				#elements: {
					SQLDatabase: elements.#PrimitiveTrait & {
						name:        "SQLDatabase"
						#apiVersion: "org.example.com/v1"
						target: ["component"]
						workloadType: "stateful"
						schema: {
							engine:  string
							version: string
							size:    string
						}
					}
				}

				// Custom database configuration
				sqlDatabase: {
					engine:  "postgres"
					version: "14"
					size:    "100Gi"
				}
			}
		}
		values: {}
	}

	#context: {}
}

// Test dependency resolution
// #TestResolution1: core.#ModuleDependencyResolver & {
// 	module: #TestCompatibleModule
// 	provider: #KubernetesProvider & {render: module: myApp}
// }

// #TestResolution2: core.#ModuleDependencyResolver & {
// 	module: #TestIncompatibleModule
// 	provider: #KubernetesProvider & {render: module: myApp}
// }

// Expected results:
// TestResolution1: Should be compatible - all required elements are supported
// TestResolution2: Should be incompatible - missing support for:
//   - org.example.com/v1.SQLDatabase (not registered in provider)
