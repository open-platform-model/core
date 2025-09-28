package core

/////////////////////////////////////////////////////////////////
//// Scope
/////////////////////////////////////////////////////////////////

#Scope: {
	#kind:       "Scope"
	#apiVersion: "core.opm.dev/v1alpha1"
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
	#primitiveElements: #ElementMap
	#primitiveElements: {
		// Collect primitives from all elements
		for elementName, element in #elements {
			// If it's primitive, add it directly
			if element.kind == "primitive" {
				(elementName): element
			}
			// If it's composite, merge its primitives
			if element.kind == "composite" {
				for primName, primElement in element.#primitiveElements {
					(primName): primElement
				}
			}
		}
	}

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
