package examples

import (
	opm "github.com/open-platform-model/core"
	elements "github.com/open-platform-model/core/elements/core"
)

//////////////////////////////////////////////////////////////////
//// Example: My Application
//////////////////////////////////////////////////////////////////

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
	// 		connectivity.#NetworkScope

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

//////////////////////////////////////////////////////////////////
//// Example: E-commerce Application
//////////////////////////////////////////////////////////////////

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

			stateless: {
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

			stateful: {
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

			volumes: {
				data: {
					persistentClaim: {
						size: values.database.storageSize
					}
					accessModes: ["ReadWriteOnce"]
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

			task: {
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
			image:    string | *"ecommerce/frontend:2.1.0"
			replicas: int | *3
		}
		database: {
			storageSize: string | *"50Gi"
		}
	}
}

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

			stateless: {
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
			replicas: 5 // Override for production
		}
		database: {
			storageSize: "100Gi" // Larger storage for production
		}
	}
}

//////////////////////////////////////////////////////////////////
//// Example: Monitoring Stack
//////////////////////////////////////////////////////////////////

monitoringStackDefinition: opm.#ModuleDefinition & {
	#metadata: {
		name:             "monitoring-stack"
		defaultNamespace: "monitoring"
		version:          "2.0.0"
		description:      "Observability stack with metrics and log collection"
		labels: {
			"app.kubernetes.io/name":      "monitoring"
			"app.kubernetes.io/component": "observability"
			team:                          "sre"
		}
	}

	components: {
		metricsServer: {
			#metadata: {
				labels: {
					app:       "metrics"
					component: "server"
				}
			}

			// Stateless metrics server
			elements.#StatelessWorkload
			elements.#Replicas
			elements.#Volume

			stateless: {
				container: {
					name:  "prometheus"
					image: values.prometheus.image
					ports: {
						http: {
							targetPort: 9090
							protocol:   "TCP"
						}
					}
					env: {
						STORAGE_RETENTION: {
							name:  "STORAGE_RETENTION"
							value: "15d"
						}
					}
				}
			}

			replicas: {
				count: 2
			}

			volumes: {
				data: {
					persistentClaim: {
						size: values.prometheus.storageSize
					}
					accessModes: ["ReadWriteOnce"]
				}
				config: {
					configMap: {
						name: "prometheus-config"
					}
				}
			}
		}

		logCollector: {
			#metadata: {
				labels: {
					app:       "logs"
					component: "collector"
				}
			}

			// Daemon for log collection on every node
			elements.#DaemonWorkload

			daemon: {
				container: {
					name:  "fluentd"
					image: "fluent/fluentd:v1.16-debian"
					ports: {
						forward: {
							targetPort: 24224
							protocol:   "TCP"
						}
						http: {
							targetPort: 9880
							protocol:   "TCP"
						}
					}
					env: {
						FLUENT_ELASTICSEARCH_HOST: {
							name:  "FLUENT_ELASTICSEARCH_HOST"
							value: "elasticsearch"
						}
						FLUENT_ELASTICSEARCH_PORT: {
							name:  "FLUENT_ELASTICSEARCH_PORT"
							value: "9200"
						}
					}
				}
			}
		}

		alertManager: {
			#metadata: {
				labels: {
					app:       "alerts"
					component: "manager"
				}
			}

			// Stateless alert manager
			elements.#StatelessWorkload
			elements.#Replicas

			stateless: {
				container: {
					name:  "alertmanager"
					image: "prom/alertmanager:v0.26.0"
					ports: {
						http: {
							targetPort: 9093
							protocol:   "TCP"
						}
					}
				}
			}

			replicas: {
				count: 2
			}
		}
	}

	values: {
		prometheus: {
			image:       string | *"prom/prometheus:v2.48.0"
			replicas:    int | *2
			storageSize: string | *"100Gi"
		}
	}
}

monitoringStack: opm.#Module & {
	#metadata: {
		name:    "monitoring-stack-prod"
		version: "2.0.0"
		labels: {
			environment: "production"
			region:      "us-west-2"
		}
	}

	moduleDefinition: monitoringStackDefinition

	values: {
		prometheus: {
			replicas:    3 // High availability
			storageSize: "500Gi"
		}
	}
}
