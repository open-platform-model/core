package core

/////////////////////////////////////////////////////////////////
//// Module
/////////////////////////////////////////////////////////////////

#ModuleDefinition: {
	#apiVersion: "core.opm.dev/v1"
	#kind:       "ModuleDefinition"
	#metadata: {
		name!:             #NameType
		defaultNamespace?: string | *"default"
		version!:          #VersionType
		description?:      string

		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	components: [Id=string]: #Component & {#metadata: #id: Id}

	// Developer-defined module scopes
	scopes?: [Id=string]: #Scope & {#metadata: #id: Id}

	// User-configurable values (like Helm values)
	// ALL fields MUST be optional to allow override
	// MUST be OpenAPIv3 compliant
	values: {
		// Example structure (all optional with defaults):
		// replicas?:     uint | *3
		// image?: {
		//     repository?: string | *"nginx"
		//     tag?:        string | *"1.0.0"
		// }
		...
	}

	#status: {
		componentCount: len(components)
		scopeCount:     len(scopes)
	}
}

// Module is a clustered resource that references a ModuleDefinition and adds platform-specific configuration'
// Platform can add components and scopes but not remove
// Platform can modify defaults in values but not structure
#Module: {
	#apiVersion: "core.opm.dev/v1"
	#kind:       "Module"
	#metadata: {
		name:     #NameType
		version?: #VersionType

		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// Platform context for this module instance
	#context: {...}

	#moduleDefinition: #ModuleDefinition

	// Platform can add components but not remove
	components?: [Id=string]: #Component & {#metadata: #id: Id}
	#allComponents: {
		if #moduleDefinition.components != _|_ {#moduleDefinition.components}
		if components != _|_ {components}
	}

	// Platform can add scopes but not remove
	scopes?: [Id=string]: #Scope & {#metadata: #id: Id}
	#allScopes: {
		if #moduleDefinition.scopes != _|_ {#moduleDefinition.scopes}
		if scopes != _|_ {scopes}
	}

	// Platform can modify defaults but not structure
	values?: #moduleDefinition.values & {
		...
	}

	#status: {
		totalComponentCount: len(#allComponents)
		platformScopes: [
			for id, scope in scopes if scope.#metadata.immutable {id},
		]
		platformComponentCount: int | *0
		platformComponentCount: {if components != _|_ {len(components)}}
		platformScopeCount: int | *0
		platformScopeCount: {if scopes != _|_ {len(scopes)}}
	}
}
