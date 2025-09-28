package core

//////////////////////////////////////////////////////////////////
//// Example
//////////////////////////////////////////////////////////////////
#MyApplication: #ModuleDefinition & {
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
				#id:          "web"
				name:         "web"
				type:         "workload"
				workloadType: "stateless"
				labels: {
					app: "web"
				}
			}

			// Add primitive elements
			#Container
			#Volume

			// Define the container and volume details
			container: {
				image: values.web.image
				name:  "web"
				ports: http: {containerPort: 80}
				env: {
					DB_HOST: {name: "DB_HOST", value: "db"}
					DB_PORT: {name: "DB_PORT", value: "5432"}
					DB_NAME: {name: "DB_NAME", value: "my-web-app"}
				}
				volumeMounts: {
					data: volumes.data & {mountPath: "/var/lib/data"}
				}
			}
			volumes: {
				data: {persistentClaim: {size: "10Gi"}}
			}
		}
		db: {
			#metadata: {
				type: "resource"
				labels: {
					app:             "database"
					"database-type": "postgres"
				}
			}

			// Add primitive elements
			#Volume

			// Define volume details
			volumes: {
				data: {persistentClaim: {size: "20Gi"}}
			}
		}
	}

	scopes: {
		network: {
			#NetworkScope

			appliesTo: [components.web, components.db]
			policy: {
				allowInternal: true
				allowExternal: false
			}
		}
	}

	values: {
		web: {
			// Example of overriding default image tag
			image: _ | *"ghcr.io/example/web:2.0.0"
		}
		dbVolume: #VolumeSpec & {
			persistentClaim: _ | *{size: "50Gi"}
		}
	}
}

myApp: #Module & {
	#metadata: {
		#id:     "my-app-instance"
		name:    "my-app-instance"
		version: "0.1.0"
		labels: {
			environment: "production"
			team:        "frontend"
		}
	}

	moduleDefinition: #MyApplication

	components: {
		auditLogging: {
			#metadata: {
				type:         "workload"
				workloadType: "stateless"
				labels: {
					app: "audit-logging"
				}
			}

			// Add primitive elements
			#Container

			// Define the container details
			container: {
				image: string | *"ghcr.io/example/audit-logging:1.0.0"
				name:  "audit-logging"
				ports: http: {containerPort: 8080}
				env: {
					LOG_LEVEL: {name: "LOG_LEVEL", value: "info"}
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
