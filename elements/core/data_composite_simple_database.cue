package core

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Simple Database Schema
/////////////////////////////////////////////////////////////////

// Simple database specification
#SimpleDatabaseSpec: {
	engine:   "postgres" | "mysql" | "mongodb" | "redis" | *"postgres"
	version:  string | *"latest"
	dbName:   string | *"appdb"
	username: string | *"admin"
	password: string | *"password"
	persistence: {
		enabled: bool | *true
		size:    string | *"1Gi"
	}
}

/////////////////////////////////////////////////////////////////
//// Simple Database Element
/////////////////////////////////////////////////////////////////

#SimpleDatabaseElement: opm.#Composite & {
	name:        "SimpleDatabase"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #SimpleDatabaseSpec
	composes: [#VolumeElement]
	annotations: {
		"core.opm.dev/workload-type": "stateful"
	}
	description: "Composite trait to add a simple database to a component"
	labels: {"core.opm.dev/category": "data"}
}

#SimpleDatabase: close(opm.#ElementBase & {
	#elements: (#SimpleDatabaseElement.#fullyQualifiedName): #SimpleDatabaseElement

	database: #SimpleDatabaseSpec

	stateful: #StatefulWorkloadSpec & {
		container: #ContainerSpec & {
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
		restartPolicy: #RestartPolicySpec & {
			policy: "Always"
		}
		updateStrategy: #UpdateStrategySpec & {
			type: "RollingUpdate"
		}
		healthCheck: #HealthCheckSpec & {
			liveness: {
				httpGet: {
					path:   "/healthz"
					port:   5432
					scheme: "HTTP"
				}
			}
		}
		volume: #VolumeSpec
	}
})
