// Developer Flow Example: Blog Application
// This demonstrates how a developer creates and tests a ModuleDefinition locally
//
// Label & Annotation Hierarchy (all levels merge):
// 1. ModuleDefinition level - Developer defines app-wide metadata (app.name, team, owner)
// 2. Module level - Platform/end-user adds deployment context (environment, deployed.by, git.commit)
// 3. Component level - Component-specific metadata (component, tier, metrics.port, backup.enabled)
package developer

import (
	"list"

	opm "github.com/open-platform-model/core"
	elements "github.com/open-platform-model/core/elements/core"
	common "github.com/open-platform-model/core/examples/common"
)

//////////////////////////////////////////////////////////////////
// Developer creates ModuleDefinition
//////////////////////////////////////////////////////////////////

blogAppDefinition: opm.#ModuleDefinition & {
	#metadata: {
		name:        "blog-app"
		version:     "1.0.0"
		description: "Simple blog application with frontend and database"
		labels: {
			"app.name": "blog-app"
			team:       "content"
		}
		annotations: {
			"owner": "content-team@example.com"
		}
	}

	components: {
		// Frontend component
		frontend: {
			#metadata: {
				name: "frontend"
				labels: {
					component: "frontend"
					tier:      "web"
				}
				annotations: {
					"metrics.port": "9090"
				}
			}

			// Use composite element
			elements.#StatelessWorkload

			statelessWorkload: {
				container: {
					name:  "blog-frontend"
					image: values.frontend.image
					ports: {
						http: {
							name:       "http"
							targetPort: 3000
							protocol:   "TCP"
						}
					}
					env: {
						DATABASE_URL: {
							name:  "DATABASE_URL"
							value: "postgresql://postgres:5432/blog"
						}
						NODE_ENV: {
							name:  "NODE_ENV"
							value: values.environment
						}
					}
				}
			}
		}

		// Database component
		database: {
			#metadata: {
				name: "database"
				labels: {
					component:      "database"
					tier:           "data"
					"storage.type": "postgresql"
				}
				annotations: {
					"backup.enabled": "true"
				}
			}

			// Use composite element for simple database
			elements.#SimpleDatabase

			simpleDatabase: {
				engine:   "postgres"
				version:  "15"
				dbName:   "blog"
				username: "admin"
				password: "changeme" // In production, use secrets
				persistence: {
					enabled: true
					size:    values.database.storageSize
				}
			}
		}
	}

	// Value schema - constraints only, no defaults
	values: {
		frontend: {
			image!: string // Required
		}
		database: {
			storageSize!: string // Required
		}
		environment!: string                    // Required
		test:         string | *"default-value" // Optional with default
	}
}

//////////////////////////////////////////////////////////////////
// Developer tests locally by creating a Module with transformers
//////////////////////////////////////////////////////////////////

// Developer creates test Module instance
blogAppLocal: opm.#Module & {
	#metadata: {
		name:      "blog-app"
		namespace: "development"
		labels: {
			environment: "dev"
		}
		annotations: {
			"deployed.by": "developer@example.com"
			"git.commit":  "abc123"
		}
	}

	// Reference the module definition
	#moduleDefinition: blogAppDefinition

	// Attach transformers with explicit component mapping
	// Developer workflow: Use expressions to map transformers to components
	// Can reference transformer.#metadata.labels to avoid duplication
	#transformersToComponents: {
		"k8s.io/api/apps/v1.Deployment": {
			transformer: common.#DeploymentTransformer
			components: [
				for id, comp in #moduleDefinition.components
				if transformer.#metadata.labels["core.opm.dev/workload-type"] == comp.#metadata.labels["core.opm.dev/workload-type"] &&
					list.Contains(comp.#primitiveElements, "elements.opm.dev/core/v0.Container") {
					id
				},
			]
		}
		"k8s.io/api/apps/v1.StatefulSet": {
			transformer: common.#StatefulSetTransformer
			components: [
				for id, comp in #moduleDefinition.components
				if transformer.#metadata.labels["core.opm.dev/workload-type"] == comp.#metadata.labels["core.opm.dev/workload-type"] &&
					list.Contains(comp.#primitiveElements, "elements.opm.dev/core/v0.Container") {
					id
				},
			]
		}
		"k8s.io/api/core/v1.PersistentVolumeClaim": {
			transformer: common.#PersistentVolumeClaimTransformer
			components: [
				for id, comp in #moduleDefinition.components
				if list.Contains(comp.#primitiveElements, "elements.opm.dev/core/v0.Volume") {
					id
				},
			]
		}
	}

	// Attach renderer (developer testing locally)
	#renderer: opm.#KubernetesListRenderer

	// Provide concrete test values
	values: {
		frontend: {
			image: "blog-frontend:dev"
		}
		database: {
			storageSize: "5Gi"
		}
		environment: "development"
	}
}
