package examples

import (
	opm "github.com/open-platform-model/core"
	elements "github.com/open-platform-model/core/elements/core"
)

//////////////////////////////////////////////////////////////////
//// Example: E-commerce Application
//////////////////////////////////////////////////////////////////

// ModuleDefinition - E-commerce template with multiple tiers
ecommerceAppDefinition: opm.#ModuleDefinition & {
	#metadata: {
		name:             "ecommerce-app"
		defaultNamespace: "ecommerce"
		version:          "1.0.0"
		description:      "Complete e-commerce application with frontend, database, and order processing"
		labels: {
			"app.kubernetes.io/name":      "ecommerce"
			"app.kubernetes.io/component": "application"
			environment:                   "production"
			team:                          "platform"
		}
	}

	components: {
		frontend: {
			#metadata: {
				labels: {
					app:  "frontend"
					tier: "web"
				}
			}

			// Stateless web application
			elements.#StatelessWorkload
			elements.#Replicas
			elements.#HealthCheck

			statelessWorkload: {
				container: {
					name:  "frontend"
					image: values.frontend.image
					ports: {
						http: {
							name:       "http"
							targetPort: 8080
							protocol:   "TCP"
						}
					}
					env: {
						API_URL: {
							name:  "API_URL"
							value: "http://api:3000"
						}
						DB_HOST: {
							name:  "DB_HOST"
							value: "postgres"
						}
					}
				}
			}

			replicas: {
				count: values.frontend.replicas
			}

			healthCheck: {
				liveness: {
					httpGet: {
						path:   "/health"
						port:   8080
						scheme: "HTTP"
					}
					initialDelaySeconds: 30
					periodSeconds:       10
				}
				readiness: {
					httpGet: {
						path:   "/ready"
						port:   8080
						scheme: "HTTP"
					}
					initialDelaySeconds: 5
					periodSeconds:       5
				}
			}
		}

		database: {
			#metadata: {
				labels: {
					app:  "database"
					tier: "data"
					type: "postgres"
				}
			}

			// Stateful database
			elements.#StatefulWorkload
			elements.#Volume

			statefulWorkload: {
				container: {
					name:  "postgres"
					image: "postgres:15-alpine"
					ports: {
						postgres: {
							name:       "postgres"
							targetPort: 5432
							protocol:   "TCP"
						}
					}
					env: {
						POSTGRES_DB: {
							name:  "POSTGRES_DB"
							value: "ecommerce"
						}
						POSTGRES_USER: {
							name:  "POSTGRES_USER"
							value: "admin"
						}
						POSTGRES_PASSWORD: {
							name:  "POSTGRES_PASSWORD"
							value: "changeme"
						}
					}
				}
				serviceName: "postgres"
			}

			volume: {
				data: {
					name: "data"
					persistentClaim: {
						size:       values.database.storageSize
						accessMode: "ReadWriteOnce"
					}
				}
			}
		}

		orderProcessor: {
			#metadata: {
				labels: {
					app:  "order-processor"
					tier: "background"
				}
			}

			// Task-based batch processing
			elements.#TaskWorkload
			elements.#RestartPolicy

			taskWorkload: {
				container: {
					name:  "processor"
					image: "ecommerce/order-processor:1.0.0"
					env: {
						DB_HOST: {
							name:  "DB_HOST"
							value: "postgres"
						}
						BATCH_SIZE: {
							name:  "BATCH_SIZE"
							value: "100"
						}
					}
				}
			}

			restartPolicy: {
				policy: "OnFailure"
			}
		}
	}

	values: {
		frontend: {
			image!:   string // Required in Definition (constraint only)
			replicas: int    // Constraint only, no default
		}
		database: {
			storageSize: string // Constraint only
		}
	}
}

// Module - Production instance with monitoring
ecommerceApp: opm.#Module & {
	#metadata: {
		name:    "ecommerce-app-prod"
		version: "1.0.0"
		labels: {
			environment: "production"
			region:      "us-east-1"
		}
	}

	moduleDefinition: ecommerceAppDefinition

	// Platform adds monitoring sidecar
	components: {
		monitoring: {
			#metadata: {
				labels: {
					app:  "monitoring"
					tier: "observability"
				}
			}

			elements.#StatelessWorkload
			elements.#SidecarContainers

			statelessWorkload: {
				container: {
					name:  "metrics-exporter"
					image: "prometheus/node-exporter:latest"
					ports: {
						metrics: {
							targetPort: 9100
							protocol:   "TCP"
						}
					}
				}
			}

			sidecarContainers: [{
				name:  "log-shipper"
				image: "fluent/fluent-bit:2.0"
				ports: {
					http: {
						targetPort: 2020
						protocol:   "TCP"
					}
				}
			}]
		}
	}

	values: {
		frontend: {
			image:    "ecommerce/frontend:2.1.0" // Provide required field
			replicas: 5                          // Concrete value for production
		}
		database: {
			storageSize: "100Gi" // Concrete value for production
		}
	}
}
