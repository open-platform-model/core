// Composite Field Templating Tests
// Tests for composite element field mapping (critical OPM logic)
package unit

import (
	opm "github.com/open-platform-model/core"
	core "github.com/open-platform-model/core/elements/core"
)

compositeTemplatingTests: {
	//////////////////////////////////////////////////////////////////
	// StatelessWorkload Field Templating
	//////////////////////////////////////////////////////////////////

	// Test: Container field templating
	"stateless/container-templating": core.#StatelessWorkload & {
		statelessWorkload: container: {
			name:  "web"
			image: "nginx:latest"
			ports: http: targetPort: 80
		}

		// Verify templating: statelessWorkload.container → container
		container: {
			name:  "web"
			image: "nginx:latest"
			ports: http: targetPort: 80
		}
	}

	// Test: Replicas field templating
	"stateless/replicas-templating": core.#StatelessWorkload & {
		statelessWorkload: {
			container: {
				name:  "web"
				image: "nginx:latest"
			}
			replicas: count: 5
		}

		// Verify templating: statelessWorkload.replicas → replicas
		replicas: count: 5
	}

	// Test: HealthCheck field templating
	"stateless/healthcheck-templating": core.#StatelessWorkload & {
		statelessWorkload: {
			container: {
				name:  "web"
				image: "nginx:latest"
			}
			healthCheck: liveness: httpGet: {
				path:   "/health"
				port:   80
				scheme: "HTTP"
			}
		}

		// Verify templating: statelessWorkload.healthCheck → healthCheck
		healthCheck: liveness: httpGet: {
			path:   "/health"
			port:   80
			scheme: "HTTP"
		}
	}

	// Test: RestartPolicy field templating
	"stateless/restart-policy-templating": core.#StatelessWorkload & {
		statelessWorkload: {
			container: {
				name:  "web"
				image: "nginx:latest"
			}
			restartPolicy: policy: "Always"
		}

		// Verify templating: statelessWorkload.restartPolicy → restartPolicy
		restartPolicy: policy: "Always"
	}

	// Test: UpdateStrategy field templating
	"stateless/update-strategy-templating": core.#StatelessWorkload & {
		statelessWorkload: {
			container: {
				name:  "web"
				image: "nginx:latest"
			}
			updateStrategy: {
				type: "RollingUpdate"
				rollingUpdate: maxUnavailable: 1
			}
		}

		// Verify templating: statelessWorkload.updateStrategy → updateStrategy
		updateStrategy: {
			type: "RollingUpdate"
			rollingUpdate: maxUnavailable: 1
		}
	}

	// Test: SidecarContainers field templating
	"stateless/sidecar-containers-templating": core.#StatelessWorkload & {
		statelessWorkload: {
			container: {
				name:  "web"
				image: "nginx:latest"
			}
			sidecarContainers: [{
				name:  "logger"
				image: "logger:v1"
			}]
		}

		// Verify templating: statelessWorkload.sidecarContainers → sidecarContainers
		sidecarContainers: [{
			name:  "logger"
			image: "logger:v1"
		}]
	}

	// Test: InitContainers field templating
	"stateless/init-containers-templating": core.#StatelessWorkload & {
		statelessWorkload: {
			container: {
				name:  "web"
				image: "nginx:latest"
			}
			initContainers: [{
				name:  "init"
				image: "init:v1"
			}]
		}

		// Verify templating: statelessWorkload.initContainers → initContainers
		initContainers: [{
			name:  "init"
			image: "init:v1"
		}]
	}

	// Test: All fields templated together
	"stateless/all-fields-templating": core.#StatelessWorkload & {
		statelessWorkload: {
			container: {
				name:  "app"
				image: "app:latest"
			}
			replicas: count:       5
			restartPolicy: policy: "Always"
			updateStrategy: type:  "RollingUpdate"
			healthCheck: liveness: httpGet: {
				path:   "/"
				port:   80
				scheme: "HTTP"
			}
			sidecarContainers: [{name: "sidecar", image: "sidecar:v1"}]
			initContainers: [{name: "init", image: "init:v1"}]
		}

		// Verify all fields templated
		container: {
			name:  "app"
			image: "app:latest"
		}
		replicas: count:       5
		restartPolicy: policy: "Always"
		updateStrategy: type:  "RollingUpdate"
		healthCheck: liveness: httpGet: {
			path:   "/"
			port:   80
			scheme: "HTTP"
		}
		sidecarContainers: [{name: "sidecar", image: "sidecar:v1"}]
		initContainers: [{name: "init", image: "init:v1"}]
	}

	//////////////////////////////////////////////////////////////////
	// StatefulWorkload Field Templating
	//////////////////////////////////////////////////////////////////

	// Test: Stateful container field templating
	"stateful/container-templating": core.#StatefulWorkload & {
		statefulWorkload: container: {
			name:  "db"
			image: "postgres:15"
			ports: db: targetPort: 5432
		}

		// Verify templating: statefulWorkload.container → container
		container: {
			name:  "db"
			image: "postgres:15"
			ports: db: targetPort: 5432
		}
	}

	// Test: Stateful all fields templating
	"stateful/all-fields-templating": core.#StatefulWorkload & {
		statefulWorkload: {
			container: {
				name:  "postgres"
				image: "postgres:15"
			}
			replicas: count:       3
			restartPolicy: policy: "Always"
			updateStrategy: type:  "RollingUpdate"
			healthCheck: liveness: exec: command: ["pg_isready"]
			serviceName: "postgres-service"
		}

		// Verify all fields templated
		container: {
			name:  "postgres"
			image: "postgres:15"
		}
		replicas: count:       3
		restartPolicy: policy: "Always"
		updateStrategy: type:  "RollingUpdate"
		healthCheck: liveness: exec: command: ["pg_isready"]
		statefulWorkload: serviceName: "postgres-service"
	}

	//////////////////////////////////////////////////////////////////
	// SimpleDatabase Field Templating
	//////////////////////////////////////////////////////////////////

	// Test: SimpleDatabase container templating with config
	"simple-database/container-from-config": core.#SimpleDatabase & {
		simpleDatabase: {
			engine:   "postgres"
			version:  "15"
			dbName:   "mydb"
			username: "user"
			password: "pass"
			persistence: {
				enabled: true
				size:    "10Gi"
			}
		}

		// Verify container fields derived from simpleDatabase config
		statefulWorkload: container: {
			image: "postgres:latest"
			env: {
				DB_NAME: value:     "mydb"
				DB_USER: value:     "user"
				DB_PASSWORD: value: "pass"
			}
			ports: db: targetPort: 5432
		}
	}

	// Test: SimpleDatabase volume templating when enabled
	"simple-database/volume-when-enabled": core.#SimpleDatabase & {
		simpleDatabase: {
			engine:   "postgres"
			version:  "15"
			dbName:   "appdb"
			username: "admin"
			password: "secret"
			persistence: {
				enabled:      true
				size:         "20Gi"
				storageClass: "fast-ssd"
			}
		}

		// Verify volume created with correct spec
		volume: dbData: {
			name: "db-data"
			persistentClaim: {
				size:         "20Gi"
				storageClass: "fast-ssd"
				accessMode:   "ReadWriteOnce"
			}
		}
		statefulWorkload: container: volumeMounts: dbData: mountPath: "/var/lib/postgresql/data"
	}

	// Test: SimpleDatabase volume not created when disabled
	"simple-database/no-volume-when-disabled": core.#SimpleDatabase & {
		simpleDatabase: {
			engine:   "postgres"
			version:  "15"
			dbName:   "testdb"
			username: "user"
			password: "pass"
			persistence: {
				enabled: false
				size:    "10Gi"
			}
		}

		// Verify volume doesn't exist
		volume: {}
	}

	// Test: SimpleDatabase default values
	"simple-database/default-values": core.#SimpleDatabase & {
		simpleDatabase: {}

		// Verify default values applied
		simpleDatabase: {
			engine:   "postgres"
			version:  "latest"
			dbName:   "appdb"
			username: "admin"
			password: "password"
			persistence: {
				enabled: true
				size:    "1Gi"
			}
		}
	}

	//////////////////////////////////////////////////////////////////
	// Transformer Compatibility
	//////////////////////////////////////////////////////////////////

	// Test: Flattened structure for transformer access
	"composite/transformer-compatibility": core.#StatelessWorkload & {
		#metadata: {
			#id:  "web"
			name: "web"
		}
		statelessWorkload: {
			container: {
				name:  "web"
				image: "nginx:latest"
				ports: http: targetPort: 80
			}
			replicas: count: 3
		}

		// Verify transformers can access flattened fields directly
		container: {
			name:  "web"
			image: "nginx:latest"
			ports: http: targetPort: 80
		}
		replicas: count: 3
	}

	// Test: Multiple composites in same component
	"composite/multiple-composites": opm.#Component & {
		#metadata: #id: "web"
		core.#StatelessWorkload
		core.#Expose

		statelessWorkload: container: {
			name:  "web"
			image: "nginx:latest"
			ports: http: targetPort: 80
		}

		expose: {
			type: "LoadBalancer"
			ports: http: {
				port:       80
				targetPort: 80
			}
		}

		// Verify both composite fields available
		statelessWorkload: container: {
			name:  "web"
			image: "nginx:latest"
		}
		expose: type: "LoadBalancer"

		// Verify templated fields from StatelessWorkload
		container: {
			name:  "web"
			image: "nginx:latest"
		}
	}

	// Test: Schema injection via Component
	"composite/schema-injection": opm.#Component & {
		#metadata: #id: "web"
		#elements: {
			StatelessWorkload: core.#StatelessWorkloadElement
		}

		// Verify #Component auto-injects statelessWorkload field
		// This validates the (elem.#nameCamel): elem.schema logic
		statelessWorkload: core.#StatelessSpec & {
			container: {
				name:  "web"
				image: "nginx:latest"
			}
		}
	}
}
