package core

// Example test scenarios for compatibility checking

// Example Kubernetes Provider
#TestKubernetesProvider: #Provider & {
	#metadata: {
		name:        "kubernetes"
		description: "Kubernetes platform provider"
		version:     "1.29.0"
		minVersion:  "1.27.0"
	}

	// Native Kubernetes resources mapped to OPM elements they support
	transformers: {
		"k8s.io/api/apps/v1.Deployment": #Transformer & {
			creates: "k8s.io/api/apps/v1.Deployment"
			_registry: #CoreElementRegistry
			required: ["elements.opm.dev/core/v1alpha1.Container"]
			optional: [
				"elements.opm.dev/core/v1alpha1.Replicas",
				"elements.opm.dev/core/v1alpha1.UpdateStrategy",
				"elements.opm.dev/core/v1alpha1.RestartPolicy",
			]
			transform: {...}
		}
		"k8s.io/api/core/v1.Service": #Transformer & {
			creates: "k8s.io/api/core/v1.Service"
			_registry: #CoreElementRegistry
			required: ["elements.opm.dev/core/v1alpha1.Expose"]
			optional: []
			transform: {...}
		}
		// Not registered: org.example.com/v1.SQLDatabase
	}

	render: {
		module: _
		output: {...}
	}
}

// Test Module 1: Compatible module
#TestCompatibleModule: #Module & {
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
					#id:          "frontend"
					name:         "frontend"
					type:         "workload"
					workloadType: "stateless"
				}

				// Add traits that are supported by the provider
				#Container
				#Replicas
				#UpdateStrategy
				#Expose

				container: {
					image: "nginx:latest"
					name:  "frontend"
					ports: http: {containerPort: 80}
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
#TestIncompatibleModule: #Module & {
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
					#id:          "processor"
					name:         "processor"
					type:         "workload"
					workloadType: "task"
				}

				// Use some supported traits
				#Container
				#RestartPolicy

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
					#id:          "db"
					name:         "db"
					type:         "workload"
					workloadType: "stateful"
				}

				// Add a custom trait that doesn't exist in the provider
				// Define a custom element inline (simulating org.example.com/v1.SQLDatabase)
				#elements: {
					SQLDatabase: #PrimitiveTrait & {
						#name:               "SQLDatabase"
						#apiVersion:         "org.example.com/v1"
						#type:               "trait"
						target: ["component"]
						#fullyQualifiedName: "org.example.com/v1.SQLDatabase"
						#schema: {
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
#TestResolution1: #ModuleDependencyResolver & {
	module:   #TestCompatibleModule
	provider: #TestKubernetesProvider
}

#TestResolution2: #ModuleDependencyResolver & {
	module:   #TestIncompatibleModule
	provider: #TestKubernetesProvider
}

// Expected results:
// TestResolution1: Should be compatible - all required elements are supported
// TestResolution2: Should be incompatible - missing support for:
//   - org.example.com/v1.SQLDatabase (not registered in provider)
