package core

/////////////////////////////////////////////////////////////////
//// Scope
/////////////////////////////////////////////////////////////////

#Scope: {
	#kind:       "Scope"
	#apiVersion: "core.opm.dev/v0"
	#metadata: {
		#id!: string

		name!: string | *#id

		// Platform scopes are immutable by developers
		immutable: bool
	}

	#elements: #ElementMap

	// Validation: Scopes must have exactly one trait
	#validateSingleTrait: len(#elements) == 1 | error("Scope must have exactly one trait. Current count: \(len(#elements))")

	// Helper: Extract ALL primitive elements (recursively traverses composite elements)
	#primitiveElements: #ElementStringArray & [
		// Collect primitives from all elements
		for _, element in #elements {
			// If it's primitive, add it directly
			if element.kind == "primitive" {(element.#fullyQualifiedName)}

			// If it's composite, merge its primitives
			if element.kind == "composite" for _, p in element.#primitiveElements {(p)}
		},
	]

	appliesTo!: [...#Component] | "*"
	...
}

// ModuleScope is a scope defined by the ModuleDefinition author
#ModuleScope: #Scope & {
	#metadata: {
		immutable: false
	}
}

// PlatformScope is a scope defined by the platform and immutable by developers
#PlatformScope: #Scope & {
	#metadata: {
		immutable: true
	}
}
