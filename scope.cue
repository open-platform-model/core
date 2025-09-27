package core

import (
	"list"
)

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

		// Validation: Scopes must have exactly one trait
		#validateSingleTrait: len(#elements) == 1 | error("Scope must have exactly one trait. Current count: \(len(#elements))")
	}

	#elements: [elementName=string]: #Element & {#name!: elementName}

	// Helper: Extract ALL primitive elements (recursively traverses composite elements)
	#primitiveElements: [...string]
	#primitiveElements: {
		// Collect all primitive elements
		let allElements = [
			for _, e in #elements if e != _|_ {
				// Primitive traits contribute themselves
				if e.kind == "primitive" {
					e.#fullyQualifiedName
				}
			},
		]

		// Deduplicate and sort
		let set = {for cap in allElements {(cap): _}}
		list.SortStrings([for k, _ in set {k}])
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
