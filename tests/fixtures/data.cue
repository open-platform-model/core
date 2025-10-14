// Test Fixtures
// Reusable test data for unit and integration tests
package fixtures

import (
	opm "github.com/open-platform-model/core"
	core "github.com/open-platform-model/core/elements/core"
)

/////////////////////////////////////////////////////////////////
//// Sample Components
/////////////////////////////////////////////////////////////////

// Simple stateless component
#SampleStatelessComponent: core.#StatelessWorkload & {
	#metadata: {
		#id:  "web"
		name: "web"
	}
	statelessWorkload: container: {
		name:  "nginx"
		image: "nginx:latest"
		ports: http: {
			name:       "http"
			targetPort: 80
		}
	}
}

// Stateless component with replicas and health check
#SampleStatelessWithModifiers: core.#StatelessWorkload & {
	#metadata: {
		#id:  "api"
		name: "api"
	}
	statelessWorkload: {
		container: {
			name:  "api"
			image: "api:v1"
			ports: api: {
				name:       "api"
				targetPort: 8080
			}
		}
		replicas: count: 3
		healthCheck: liveness: httpGet: {
			path: "/healthz"
			port: 8080
		}
	}
}

// Stateful component
#SampleStatefulComponent: core.#StatefulWorkload & {
	#metadata: {
		#id:  "db"
		name: "postgres"
	}
	statefulWorkload: container: {
		name:  "postgres"
		image: "postgres:15"
		ports: db: {
			name:       "db"
			targetPort: 5432
		}
	}
}

// Simple database component
#SampleDatabaseComponent: core.#SimpleDatabase & {
	#metadata: {
		#id:  "database"
		name: "database"
	}
	simpleDatabase: {
		engine:   "postgres"
		dbName:   "testdb"
		username: "testuser"
		password: "testpass"
		persistence: {
			enabled: true
			size:    "10Gi"
		}
	}
}

/////////////////////////////////////////////////////////////////
//// Sample Module Definitions
/////////////////////////////////////////////////////////////////

// Simple web application
#SampleWebApp: opm.#ModuleDefinition & {
	#metadata: {
		name:    "sample-web"
		version: "1.0.0"
	}
	components: {
		web: core.#StatelessWorkload & {
			statelessWorkload: container: {
				name:  "web"
				image: "nginx:latest"
				ports: http: {
					name:       "http"
					targetPort: 80
				}
			}
		}
	}
	values: {}
}

// Three-tier application
#SampleThreeTier: opm.#ModuleDefinition & {
	#metadata: {
		name:    "three-tier"
		version: "1.0.0"
	}
	components: {
		web: core.#StatelessWorkload & {
			statelessWorkload: {
				container: {
					name:  "web"
					image: values.webImage
					ports: http: targetPort: 80
				}
				replicas: count: values.webReplicas
			}
		}
		api: core.#StatelessWorkload & {
			statelessWorkload: container: {
				name:  "api"
				image: "api:v1"
				ports: api: targetPort: 8080
			}
		}
		db: core.#StatefulWorkload & {
			statefulWorkload: container: {
				name:  "db"
				image: "postgres:15"
				ports: db: targetPort: 5432
			}
		}
	}
	values: {
		webImage:    string
		webReplicas: int
	}
}
