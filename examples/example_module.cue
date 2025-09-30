package examples

import (
	core "github.com/open-platform-model/core"
	elements "github.com/open-platform-model/core/elements"
)

//////////////////////////////////////////////////////////////////
//// Example
//////////////////////////////////////////////////////////////////
myAppDefinition: core.#ModuleDefinition & {
	#metadata: {
		#id:     "my-app"
		name:    "my-app"
		version: "0.1.0"
		labels: {
			environment: "production"
			team:        "frontend"
		}
	}

	components: {
		web: {
			#metadata: {
				labels: {
					app: "web"
				}
			}

			// Add primitive elements
			elements.#Volume

			// Add composite elements
			elements.#StatelessWorkload

			// Define the container and volume details
			stateless: {
				container: {
					image: values.web.image
					name:  "web"
					ports: http: {targetPort: 80}
					env: {
						DB_HOST: {name: "DB_HOST", value: "db"}
						DB_PORT: {name: "DB_PORT", value: "5432"}
						DB_NAME: {name: "DB_NAME", value: "my-web-app"}
					}
				}
			}
			volumes: {
				data: {persistentClaim: {size: "10Gi"}}
			}
		}
		db: {
			#metadata: {
				labels: {
					app:             "database"
					"database-type": "postgres"
				}
			}

			// Add composite element
			elements.#SimpleDatabase

			database: {
				engine:   "postgres"
				version:  "13"
				dbName:   "my-web-app"
				username: "admin"
				password: "password"
				persistence: {
					enabled: true
					size:    values.dbVolume.persistentClaim.size
				}
			}
		}
	}

	// scopes: {
	// 	network: {
	// 		elements.#NetworkScope

	// 		appliesTo: [components.web, components.db]
	// 		policy: {
	// 			allowInternal: true
	// 			allowExternal: false
	// 		}
	// 	}
	// }

	values: {
		web: {
			// Example of overriding default image tag
			image: _ | *"ghcr.io/example/web:2.0.0"
		}
		dbVolume: elements.#VolumeSpec & {
			persistentClaim: _ | *{size: "10Gi"}
		}
	}
}

myApp: core.#Module & {
	#metadata: {
		#id:     "my-app-instance"
		name:    "my-app-instance"
		version: "0.1.0"
		labels: {
			environment: "production"
			team:        "frontend"
		}
	}

	moduleDefinition: myAppDefinition

	components: {
		auditLogging: {
			#metadata: {
				labels: {
					app: "audit-logging"
				}
			}

			// Add primitive elements
			elements.#StatelessWorkload

			// Define the container details
			stateless: {
				container: {
					image: string | *"ghcr.io/example/audit-logging:1.0.0"
					name:  "audit-logging"
					ports: http: {targetPort: 8080}
					env: {
						LOG_LEVEL: {name: "LOG_LEVEL", value: "info"}
					}
				}
			}
		}
	}

	values: {
		// Add custom values if needed
		// For example, override image tags or repository
		// web: {image: "ghcr.io/example/web:2.0.0"}
		auditLogging: {
			image: "ghcr.io/example/audit-logging:1.0.1"
		}
	}
}
