package examples

import (
	opm "github.com/open-platform-model/core"
	elements "github.com/open-platform-model/core/elements/core"
)

//////////////////////////////////////////////////////////////////
//// Example: Simple Application
//////////////////////////////////////////////////////////////////

// ModuleDefinition - Application template with constraints-only values
myAppDefinition: opm.#ModuleDefinition & {
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
			statelessWorkload: {
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
			volume: {
				data: {
					name: "data"
					persistentClaim: {
						size:       "10Gi"
						accessMode: "ReadWriteOnce"
					}
				}
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

			simpleDatabase: {
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

	values: {
		web: {
			image!: string // Required field (constraint only)
		}
		dbVolume: {
			persistentClaim: {
				size: string // Constraint only
			}
		}
	}
}

// Module - Platform instance with concrete values
myApp: opm.#Module & {
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
			statelessWorkload: {
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
		web: {
			image: "ghcr.io/example/web:2.0.0" // Provide required field
		}
		dbVolume: {
			persistentClaim: {
				size: "10Gi" // Concrete value
			}
		}
		auditLogging: {
			image: "ghcr.io/example/audit-logging:1.0.1"
		}
	}
}
