package examples

import (
	opm "github.com/open-platform-model/core"
	elements "github.com/open-platform-model/core/elements/core"
)

//////////////////////////////////////////////////////////////////
//// Validation Scenario 1: Compatible Module
//////////////////////////////////////////////////////////////////
// This module uses only elements supported by the Kubernetes provider

compatibleModule: opm.#Module & {
	#metadata: {
		name:    "compatible-web-app"
		version: "1.0.0"
	}

	moduleDefinition: {
		#apiVersion: "core.opm.dev/v1"
		#kind:       "ModuleDefinition"
		#metadata: {
			name:             "compatible-web-app"
			defaultNamespace: "apps"
			version:          "1.0.0"
			description:      "A simple web application using only supported elements"
		}

		components: {
			web: {
				#metadata: {
					labels: {
						app: "web"
					}
				}

				// Use supported composite element
				elements.#StatelessWorkload
				elements.#Replicas
				elements.#HealthCheck

				stateless: {
					container: {
						name:  "nginx"
						image: "nginx:alpine"
						ports: {
							http: {
								targetPort: 80
								protocol:   "TCP"
							}
						}
					}
				}

				replicas: {
					count: 3
				}

				healthCheck: {
					liveness: {
						httpGet: {
							path:   "/health"
							port:   80
							scheme: "HTTP"
						}
					}
				}
			}
		}

		values: {}
	}

	#context: {}
}

//////////////////////////////////////////////////////////////////
//// Validation Scenario 2: Incompatible Module - Custom Element
//////////////////////////////////////////////////////////////////
// This module uses a custom element not in the catalog

incompatibleModuleCustomElement: opm.#Module & {
	#metadata: {
		name:    "custom-database-app"
		version: "1.0.0"
	}

	moduleDefinition: {
		#apiVersion: "core.opm.dev/v1"
		#kind:       "ModuleDefinition"
		#metadata: {
			name:             "custom-database-app"
			defaultNamespace: "apps"
			version:          "1.0.0"
			description:      "Application with custom database element not in catalog"
		}

		components: {
			db: {
				#metadata: {
					labels: {
						app: "database"
					}
				}

				// Define a custom element inline that doesn't exist in catalog
				#elements: {
					CustomMongoDB: opm.#Primitive & {
						name:        "CustomMongoDB"
						#apiVersion: "custom.example.com/v1"
						kind:        "primitive"
						target: ["component"]
						workloadType: "stateful"
						schema: {
							version:     string
							replicaSet:  string
							storageSize: string
						}
					}
				}

				customMongoDB: {
					version:     "6.0"
					replicaSet:  "rs0"
					storageSize: "100Gi"
				}
			}
		}

		values: {}
	}

	#context: {}
}

//////////////////////////////////////////////////////////////////
//// Validation Scenario 3: Incompatible Module - Unsupported Workload
//////////////////////////////////////////////////////////////////
// This module uses a workload type without transformer support

incompatibleModuleUnsupportedWorkload: opm.#Module & {
	#metadata: {
		name:    "scheduled-job-app"
		version: "1.0.0"
	}

	moduleDefinition: {
		#apiVersion: "core.opm.dev/v1"
		#kind:       "ModuleDefinition"
		#metadata: {
			name:             "scheduled-job-app"
			defaultNamespace: "jobs"
			version:          "1.0.0"
			description:      "Application with scheduled task (CronJob) - no transformer"
		}

		components: {
			backup: {
				#metadata: {
					labels: {
						app: "backup"
					}
				}

				// Use ScheduledTaskWorkload - provider may not support it
				elements.#ScheduledTaskWorkload

				scheduledTask: {
					container: {
						name:  "backup"
						image: "backup-tool:1.0"
					}
					schedule: "0 2 * * *"
				}
			}
		}

		values: {}
	}

	#context: {}
}

//////////////////////////////////////////////////////////////////
//// Validation Scenario 4: Mixed Compatibility
//////////////////////////////////////////////////////////////////
// This module has both supported and unsupported elements

mixedCompatibilityModule: opm.#Module & {
	#metadata: {
		name:    "mixed-app"
		version: "1.0.0"
	}

	moduleDefinition: {
		#apiVersion: "core.opm.dev/v1"
		#kind:       "ModuleDefinition"
		#metadata: {
			name:             "mixed-app"
			defaultNamespace: "apps"
			version:          "1.0.0"
			description:      "Application with mix of supported and unsupported elements"
		}

		components: {
			// This component is supported
			frontend: {
				#metadata: {
					labels: {
						app: "frontend"
					}
				}

				elements.#StatelessWorkload

				stateless: {
					container: {
						name:  "web"
						image: "web:1.0"
						ports: {
							http: {
								targetPort: 8080
							}
						}
					}
				}
			}

			// This component uses unsupported element
			cache: {
				#metadata: {
					labels: {
						app: "cache"
					}
				}

				// Custom Redis operator element
				#elements: {
					RedisCluster: opm.#Primitive & {
						name:        "RedisCluster"
						#apiVersion: "redis.example.com/v1"
						kind:        "primitive"
						target: ["component"]
						workloadType: "stateful"
						schema: {
							nodes:          int
							memory:         string
							persistEnabled: bool
						}
					}
				}

				redisCluster: {
					nodes:          3
					memory:         "4Gi"
					persistEnabled: true
				}
			}
		}

		values: {}
	}

	#context: {}
}

//////////////////////////////////////////////////////////////////
//// Validation Test Results
//// These would be computed when catalog is provided
//////////////////////////////////////////////////////////////////

// Example validation result structure:
// validationExample: {
// 	scenario: "Compatible Module"
// 	module: compatibleModule
// 	result: opm.#ValidateModuleAdmission & {
// 		module: compatibleModule
// 		catalog: exampleCatalog  // Defined in example_provider.cue
// 		provider: "kubernetes"
// 	}
// 	expected: {
// 		admitted: true
// 		message: "All elements supported"
// 	}
// }
