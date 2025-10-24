// Developer Flow Example: Supabase Application
// This demonstrates a complete Supabase stack based on the official docker-compose.yml
//
// Supabase is an open-source Firebase alternative with:
// - PostgreSQL database
// - Auto-generated REST APIs
// - Realtime subscriptions
// - Authentication
// - Storage
// - Edge Functions
package developer

import (
	"list"

	opm "github.com/open-platform-model/core"
	elements "github.com/open-platform-model/core/elements/core"
	common "github.com/open-platform-model/core/examples/common"
)

//////////////////////////////////////////////////////////////////
// Developer creates Supabase ModuleDefinition
//////////////////////////////////////////////////////////////////

supabaseAppDefinition: opm.#ModuleDefinition & {
	#metadata: {
		name:        "supabase"
		version:     "1.0.0"
		description: "Complete Supabase stack with database, API gateway, auth, storage, and functions"
		labels: {
			"app.name": "supabase"
			team:       "platform"
		}
		annotations: {
			"owner": "platform-team@example.com"
		}
	}

	components: {
		// PostgreSQL Database - Core data layer
		db: {
			#metadata: {
				name: "db"
				labels: {
					component:      "database"
					tier:           "data"
					"storage.type": "postgresql"
				}
				annotations: {
					"backup.enabled": "true"
				}
			}

			elements.#SimpleDatabase

			simpleDatabase: {
				engine:   "postgres"
				version:  "15"
				dbName:   "postgres"
				username: "postgres"
				password: values.database.password
				persistence: {
					enabled: true
					size:    values.database.storageSize
				}
			}
		}

		// Kong API Gateway - Routes all API requests
		kong: {
			#metadata: {
				name: "kong"
				labels: {
					component: "api-gateway"
					tier:      "edge"
				}
				annotations: {
					"metrics.enabled": "true"
				}
			}

			elements.#StatelessWorkload

			statelessWorkload: {
				container: {
					name:  "kong"
					image: "kong:2.8.1"
					ports: {
						http: {
							name:       "http"
							targetPort: 8000
							protocol:   "TCP"
						}
						https: {
							name:       "https"
							targetPort: 8443
							protocol:   "TCP"
						}
					}
					env: {
						KONG_DATABASE: {
							name:  "KONG_DATABASE"
							value: "off"
						}
						KONG_DECLARATIVE_CONFIG: {
							name:  "KONG_DECLARATIVE_CONFIG"
							value: "/var/lib/kong/kong.yml"
						}
						KONG_DNS_ORDER: {
							name:  "KONG_DNS_ORDER"
							value: "LAST,A,CNAME"
						}
						KONG_PLUGINS: {
							name:  "KONG_PLUGINS"
							value: "request-transformer,cors,key-auth,acl,basic-auth"
						}
					}
				}
			}
		}

		// GoTrue Auth Service - Handles authentication
		auth: {
			#metadata: {
				name: "auth"
				labels: {
					component: "auth"
					tier:      "application"
				}
				annotations: {
					"service.type": "authentication"
				}
			}

			elements.#StatelessWorkload

			statelessWorkload: {
				container: {
					name:  "auth"
					image: "supabase/gotrue:latest"
					ports: {
						http: {
							name:       "http"
							targetPort: 9999
							protocol:   "TCP"
						}
					}
					env: {
						GOTRUE_API_HOST: {
							name:  "GOTRUE_API_HOST"
							value: "0.0.0.0"
						}
						GOTRUE_API_PORT: {
							name:  "GOTRUE_API_PORT"
							value: "9999"
						}
						GOTRUE_DB_DRIVER: {
							name:  "GOTRUE_DB_DRIVER"
							value: "postgres"
						}
						GOTRUE_SITE_URL: {
							name:  "GOTRUE_SITE_URL"
							value: values.auth.siteUrl
						}
						GOTRUE_URI_ALLOW_LIST: {
							name:  "GOTRUE_URI_ALLOW_LIST"
							value: values.auth.allowList
						}
						GOTRUE_JWT_SECRET: {
							name:  "GOTRUE_JWT_SECRET"
							value: values.jwt.secret
						}
						GOTRUE_JWT_EXP: {
							name:  "GOTRUE_JWT_EXP"
							value: "3600"
						}
					}
				}
			}
		}

		// PostgREST - Auto-generated REST API
		rest: {
			#metadata: {
				name: "rest"
				labels: {
					component: "rest-api"
					tier:      "application"
				}
			}

			elements.#StatelessWorkload

			statelessWorkload: {
				container: {
					name:  "rest"
					image: "postgrest/postgrest:latest"
					ports: {
						http: {
							name:       "http"
							targetPort: 3000
							protocol:   "TCP"
						}
					}
					env: {
						PGRST_DB_URI: {
							name:  "PGRST_DB_URI"
							value: "postgresql://postgres:\(values.database.password)@db:5432/postgres"
						}
						PGRST_DB_SCHEMAS: {
							name:  "PGRST_DB_SCHEMAS"
							value: "public,storage,graphql_public"
						}
						PGRST_DB_ANON_ROLE: {
							name:  "PGRST_DB_ANON_ROLE"
							value: "anon"
						}
						PGRST_JWT_SECRET: {
							name:  "PGRST_JWT_SECRET"
							value: values.jwt.secret
						}
					}
				}
			}
		}

		// Realtime - WebSocket subscriptions
		realtime: {
			#metadata: {
				name: "realtime"
				labels: {
					component: "realtime"
					tier:      "application"
				}
			}

			elements.#StatelessWorkload

			statelessWorkload: {
				container: {
					name:  "realtime"
					image: "supabase/realtime:latest"
					ports: {
						http: {
							name:       "http"
							targetPort: 4000
							protocol:   "TCP"
						}
					}
					env: {
						PORT: {
							name:  "PORT"
							value: "4000"
						}
						DB_HOST: {
							name:  "DB_HOST"
							value: "db"
						}
						DB_PORT: {
							name:  "DB_PORT"
							value: "5432"
						}
						DB_USER: {
							name:  "DB_USER"
							value: "postgres"
						}
						DB_PASSWORD: {
							name:  "DB_PASSWORD"
							value: values.database.password
						}
						DB_NAME: {
							name:  "DB_NAME"
							value: "postgres"
						}
						DB_SSL: {
							name:  "DB_SSL"
							value: "false"
						}
						JWT_SECRET: {
							name:  "JWT_SECRET"
							value: values.jwt.secret
						}
					}
				}
			}
		}

		// Storage - File storage API
		storage: {
			#metadata: {
				name: "storage"
				labels: {
					component: "storage"
					tier:      "application"
				}
				annotations: {
					"storage.backend": "file"
				}
			}

			elements.#StatelessWorkload

			statelessWorkload: {
				container: {
					name:  "storage"
					image: "supabase/storage-api:latest"
					ports: {
						http: {
							name:       "http"
							targetPort: 5000
							protocol:   "TCP"
						}
					}
					env: {
						ANON_KEY: {
							name:  "ANON_KEY"
							value: values.jwt.anonKey
						}
						SERVICE_KEY: {
							name:  "SERVICE_KEY"
							value: values.jwt.serviceKey
						}
						POSTGREST_URL: {
							name:  "POSTGREST_URL"
							value: "http://rest:3000"
						}
						PGRST_JWT_SECRET: {
							name:  "PGRST_JWT_SECRET"
							value: values.jwt.secret
						}
						DATABASE_URL: {
							name:  "DATABASE_URL"
							value: "postgresql://postgres:\(values.database.password)@db:5432/postgres"
						}
						STORAGE_BACKEND: {
							name:  "STORAGE_BACKEND"
							value: "file"
						}
						FILE_STORAGE_BACKEND_PATH: {
							name:  "FILE_STORAGE_BACKEND_PATH"
							value: "/var/lib/storage"
						}
					}
				}
			}
		}

		// Studio - Web UI dashboard
		studio: {
			#metadata: {
				name: "studio"
				labels: {
					component: "dashboard"
					tier:      "web"
				}
			}

			elements.#StatelessWorkload

			statelessWorkload: {
				container: {
					name:  "studio"
					image: "supabase/studio:latest"
					ports: {
						http: {
							name:       "http"
							targetPort: 3000
							protocol:   "TCP"
						}
					}
					env: {
						SUPABASE_URL: {
							name:  "SUPABASE_URL"
							value: values.studio.publicUrl
						}
						STUDIO_PG_META_URL: {
							name:  "STUDIO_PG_META_URL"
							value: "http://meta:8080"
						}
						SUPABASE_ANON_KEY: {
							name:  "SUPABASE_ANON_KEY"
							value: values.jwt.anonKey
						}
						SUPABASE_SERVICE_KEY: {
							name:  "SUPABASE_SERVICE_KEY"
							value: values.jwt.serviceKey
						}
					}
				}
			}
		}

		// Functions - Edge runtime for serverless functions
		functions: {
			#metadata: {
				name: "functions"
				labels: {
					component: "edge-functions"
					tier:      "application"
				}
			}

			elements.#StatelessWorkload

			statelessWorkload: {
				container: {
					name:  "functions"
					image: "supabase/edge-runtime:latest"
					ports: {
						http: {
							name:       "http"
							targetPort: 9000
							protocol:   "TCP"
						}
					}
					env: {
						JWT_SECRET: {
							name:  "JWT_SECRET"
							value: values.jwt.secret
						}
						SUPABASE_URL: {
							name:  "SUPABASE_URL"
							value: values.studio.publicUrl
						}
						SUPABASE_ANON_KEY: {
							name:  "SUPABASE_ANON_KEY"
							value: values.jwt.anonKey
						}
						SUPABASE_SERVICE_ROLE_KEY: {
							name:  "SUPABASE_SERVICE_ROLE_KEY"
							value: values.jwt.serviceKey
						}
					}
				}
			}
		}
	}

	// Value schema - constraints only, no defaults
	// Developers define what can be configured
	values: {
		database: {
			password!:    string // Required - PostgreSQL password
			storageSize!: string // Required - e.g., "10Gi"
		}
		jwt: {
			secret!:     string // Required - JWT signing secret
			anonKey!:    string // Required - Anonymous key for public access
			serviceKey!: string // Required - Service role key for admin access
		}
		auth: {
			siteUrl!:   string // Required - Main site URL
			allowList!: string // Required - Comma-separated allowed redirect URLs
		}
		studio: {
			publicUrl!: string // Required - Public URL for Supabase API
		}
		environment!: string // Required - Environment name
	}
}

//////////////////////////////////////////////////////////////////
// Developer tests locally by creating a Module with transformers
//////////////////////////////////////////////////////////////////

// Developer creates test Module instance
supabaseLocal: opm.#Module & {
	#metadata: {
		name:      "supabase"
		namespace: "development"
		labels: {
			environment: "dev"
		}
		annotations: {
			"deployed.by": "developer@example.com"
			"git.commit":  "local-dev"
		}
	}

	// Reference the module definition
	#moduleDefinition: supabaseAppDefinition

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
		database: {
			password:    "your-super-secret-and-long-postgres-password"
			storageSize: "10Gi"
		}
		jwt: {
			secret:     "your-super-secret-jwt-token-with-at-least-32-characters-long"
			anonKey:    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
			serviceKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
		}
		auth: {
			siteUrl:   "http://localhost:3000"
			allowList: "http://localhost:3000,http://localhost:8000"
		}
		studio: {
			publicUrl: "http://localhost:8000"
		}
		environment: "development"
	}
}
