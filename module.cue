package core

import (
	"list"
)

/////////////////////////////////////////////////////////////////
//// Module
/////////////////////////////////////////////////////////////////
#ModuleBase: {
	#apiVersion: "core.opm.dev/v0"
	#metadata: {
		name!:    #NameType
		version!: #VersionType

		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
		...
	}
	#status: {...}
	...
}

#ModuleDefinition: close(#ModuleBase & {
	#apiVersion: "core.opm.dev/v0"
	#kind:       "ModuleDefinition"
	#metadata: {
		name!:             #NameType
		defaultNamespace?: string | *"default"
		version!:          #VersionType
		description?:      string

		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// Components defined in this module
	components: [Id=string]: #Component & {#metadata: #id: Id}

	// Developer-defined module scopes
	scopes?: [Id=string]: #Scope & {#metadata: #id: Id}

	// Collect all primitive elements from all components
	// Use a struct to deduplicate, then extract keys for unique list
	_primitivesMap: {
		for _, comp in components {
			for _, prim in comp.#primitiveElements {
				(prim): true
			}
		}
	}
	#allPrimitiveElements: #ElementStringArray & [for prim, _ in _primitivesMap {prim}]

	// Schema/constraints for configurable values
	// Developers define the configuration contract - NO defaults, NO templating
	// Platform teams can add defaults and refine constraints via CUE merging
	// MUST be OpenAPIv3 compliant (no CUE templating - for/if statements)
	values: {...}

	#status: {
		componentCount: len(components)
		scopeCount:     int | *0
		scopeCount: {if scopes != _|_ {len(scopes)}}
	}
})

// Module is for end-user deployment
// References a ModuleDefinition and provides concrete values
// Includes embedded render logic
#Module: close(#ModuleBase & {
	#apiVersion: "core.opm.dev/v0"
	#kind:       "Module"
	#metadata: {
		name!:        #NameType
		namespace:    string | *"default"
		version?:     #VersionType
		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// End-user provides concrete values
	V=values: {...}

	// Reference to upstream ModuleDefinition with values merged
	#moduleDefinition!: #ModuleDefinition & {values: V}

	// Explicit transformer-to-component mapping
	// Users define which transformers apply to which components
	// Can use CUE expressions to derive component lists dynamically
	// Example:
	//   #transformersToComponents: {
	//     "k8s.io/api/apps/v1.Deployment": {
	//       transformer: common.#DeploymentTransformer
	//       components: [
	//         for id, comp in #moduleDefinition.components
	//         if transformer.#metadata.labels["core.opm.dev/workload-type"] == comp.#metadata.labels["core.opm.dev/workload-type"] &&
	//            list.Contains(comp.#primitiveElements, "elements.opm.dev/core/v0.Container") {
	//           id
	//         }
	//       ]
	//     }
	//   }
	#transformersToComponents!: [string]: {
		transformer: #Transformer
		components: [...string] // List of component IDs
	}

	// Renderer chosen by platform team - REQUIRED
	#renderer!: #Renderer

	// Render output
	output: {
		// Collect resources from all components by applying transformers
		// Uses explicit transformer-to-component mapping from #transformersToComponents
		// Iterates transformers first (fewer outer iterations)
		_componentOutputs: {
			for transformerFQN, mapping in #transformersToComponents {
				(transformerFQN): [
					// For each component in the mapping
					for componentID in mapping.components {
						let comp = #moduleDefinition.components[componentID]

						// Apply transformer to component
						(mapping.transformer & {
							transform: {
								#component: comp
								#context: #TransformerContext & {
									name:              #moduleDefinition.#metadata.name
									namespace:         #metadata.namespace
									moduleMetadata:    #moduleDefinition.#metadata & #metadata
									componentMetadata: comp.#metadata
								}
							}
						}).transform.output
					},
				]
			}
		}

		// Flatten to single list of transformer outputs
		_transformerOutputs: [for _, outputs in _componentOutputs {outputs}]

		// Flatten to single list of resources
		#resources: list.FlattenN(_transformerOutputs, 2)

		// Render using Module's renderer
		_rendered: (#renderer.render & {
			resources: #resources
		}).output

		// Expose rendered outputs conditionally
		if _rendered.manifest != _|_ {
			manifest: _rendered.manifest
		}
		if _rendered.files != _|_ {
			files: _rendered.files
		}
		if _rendered.metadata != _|_ {
			metadata: _rendered.metadata
		}
	}

	#status: {
		definitionName: #moduleDefinition.#metadata.name
	}
})
