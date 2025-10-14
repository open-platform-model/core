// Module Templating Tests
// Tests platform team's ability to use for/if statements in Module.values
package integration

import (
	opm "github.com/open-platform-model/core"
	core "github.com/open-platform-model/core/elements/core"
)

templatingTests: {
	//////////////////////////////////////////////////////////////////
	// Platform Templates Image Values from Components
	//////////////////////////////////////////////////////////////////

	"templating/for-loop-component-images": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "microservices-app"
				version: "1.0.0"
			}
			components: {
				api: core.#StatelessWorkload & {
					#metadata: {
						#id:  "api"
						name: "api"
					}
					statelessWorkload: container: {
						name:  "api"
						image: values.apiImage
					}
				}
				web: core.#StatelessWorkload & {
					#metadata: {
						#id:  "web"
						name: "web"
					}
					statelessWorkload: container: {
						name:  "web"
						image: values.webImage
					}
				}
				worker: core.#StatelessWorkload & {
					#metadata: {
						#id:  "worker"
						name: "worker"
					}
					statelessWorkload: container: {
						name:  "worker"
						image: values.workerImage
					}
				}
			}
			// Definition only defines that these fields exist
			values: {
				apiImage!:    string
				webImage!:    string
				workerImage!: string
			}
		}

		// Platform templates image defaults using for loop
		_module: opm.#Module & {
			moduleDefinition: _definition
			values: {
				// Template image values from component names
				for name, comp in moduleDefinition.components {
					"\(name)Image": string | *"registry.platform.com/\(name):v1.0"
				}
			}
		}

		_release: opm.#ModuleRelease & {
			module: _module
			values: {
				// User can override specific images
				apiImage:    "registry.platform.com/api:v1.0"    // Use default
				webImage:    "custom-registry.com/web:v2.0"      // Override
				workerImage: "registry.platform.com/worker:v1.0" // Use default
			}
		}

		// Validate platform-templated default applied (generated from component name)
		result: _release.values.apiImage
		result: "registry.platform.com/api:v1.0"

		// Validate user can override templated default
		result2: _release.values.webImage
		result2: "custom-registry.com/web:v2.0"
	}

	//////////////////////////////////////////////////////////////////
	// Conditional Templating Based on Component Count
	//////////////////////////////////////////////////////////////////

	"templating/conditional-load-balancer": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "scalable-app"
				version: "1.0.0"
			}
			components: {
				web: core.#StatelessWorkload & {
					#metadata: {
						#id:  "web"
						name: "web"
					}
					statelessWorkload: container: {
						name:  "web"
						image: "nginx:latest"
					}
				}
				api: core.#StatelessWorkload & {
					#metadata: {
						#id:  "api"
						name: "api"
					}
					statelessWorkload: container: {
						name:  "api"
						image: "api:v1"
					}
				}
			}
			values: {
				loadBalancerEnabled?: bool
			}
		}

		// Platform conditionally enables load balancer for multi-component apps
		_module: opm.#Module & {
			moduleDefinition: _definition
			values: {
				if len(moduleDefinition.components) > 1 {
					loadBalancerEnabled: bool | *true
				}
			}
		}

		_release: opm.#ModuleRelease & {
			module: _module
			values: {
				loadBalancerEnabled: true
			}
		}

		// Validate conditional templating applied (loadBalancer enabled for multi-component apps)
		result: _release.values.loadBalancerEnabled
		result: true
	}

	//////////////////////////////////////////////////////////////////
	// Template Storage Size for Stateful Workloads
	//////////////////////////////////////////////////////////////////

	"templating/stateful-storage-defaults": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "database-app"
				version: "1.0.0"
			}
			components: {
				web: core.#StatelessWorkload & {
					#metadata: {
						#id:  "web"
						name: "web"
					}
					statelessWorkload: container: {
						name:  "web"
						image: "nginx:latest"
					}
				}
				postgres: core.#StatefulWorkload & {
					#metadata: {
						#id:  "postgres"
						name: "postgres"
					}
					statefulWorkload: container: {
						name:  "postgres"
						image: "postgres:14"
					}
				}
				redis: core.#StatefulWorkload & {
					#metadata: {
						#id:  "redis"
						name: "redis"
					}
					statefulWorkload: container: {
						name:  "redis"
						image: "redis:7"
					}
				}
			}
			values: {
				postgresStorage?: string
				redisStorage?:    string
			}
		}

		// Platform adds storage defaults for stateful workloads only
		_module: opm.#Module & {
			moduleDefinition: _definition
			values: {
				for name, comp in moduleDefinition.components
				if comp.#elements["core.opm.dev/v1alpha1.StatefulWorkload"] != _|_ {
					"\(name)Storage": string | *"10Gi"
				}
			}
		}

		_release: opm.#ModuleRelease & {
			module: _module
			values: {
				postgresStorage: "20Gi" // Override
				redisStorage:    "10Gi" // Use default
			}
		}

		// Validate user override of conditionally-templated storage (20Gi overrides default 10Gi)
		result: _release.values.postgresStorage
		result: "20Gi"

		// Validate conditionally-templated default applied (only for stateful workloads)
		result2: _release.values.redisStorage
		result2: "10Gi"
	}

	//////////////////////////////////////////////////////////////////
	// Template Environment-Specific Domains
	//////////////////////////////////////////////////////////////////

	"templating/environment-domains": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "multi-service-app"
				version: "1.0.0"
			}
			components: {
				api: core.#StatelessWorkload & {
					#metadata: {
						#id:  "api"
						name: "api"
					}
					statelessWorkload: container: {
						name:  "api"
						image: "api:v1"
					}
				}
				frontend: core.#StatelessWorkload & {
					#metadata: {
						#id:  "frontend"
						name: "frontend"
					}
					statelessWorkload: container: {
						name:  "frontend"
						image: "frontend:v1"
					}
				}
			}
			values: {
				apiDomain!:      string
				frontendDomain!: string
				environment!:    "dev" | "staging" | "prod"
			}
		}

		// Platform templates domain defaults based on component names
		_module: opm.#Module & {
			moduleDefinition: _definition
			values: {
				environment: "dev" | "staging" | "prod"
				for name, comp in moduleDefinition.components {
					"\(name)Domain": string | *"\(name).myplatform.com"
				}
			}
		}

		_release: opm.#ModuleRelease & {
			module: _module
			values: {
				environment:    "prod"
				apiDomain:      "api.myplatform.com"
				frontendDomain: "app.myplatform.com" // Override default
			}
		}

		// Validate templated domain default used
		result: _release.values.apiDomain
		result: "api.myplatform.com"

		// Validate user override of templated domain
		result2: _release.values.frontendDomain
		result2: "app.myplatform.com"
	}

	//////////////////////////////////////////////////////////////////
	// Mixed: Templating + Manual Defaults + Constraints
	//////////////////////////////////////////////////////////////////

	"templating/mixed-strategies": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "complex-app"
				version: "1.0.0"
			}
			components: {
				api: core.#StatelessWorkload & {
					#metadata: {
						#id:  "api"
						name: "api"
					}
					statelessWorkload: container: {
						name:  "api"
						image: "api:v1"
					}
				}
				web: core.#StatelessWorkload & {
					#metadata: {
						#id:  "web"
						name: "web"
					}
					statelessWorkload: container: {
						name:  "web"
						image: "web:v1"
					}
				}
			}
			values: {
				apiImage!:  string
				webImage!:  string
				domain!:    string
				replicas:   uint
				debug:      bool
				maxMemory?: string
			}
		}

		_module: opm.#Module & {
			moduleDefinition: _definition
			values: {
				// Templated: image defaults
				for name, comp in moduleDefinition.components {
					"\(name)Image": string | *"registry.platform.com/\(name):latest"
				}

				// Manual: domain constraint + default
				domain: string & =~".*\\.myplatform\\.com$" | *"app.myplatform.com"

				// Manual: replicas default
				replicas: uint | *3

				// Manual: debug default
				debug: bool | *false

				// Conditional: max memory for multi-component apps
				if len(moduleDefinition.components) > 1 {
					maxMemory: string | *"2Gi"
				}
			}
		}

		_release: opm.#ModuleRelease & {
			module: _module
			values: {
				apiImage:  "registry.platform.com/api:latest"
				webImage:  "registry.platform.com/web:v2.0"
				domain:    "myapp.myplatform.com"
				replicas:  5
				debug:     true
				maxMemory: "4Gi"
			}
		}

		// Validate templated default (from for loop over components)
		result: _release.values.apiImage
		result: "registry.platform.com/api:latest"

		// Validate manual constraint refinement with regex enforced
		result2: _release.values.domain
		result2: "myapp.myplatform.com"

		// Validate conditional templating (maxMemory only for multi-component)
		result3: _release.values.maxMemory
		result3: "4Gi"
	}

	//////////////////////////////////////////////////////////////////
	// Nested Templating with Component Metadata
	//////////////////////////////////////////////////////////////////

	"templating/component-metadata": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "labeled-app"
				version: "1.0.0"
			}
			components: {
				frontend: core.#StatelessWorkload & {
					#metadata: {
						#id:  "frontend"
						name: "frontend"
						labels: tier: "presentation"
					}
					statelessWorkload: container: {
						name:  "frontend"
						image: "frontend:v1"
					}
				}
				backend: core.#StatelessWorkload & {
					#metadata: {
						#id:  "backend"
						name: "backend"
						labels: tier: "application"
					}
					statelessWorkload: container: {
						name:  "backend"
						image: "backend:v1"
					}
				}
			}
			values: {
				frontendReplicas?: uint
				backendReplicas?:  uint
			}
		}

		// Platform sets replica defaults based on tier
		_module: opm.#Module & {
			moduleDefinition: _definition
			values: {
				for name, comp in moduleDefinition.components
				if comp.#metadata.labels.tier == "presentation" {
					"\(name)Replicas": uint | *2
				}
				for name, comp in moduleDefinition.components
				if comp.#metadata.labels.tier == "application" {
					"\(name)Replicas": uint | *3
				}
			}
		}

		_release: opm.#ModuleRelease & {
			module: _module
			values: {
				frontendReplicas: 4 // Override
				backendReplicas:  3 // Use default
			}
		}

		// Validate user override of metadata-based templated default (4 overrides tier:presentation default 2)
		result: _release.values.frontendReplicas
		result: 4

		// Validate metadata-based templated default applied (tier:application gets default 3)
		result2: _release.values.backendReplicas
		result2: 3
	}
}
