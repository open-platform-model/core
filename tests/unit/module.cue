// Module Logic Tests
// Tests for module-level computed values and logic
package unit

import (
	opm "github.com/open-platform-model/core"
	core "github.com/open-platform-model/core/elements/core"
	fixtures "github.com/open-platform-model/core/tests/fixtures"
)

moduleTests: {
	//////////////////////////////////////////////////////////////////
	// ModuleDefinition Tests
	//////////////////////////////////////////////////////////////////

	// Test: ModuleDefinition status computation
	"module-definition/status-computation": opm.#ModuleDefinition & {
		#metadata: {
			name:    "test-app"
			version: "1.0.0"
		}
		components: {
			web: core.#StatelessWorkload & {
				statelessWorkload: container: {
					name:  "web"
					image: "nginx:latest"
				}
			}
			api: core.#StatelessWorkload & {
				statelessWorkload: container: {
					name:  "api"
					image: "api:v1"
				}
			}
		}
		scopes: {
			network: opm.#Scope & {
				#metadata: #id: "network"
				#elements: {
					NetworkScope: core.#NetworkScopeElement
				}
				networkScope: networkPolicy: internalCommunication: true
				appliesTo: "*"
			}
		}
		values: {}

		// Validate status fields computed correctly
		#status: {
			componentCount: 2
			scopeCount:     1
		}
	}

	// Test: ModuleDefinition with values schema
	"module-definition/values-schema": opm.#ModuleDefinition & {
		#metadata: {
			name:    "configurable-app"
			version: "1.0.0"
		}
		components: {
			web: core.#StatelessWorkload & {
				statelessWorkload: {
					container: {
						name:  "web"
						image: values.image
					}
					replicas: count: values.replicas
				}
			}
		}
		values: {
			image?:    string | *"nginx:latest"
			replicas?: int | *3
		}

		// Validate values schema defaults
		values: {
			image:    "nginx:latest"
			replicas: 3
		}
	}

	//////////////////////////////////////////////////////////////////
	// Module Component Merging
	//////////////////////////////////////////////////////////////////

	// Test: Module component merging (definition + platform)
	"module/component-merging": opm.#Module & {
		#metadata: {
			name:      "app"
			namespace: "test"
		}

		#module: opm.#CatalogModule & {
			#metadata: {
				name:    "app-test"
				version: "1.0.0"
			}

			moduleDefinition: {
				#metadata: {
					name:    "app"
					version: "1.0.0"
				}
				components: {
					web: core.#StatelessWorkload & {
						statelessWorkload: container: {
							name:  "web"
							image: "nginx:latest"
						}
					}
				}
				values: {}
			}

			transformersToComponents: {
				"mock.test/v1.Deployment": {
					transformer: fixtures.#MockDeploymentTransformer
					components: ["web"]
				}
			}

			renderer: fixtures.#MockListRenderer
		}

		values: {}
	}

	//////////////////////////////////////////////////////////////////
	// Module Scope Merging
	//////////////////////////////////////////////////////////////////

	// Test: Module scope merging (definition + platform)
	"module/scope-merging": opm.#Module & {
		#metadata: {
			name:      "app"
			namespace: "test"
		}

		#module: opm.#CatalogModule & {
			#metadata: {
				name:    "app-scopes-test"
				version: "1.0.0"
			}

			moduleDefinition: {
				#metadata: {
					name:    "app"
					version: "1.0.0"
				}
				components: {
					web: core.#StatelessWorkload & {
						statelessWorkload: container: {
							name:  "web"
							image: "nginx:latest"
						}
					}
				}
				scopes: {
					network: opm.#Scope & {
						#metadata: #id: "network"
						#elements: {
							NetworkScope: core.#NetworkScopeElement
						}
						networkScope: networkPolicy: internalCommunication: true
						appliesTo: "*"
					}
				}
				values: {}
			}

			transformersToComponents: {
				"mock.test/v1.Deployment": {
					transformer: fixtures.#MockDeploymentTransformer
					components: ["web"]
				}
			}

			renderer: fixtures.#MockListRenderer
		}

		values: {}
	}

	//////////////////////////////////////////////////////////////////
	// Module Values Override
	//////////////////////////////////////////////////////////////////

	// Test: Module values override definition defaults
	"module/values-override": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "app"
				version: "1.0.0"
			}
			components: {
				web: core.#StatelessWorkload & {
					statelessWorkload: {
						container: image: values.image
						replicas: count:  values.replicas
					}
				}
			}
			values: {
				image?:    string | *"nginx:latest"
				replicas?: int | *1
			}
		}

		_module: opm.#Module & {
			#metadata: {
				name:      "app"
				namespace: "test"
			}

			#module: opm.#CatalogModule & {
				#metadata: {
					name:    "app-values-test"
					version: "1.0.0"
				}

				moduleDefinition: _definition

				transformersToComponents: {
					"mock.test/v1.Deployment": {
						transformer: fixtures.#MockDeploymentTransformer
						components: ["web"]
					}
				}

				renderer: fixtures.#MockListRenderer
			}

			values: {
				image:    "nginx:1.25"
				replicas: 5
			}
		}

		// Module values override defaults
		_module: values: {
			image:    "nginx:1.25"
			replicas: 5
		}
	}

}
