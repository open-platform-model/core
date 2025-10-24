// Module Composition Tests
// Tests platform adding components and scopes to ModuleDefinition
package integration

import (
	opm "github.com/open-platform-model/core"
	core "github.com/open-platform-model/core/elements/core"
)

compositionTests: {
	//////////////////////////////////////////////////////////////////
	// Platform Adds Monitoring Component
	//////////////////////////////////////////////////////////////////

	"composition/platform-adds-component": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "app"
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
			}
			values: {}
		}

		_module: opm.#Module & {
			moduleDefinition: _definition

			// Platform adds monitoring component
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
		}

		// Validate definition component preserved in unified view
		result: _module.components.web.container.image
		result: "nginx:latest"

		// Validate platform-added component in unified view
		result2: _module.components.monitoring.container.image
		result2: "prometheus:latest"

		// Validate total count includes both definition and platform components
		result3: _module.#status.totalComponentCount
		result3: 2

		// Validate platform component count
		result4: _module.#status.platformComponentCount
		result4: 1
	}

	//////////////////////////////////////////////////////////////////
	// Platform Adds Immutable Scope
	//////////////////////////////////////////////////////////////////

	"composition/platform-adds-scope": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "app"
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

		_module: opm.#Module & {
			moduleDefinition: _definition

			// Platform adds immutable security scope
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
		}

		// Validate platform scope marked as immutable (users cannot override)
		result: _module.scopes.security.#metadata.immutable
		result: true

		// Validate platform scope count
		result2: _module.#status.platformScopeCount
		result2: 1
	}

	//////////////////////////////////////////////////////////////////
	// Component Count Validation
	//////////////////////////////////////////////////////////////////

	"composition/component-count-validation": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "app"
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
			values: {}
		}

		_module: opm.#Module & {
			moduleDefinition: _definition

			// Platform adds two components
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
				logging: core.#DaemonWorkload & {
					#metadata: {
						#id:  "logging"
						name: "logging"
					}
					daemonWorkload: container: {
						name:  "fluentd"
						image: "fluentd:latest"
					}
				}
			}
		}

		// Validate total component count (2 definition + 2 platform = 4)
		result: _module.#status.totalComponentCount
		result: 4 // 2 from definition + 2 from platform

		// Validate platform added exactly 2 components
		result2: _module.#status.platformComponentCount
		result2: 2
	}

	//////////////////////////////////////////////////////////////////
	// Scope Merging (Developer + Platform Scopes)
	//////////////////////////////////////////////////////////////////

	"composition/scope-merging": {
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "app"
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

		_module: opm.#Module & {
			moduleDefinition: _definition

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
		}

		// Validate definition scope preserved in unified view
		result: _module.#allScopes.network.#metadata.#id
		result: "network"

		// Validate platform scope added to unified view
		result2: _module.#allScopes.security.#metadata.#id
		result2: "security"

		// Validate definition scope count
		result3: _module.#status.scopeCount
		result3: 1 // Definition scope count

		// Validate platform scope count
		result4: _module.#status.platformScopeCount
		result4: 1 // Platform scope count
	}
}
