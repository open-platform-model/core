// Module Renderer Integration Tests
// Tests module rendering with the new renderer pattern
package integration

import (
	opm "github.com/open-platform-model/core"
	core "github.com/open-platform-model/core/elements/core"
)

moduleRendererTests: {
	//////////////////////////////////////////////////////////////////
	// Module with Renderer - Full Integration Test
	//////////////////////////////////////////////////////////////////

	"module-renderer/simple-module-with-kubernetes-list": {
		// Define a simple transformer
		_deploymentTransformer: opm.#Transformer & {
			#kind:       "Deployment"
			#apiVersion: "k8s.io/api/apps/v1"
			required: ["elements.opm.dev/core/v0.Container"]
			optional: []

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
						replicas: 1
						template: spec: containers: [#component.container]
					}
				}]
			}
		}

		// Define module definition
		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "test-app"
				version: "1.0.0"
			}

			components: {
				web: core.#StatelessWorkload & {
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
			}

			values: {}
		}

		// Create module instance with transformers and renderer
		_module: opm.#Module & {
			#metadata: {
				name:      "test-app"
				namespace: "production"
			}

			#moduleDefinition: _definition

			// Attach transformers
			#transformers: {
				"k8s.io/api/apps/v1.Deployment": _deploymentTransformer
			}

			// Attach renderer
			#renderer: opm.#KubernetesListRenderer

			values: {}
		}

		// Validate manifest was rendered
		_manifestExists: _module.output.manifest != _|_
		_manifestExists: true

		// Validate manifest structure
		_module: output: manifest: {
			apiVersion: "v1"
			kind:       "List"
		}

		// Validate metadata
		_module: output: metadata: format: "yaml"
	}

	//////////////////////////////////////////////////////////////////
	// Module with Multiple Components (multiple resources)
	//////////////////////////////////////////////////////////////////

	"module-renderer/multiple-components": {
		_deploymentTransformer: opm.#Transformer & {
			#kind:       "Deployment"
			#apiVersion: "k8s.io/api/apps/v1"
			required: ["elements.opm.dev/core/v0.Container"]
			optional: []

			transform: {
				#component: opm.#Component
				#context:   opm.#TransformerContext

				output: [{
					apiVersion: "apps/v1"
					kind:       "Deployment"
					metadata: {
						name:      #context.componentMetadata.name
						namespace: #context.namespace
					}
				}]
			}
		}

		_definition: opm.#ModuleDefinition & {
			#metadata: {
				name:    "multi-component-app"
				version: "1.0.0"
			}

			components: {
				web: core.#StatelessWorkload & {
					#metadata: {
						#id:  "web"
						name: "web"
					}
					statelessWorkload: container: {
						name:  "nginx"
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
			#metadata: {
				name:      "multi-component-app"
				namespace: "staging"
			}

			#moduleDefinition: _definition

			#transformers: {
				"k8s.io/api/apps/v1.Deployment": _deploymentTransformer
			}

			#renderer: opm.#KubernetesListRenderer

			values: {}
		}

		// Validate manifest contains items
		_manifestItemCount: len(_module.output.manifest.items)
		_manifestItemCount: 2
	}
}
