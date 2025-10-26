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
	version:  string
	dbName:   string
	username: string
	password: string
	persistence: {
		enabled:       bool | *true
		size:          string
		storageClass?: string
	}
}

/////////////////////////////////////////////////////////////////
//// Simple Database Element
/////////////////////////////////////////////////////////////////

#SimpleDatabaseElement: opm.#Composite & {
	name:        "SimpleDatabase"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: #SimpleDatabaseSpec
	composes: [
		"elements.opm.dev/core/v0.StatefulWorkload",
		"elements.opm.dev/core/v0.Volume",
	]
	description: "Composite trait to add a simple database to a component"
	labels: {
		"core.opm.dev/category":      "data"
		"core.opm.dev/workload-type": "stateful"
	}
}

#SimpleDatabase: close(opm.#Component & {
	#elements: (#SimpleDatabaseElement.#fullyQualifiedName): #SimpleDatabaseElement

	#StatefulWorkload
	#Volume

	simpleDatabase: #SimpleDatabaseSpec

	statefulWorkload: #StatefulWorkloadSpec & {
		container: #ContainerSpec & {
			if simpleDatabase.engine == "postgres" {
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
						value: simpleDatabase.dbName
					}
					DB_USER: {
						name:  "DB_USER"
						value: simpleDatabase.username
					}
					DB_PASSWORD: {
						name:  "DB_PASSWORD"
						value: simpleDatabase.password
					}
				}
				if simpleDatabase.persistence.enabled {
					volumeMounts: dbData: #VolumeMountSpec & {
						name:      "dbData"
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
	}
	volume: [string]: #VolumeSpec
	if simpleDatabase.persistence.enabled {
		volume: dbData: {
			name: "db-data"
			persistentClaim: {
				accessMode: "ReadWriteOnce"
				size:       simpleDatabase.persistence.size
				if simpleDatabase.persistence.storageClass != _|_ {
					storageClass: simpleDatabase.persistence.storageClass
				}
			}
		}
	}
})
