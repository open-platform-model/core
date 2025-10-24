// Application Scenario Tests
// Tests complete real-world application examples
package integration

import (
	opm "github.com/open-platform-model/core"
	core "github.com/open-platform-model/core/elements/core"
	fixtures "github.com/open-platform-model/core/tests/fixtures"
)

scenarioTests: {
	//////////////////////////////////////////////////////////////////
	// Complete Three-Tier Application
	//////////////////////////////////////////////////////////////////

	"scenario/three-tier-app": {
		// Use fixture three-tier definition
		_definition: fixtures.#SampleThreeTier

		// Platform wraps in Module with defaults
		_module: opm.#Module & {
			moduleDefinition: _definition
			values: {
				webImage:    string | *"nginx:1.25"
				webReplicas: int | *10
			}

			// Platform adds monitoring
			components: {
				monitoring: core.#DaemonWorkload & {
					#metadata: {
						#id:  "monitoring"
						name: "monitoring"
					}
					daemonWorkload: container: {
						name:  "prometheus"
						image: "prometheus:latest"
					}
				}
			}

			// Platform adds security scope
			scopes: {
				security: opm.#Scope & {
					#metadata: {
						#id:       "security"
						immutable: true
					}
					#elements: {
						NetworkScope: core.#NetworkScopeElement
					}
					networkScope: networkPolicy: externalCommunication: false
					appliesTo: "*"
				}
			}
		}

		// User creates release for production
		_release: opm.#ModuleRelease & {
			#metadata: {
				name:        "three-tier-prod"
				namespace:   "production"
				environment: "prod"
			}
			module: _module
			provider: opm.#Provider & {
				#metadata: {
					name:        "kubernetes"
					description: "Kubernetes provider"
					version:     "1.0.0"
					minVersion:  "1.0.0"
				}
				transformers: {}
			}
		}

		// Validate platform default applied to web component
		result: _release.module.components.web.container.image
		result: "nginx:1.25"

		// Validate platform default for replicas
		result2: _release.module.components.web.replicas.count
		result2: 10

		// Validate original definition component preserved
		result3: _release.module.components.api.container.image
		result3: "api:v1"

		// Validate original definition component preserved
		result4: _release.module.components.db.container.image
		result4: "postgres:15"

		// Validate platform-added monitoring component
		result5: _release.module.components.monitoring.container.image
		result5: "prometheus:latest"

		// Validate total includes both definition (3) and platform (1) components
		result6: _release.module.#status.totalComponentCount
		result6: 4

		// Validate platform added exactly 1 component
		result7: _release.module.#status.platformComponentCount
		result7: 1

		// Validate platform added exactly 1 immutable scope
		result8: _release.module.#status.platformScopeCount
		result8: 1
	}

	//////////////////////////////////////////////////////////////////
	// Database Application with Persistence
	//////////////////////////////////////////////////////////////////

	"scenario/database-with-persistence": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "database-app"
				version: "1.0.0"
			}
			components: {
				db: core.#SimpleDatabase & {
					#metadata: {
						#id:  "db"
						name: "postgres"
					}
					simpleDatabase: {
						engine:   values.dbEngine
						dbName:   values.dbName
						username: values.dbUser
						password: values.dbPassword
						persistence: {
							enabled:      true
							size:         values.volumeSize
							storageClass: values.storageClass
						}
					}
				}
			}
			values: {
				dbEngine:     string | *"postgres"
				dbName:       string | *"appdb"
				dbUser:       string | *"admin"
				dbPassword:   string | *"password"
				volumeSize:   string | *"10Gi"
				storageClass: string | *"standard"
			}
		}

		_module: opm.#Module & {
			moduleDefinition: _definition
		}

		_release: opm.#ModuleRelease & {
			module: _module
			values: {
				dbEngine:     "postgres"
				dbName:       "production-db"
				dbUser:       "produser"
				dbPassword:   "secure-password"
				volumeSize:   "100Gi"
				storageClass: "fast-ssd"
			}
		}

		// Validate user value override for database name
		result: _release.module.components.db.statefulWorkload.container.env.DB_NAME.value
		result: "production-db"

		// Validate user value override for database user
		result2: _release.module.components.db.statefulWorkload.container.env.DB_USER.value
		result2: "produser"

		// Validate user override for volume size (100Gi instead of default 10Gi)
		result3: _release.module.components.db.volume.dbData.persistentClaim.size
		result3: "100Gi"

		// Validate user override for storage class (fast-ssd instead of default standard)
		result4: _release.module.components.db.volume.dbData.persistentClaim.storageClass
		result4: "fast-ssd"
	}

	//////////////////////////////////////////////////////////////////
	// Web Application with Expose
	//////////////////////////////////////////////////////////////////

	"scenario/web-app-with-expose": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "web-app"
				version: "1.0.0"
			}
			components: {
				frontend: opm.#Component & {
					#metadata: {
						#id:  "frontend"
						name: "frontend"
					}
					core.#StatelessWorkload
					core.#Expose

					statelessWorkload: {
						container: {
							name:  "nginx"
							image: values.image
							ports: http: {
								name:       "http"
								targetPort: 80
							}
						}
						replicas: count: values.replicas
						healthCheck: liveness: httpGet: {
							path:   "/"
							port:   80
							scheme: "HTTP"
						}
					}

					expose: {
						type: values.exposeType
						ports: http: {
							port:       80
							targetPort: 80
						}
					}
				}
			}
			values: {
				image:      string
				replicas:   int
				exposeType: "ClusterIP" | "NodePort" | "LoadBalancer"
			}
		}

		_module: opm.#Module & {
			moduleDefinition: _definition
			values: {
				image:      string | *"nginx:1.25"
				replicas:   int | *5
				exposeType: ("ClusterIP" | "NodePort" | "LoadBalancer") | *"LoadBalancer"
			}
		}

		_release: opm.#ModuleRelease & {
			#metadata: {
				name:      "web-app-prod"
				namespace: "production"
			}
			module: _module
			provider: opm.#Provider & {
				#metadata: {
					name:        "kubernetes"
					description: "Kubernetes provider"
					version:     "1.0.0"
					minVersion:  "1.0.0"
				}
				transformers: {}
			}
		}

		// Validate platform default for image applied
		result: _release.module.components.frontend.container.image
		result: "nginx:1.25"

		// Validate platform default for replicas applied (overrides element default of 1)
		result2: _release.module.components.frontend.replicas.count
		result2: 5

		// Validate platform default for expose type applied (LoadBalancer overrides element default ClusterIP)
		result3: _release.module.components.frontend.expose.type
		result3: "LoadBalancer"

		// Validate health check configuration from definition
		result4: _release.module.components.frontend.healthCheck.liveness.httpGet.path
		result4: "/"
	}

	//////////////////////////////////////////////////////////////////
	// Microservices with Network Scope
	//////////////////////////////////////////////////////////////////

	"scenario/microservices-network": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "microservices"
				version: "1.0.0"
			}
			components: {
				api: core.#StatelessWorkload & {
					#metadata: {
						#id:  "api"
						name: "api"
					}
					statelessWorkload: container: {
						name:  "api"
						image: "api:v1"
						ports: api: {
							name:       "api"
							targetPort: 8080
						}
					}
				}
				worker: core.#StatelessWorkload & {
					#metadata: {
						#id:  "worker"
						name: "worker"
					}
					statelessWorkload: container: {
						name:  "worker"
						image: "worker:v1"
					}
				}
			}
			scopes: {
				network: opm.#Scope & {
					#metadata: #id: "network"
					#elements: {
						NetworkScope: core.#NetworkScopeElement
					}
					networkScope: networkPolicy: internalCommunication: true
					appliesTo: "*"
				}
			}
			values: {}
		}

		_module: opm.#Module & {
			moduleDefinition: _definition
		}

		_release: opm.#ModuleRelease & {
			module: _module
			provider: opm.#Provider & {
				#metadata: {
					name:        "kubernetes"
					description: "Kubernetes provider"
					version:     "1.0.0"
					minVersion:  "1.0.0"
				}
				transformers: {}
			}
		}

		// Validate api component configuration preserved
		result: _release.module.components.api.container.image
		result: "api:v1"

		// Validate worker component configuration preserved
		result2: _release.module.components.worker.container.image
		result2: "worker:v1"

		// Validate both components counted
		result3: _release.module.#status.totalComponentCount
		result3: 2

		// Validate network scope applied to all components
		result4: _release.module.#status.scopeCount
		result4: 1
	}
}
