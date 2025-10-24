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

/////////////////////////////////////////////////////////////////
//// Mock Transformers
/////////////////////////////////////////////////////////////////

// Mock Deployment transformer for testing
#MockDeploymentTransformer: opm.#Transformer & {
	#kind:       "Deployment"
	#apiVersion: "mock.test/v1"
	required: ["elements.opm.dev/core/v0.Container"]
	optional: ["elements.opm.dev/core/v0.Replicas"]

	transform: {
		#component: opm.#Component
		#context:   opm.#TransformerContext

		// Returns a list with a single Deployment
		output: [{
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      #context.componentMetadata.name
				namespace: #context.namespace
			}
			spec: {
				replicas: (#component.replicas | *{count: 1}).count
				template: spec: containers: [#component.container]
			}
		}]
	}
}

// Mock Service transformer for testing
#MockServiceTransformer: opm.#Transformer & {
	#kind:       "Service"
	#apiVersion: "mock.test/v1"
	required: ["elements.opm.dev/core/v0.Container"]
	optional: []

	transform: {
		#component: opm.#Component
		#context:   opm.#TransformerContext

		// Returns a list with a single Service
		output: [{
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      #context.componentMetadata.name
				namespace: #context.namespace
			}
			spec: {
				selector: app: #context.componentMetadata.name
				ports: [{
					port:       80
					targetPort: 8080
				}]
			}
		}]
	}
}

/////////////////////////////////////////////////////////////////
//// Mock Renderers
/////////////////////////////////////////////////////////////////

// Mock List renderer for testing
#MockListRenderer: opm.#Renderer & {
	#metadata: {
		name:        "mock-list"
		description: "Mock list renderer for tests"
		version:     "1.0.0"
	}
	targetPlatform: "mock"

	// New renderer pattern - function-style
	render: {
		resources: [...{...}]
		output: {
			manifest: {
				kind:  "MockList"
				items: resources
			}
			metadata: {
				format: "yaml"
			}
		}
	}
}

// Mock Files renderer for testing
#MockFilesRenderer: opm.#Renderer & {
	#metadata: {
		name:        "mock-files"
		description: "Mock files renderer for tests"
		version:     "1.0.0"
	}
	targetPlatform: "mock"

	// New renderer pattern - function-style
	render: {
		resources: [...{...}]
		output: {
			files: {
				"resources.yaml": resources
			}
			metadata: {
				format:     "yaml"
				entrypoint: "resources.yaml"
			}
		}
	}
}
