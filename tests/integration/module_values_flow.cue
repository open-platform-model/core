// Module Values Flow Tests
// Tests value constraint refinement through ModuleDefinition → Module → ModuleRelease
package integration

import (
	opm "github.com/open-platform-model/core"
	core "github.com/open-platform-model/core/elements/core"
)

valuesFlowTests: {
	//////////////////////////////////////////////////////////////////
	// Definition Has Schema Only (No Defaults)
	//////////////////////////////////////////////////////////////////

	"values/definition-schema-only": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "my-app"
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
			// Definition: constraints only, no defaults
			values: {
				image!:   string // Required field
				replicas: uint   // Type constraint
			}
		}

		_module: opm.#Module & {
			moduleDefinition: _definition
			// Platform adds defaults
			values: {
				image:    "nginx:latest" // Provide required field
				replicas: uint | *3      // Add default
			}
		}

		_release: opm.#ModuleRelease & {
			module: _module
			values: {
				image:    "nginx:latest"
				replicas: 5
			}
		}

		// Validate user override applied
		result: _release.values.replicas
		result: 5
	}

	//////////////////////////////////////////////////////////////////
	// Platform Adds Defaults to Definition Constraints
	//////////////////////////////////////////////////////////////////

	"values/platform-adds-defaults": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "my-app"
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
			// Definition: constraints only
			values: {
				replicas: uint
				debug:    bool
			}
		}

		// Platform adds defaults
		_module: opm.#Module & {
			moduleDefinition: _definition
			values: {
				replicas: uint | *3     // Add default
				debug:    bool | *false // Add default
			}
		}

		// User uses defaults or overrides
		_release: opm.#ModuleRelease & {
			module: _module
			values: {
				replicas: 3    // Use default
				debug:    true // Override default
			}
		}

		// Validate platform default used (3)
		result: _release.values.replicas
		result: 3

		// Validate user override applied (true overrides default false)
		result2: _release.values.debug
		result2: true
	}

	//////////////////////////////////////////////////////////////////
	// Platform Refines Constraints (Regex Pattern)
	//////////////////////////////////////////////////////////////////

	"values/platform-refines-constraints": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "my-app"
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
			// Definition: just require string
			values: {
				domain!: string
				port:    >0 & <65536
			}
		}

		// Platform refines constraints
		_module: opm.#Module & {
			moduleDefinition: _definition
			values: {
				domain: string & =~".*\\.myplatform\\.com$" // Refine with regex
				port:   >0 & <65536 | *8080                 // Add default within range
			}
		}

		_release: opm.#ModuleRelease & {
			module: _module
			values: {
				domain: "app.myplatform.com" // Satisfies refined constraint
				port:   8080                 // Use default
			}
		}

		// Validate user value satisfies platform regex constraint
		result: _release.values.domain
		result: "app.myplatform.com"

		// Validate platform default used (8080)
		result2: _release.values.port
		result2: 8080
	}

	//////////////////////////////////////////////////////////////////
	// Platform Adds New Fields for Platform Components
	//////////////////////////////////////////////////////////////////

	"values/platform-adds-fields": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "my-app"
				version: "1.0.0"
			}
			components: {
				web: core.#StatelessWorkload & {
					statelessWorkload: container: {
						name:  "web"
						image: values.image
					}
				}
			}
			values: {
				image: string
			}
		}

		// Platform adds monitoring component and new field
		_module: opm.#Module & {
			moduleDefinition: _definition

			components: {
				monitoring: core.#DaemonWorkload & {
					#metadata: {
						#id:  "monitoring"
						name: "monitoring"
					}
					daemonWorkload: container: {
						name:  "prometheus"
						image: "prometheus:latest"
					}
				}
			}

			values: {
				image:          string | *"nginx:latest"
				enableMetrics!: bool // New required field for platform component
			}
		}

		_release: opm.#ModuleRelease & {
			module: _module
			values: {
				image:         "nginx:latest"
				enableMetrics: true
			}
		}

		// Validate platform-added field for platform component
		result: _release.values.enableMetrics
		result: true
	}

	//////////////////////////////////////////////////////////////////
	// Single-Level Inheritance Verification
	//////////////////////////////////////////////////////////////////

	"values/single-level-inheritance": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "my-app"
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
			// Definition: enum constraint only
			values: {
				tier: "free" | "standard" | "premium"
			}
		}

		// Platform adds default
		_module: opm.#Module & {
			moduleDefinition: _definition
			values: {
				tier: ("free" | "standard" | "premium") | *"standard"
			}
		}

		// User doesn't override - should see "standard" from Module, not see Definition's constraint
		_release: opm.#ModuleRelease & {
			module: _module
			values: {
				tier: "standard" // From Module default
			}
		}

		// Validate single-level inheritance: Release sees Module's default (standard), not Definition's constraint
		result: _release.values.tier
		result: "standard"
	}

	//////////////////////////////////////////////////////////////////
	// Enum with Default
	//////////////////////////////////////////////////////////////////

	"values/enum-with-default": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "my-app"
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
			values: {
				environment: "dev" | "staging" | "prod"
			}
		}

		_module: opm.#Module & {
			moduleDefinition: _definition
			values: {
				environment: ("dev" | "staging" | "prod") | *"dev"
			}
		}

		_release: opm.#ModuleRelease & {
			module: _module
			values: {
				environment: "prod"
			}
		}

		// Validate user override within enum constraint (prod overrides default dev)
		result: _release.values.environment
		result: "prod"
	}
}
