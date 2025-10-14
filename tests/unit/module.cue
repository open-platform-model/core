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

		// Platform adds monitoring component
		components: {
			monitoring: core.#DaemonWorkload & {
				daemonWorkload: container: {
					name:  "monitoring"
					image: "prometheus:latest"
				}
			}
		}

		// Validate #allComponents includes both
		#allComponents: {
			web:        _
			monitoring: _
		}

		// Validate status
		#status: {
			totalComponentCount:    2
			platformComponentCount: 1
		}
	}

	//////////////////////////////////////////////////////////////////
	// Module Scope Merging
	//////////////////////////////////////////////////////////////////

	// Test: Module scope merging (definition + platform)
	"module/scope-merging": opm.#Module & {
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

		// Platform adds security scope
		scopes: {
			security: opm.#Scope & {
				#metadata: {
					#id:       "security"
					immutable: true
				}
				#elements: {
					NetworkScope: core.#NetworkScopeElement
				}
				networkScope: networkPolicy: externalCommunication: false
				appliesTo: "*"
			}
		}

		// Validate platform scope count
		#status: platformScopeCount: 1
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
			moduleDefinition: _definition
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

	//////////////////////////////////////////////////////////////////
	// ModuleRelease Tests
	//////////////////////////////////////////////////////////////////

	// Test: ModuleRelease values resolution
	"module-release/values-resolution": {
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
			moduleDefinition: _definition
			values: {
				image:    "nginx:1.25"
				replicas: 5
			}
		}

		_release: opm.#ModuleRelease & {
			module: _module
			provider: opm.#Provider & {
				#metadata: {
					name:        "kubernetes"
					description: "Test provider"
					version:     "1.0.0"
					minVersion:  "1.0.0"
				}
				transformers: {}
			}
		}

		// Validate values merged: definition defaults + module overrides
		_release: values: {
			image:    "nginx:1.25"
			replicas: 5
		}
	}

	// Test: ModuleRelease with fixture
	"module-release/using-fixture": {
		_module: opm.#Module & {
			moduleDefinition: fixtures.#SampleThreeTier
			values: {
				webImage:    "nginx:1.25"
				webReplicas: 10
			}
		}

		_release: opm.#ModuleRelease & {
			module: _module
			provider: opm.#Provider & {
				#metadata: {
					name:        "kubernetes"
					description: "Test provider"
					version:     "1.0.0"
					minVersion:  "1.0.0"
				}
				transformers: {}
			}
		}

		// Validate fixture works and values resolve
		_release: values: {
			webImage:    "nginx:1.25"
			webReplicas: 10
		}
		_release: module: #allComponents: {
			web: _
			api: _
			db:  _
		}
	}
}
