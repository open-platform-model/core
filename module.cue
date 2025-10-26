package core

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

	// Note: Primitive elements are now resolved by the OPM CLI runtime
	// The runtime analyzes all components and extracts their primitive elements

	// Schema/constraints for configurable values
	// Developers define the configuration contract - NO defaults, NO templating
	// Platform teams can add defaults and refine constraints via CUE merging
	// MUST be OpenAPIv3 compliant (no CUE templating - for/if statements)
	// TODO: Add OpenAPIv3 validation
	values: {...}

	#status: {
		componentCount: len(components)
		scopeCount:     int | *0
		scopeCount: {if scopes != _|_ {len(scopes)}}
	}
})

// Module is for end-user deployment
// References a CatalogModule (which bundles definition + transformers + renderer)
// End-users only need to provide concrete values
#Module: close(#ModuleBase & {
	#apiVersion: "core.opm.dev/v0"
	#kind:       "Module"
	M=#metadata: {
		name!:        #NameType
		namespace: string | *"default"
		version?:     #VersionType
		labels?:    #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// End-user provides concrete values
	V=values: {...}

	// Reference to CatalogModule (contains definition + transformers + renderer)
	// For local development: inline #CatalogModule definition
	// For production: reference from platform catalog
	#module!: #CatalogModule & {
		// Merge end-user values into the module definition
		moduleDefinition: {
			values: V

			// Unify module metadata into each component
			components: [ID=_]: #Component & {
				#metadata: {
					namespace: string | *M.namespace
					labels: M.labels
					annotations: M.annotations
				}
			}
		}
	}

	// Note: Output rendering is now handled by the OPM CLI runtime
	// The CLI will:
	// 1. Analyze components to resolve primitives
	// 2. Match transformers from provider to components
	// 3. Execute transformers to generate resources
	// 4. Execute renderer to produce final output
	//
	// For pure CUE rendering without CLI, this section would need to be reimplemented
	// using the provider.transformers map and runtime matching logic

	#status: {
		definitionName: #module.moduleDefinition.#metadata.name
	}
})
