package examples

import (
	opm "github.com/open-platform-model/core"
	elements "github.com/open-platform-model/core/elements/core"
)

//////////////////////////////////////////////////////////////////
//// Example: Monitoring Stack
//////////////////////////////////////////////////////////////////

// ModuleDefinition - Observability stack template
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

			statelessWorkload: {
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

			volume: {
				data: {
					name: "data"
					persistentClaim: {
						size:       values.prometheus.storageSize
						accessMode: "ReadWriteOnce"
					}
				}
				config: {
					name: "config"
					configMap: {
						data: {"prometheus.yml": ""}
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

			daemonWorkload: {
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

			statelessWorkload: {
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
			image!:      string // Required field (constraint only)
			storageSize: string // Constraint only
		}
	}
}

// Module - Production instance with high availability
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
			image:       "prom/prometheus:v2.48.0" // Provide required field
			storageSize: "500Gi"                   // Concrete value for production
		}
	}
}
