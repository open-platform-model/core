package data

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

#SimpleDatabaseElement: core.#Composite & {
	name:        "SimpleDatabase"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: schema.#SimpleDatabaseSpec
	composes: [#VolumeElement]
	workloadType: "stateful"
	description:  "Composite trait to add a simple database to a component"
	labels: {"core.opm.dev/category": "data"}
}

#SimpleDatabase: close(core.#ElementBase & {
	#elements: (#SimpleDatabaseElement.#fullyQualifiedName): #SimpleDatabaseElement

	database: schema.#SimpleDatabaseSpec

	stateful: schema.#StatefulWorkloadSpec & {
		container: schema.#ContainerSpec & {
			if database.engine == "postgres" {
				name:  "database"
				image: "postgres:latest"
				ports: {
					db: {
						targetPort: 5432
					}
				}
				env: {
					DB_NAME: {
						name:  "DB_NAME"
						value: database.dbName
					}
					DB_USER: {
						name:  "DB_USER"
						value: database.username
					}
					DB_PASSWORD: {
						name:  "DB_PASSWORD"
						value: database.password
					}
				}
				volumeMounts: {
					data: {
						name:      "data"
						mountPath: "/var/lib/postgresql/data"
					}
				}
			}
		}
		restartPolicy: schema.#RestartPolicySpec & {
			policy: "Always"
		}
		updateStrategy: schema.#UpdateStrategySpec & {
			type: "RollingUpdate"
		}
		healthCheck: schema.#HealthCheckSpec & {
			liveness: {
				httpGet: {
					path:   "/healthz"
					port:   5432
					scheme: "HTTP"
				}
			}
		}
		volume: schema.#VolumeSpec
	}
})

// Re-export schema types for convenience
#SimpleDatabaseSpec: schema.#SimpleDatabaseSpec
