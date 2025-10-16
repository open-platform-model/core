package core

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Network Scope Schema
/////////////////////////////////////////////////////////////////

// Network scope specification
#NetworkScopeSpec: {
	networkPolicy: {
		// Whether components in this scope can communicate with each other
		internalCommunication?: bool | *true

		// Whether components in this scope can communicate with components outside the scope
		externalCommunication?: bool | *false
	}
}

/////////////////////////////////////////////////////////////////
//// Network Scope Element
/////////////////////////////////////////////////////////////////

// Network Scope as Trait
#NetworkScopeElement: opm.#Primitive & {
	name:        "NetworkScope"
	#apiVersion: "elements.opm.dev/core/v0"
	description: "Primitive scope to define a shared network boundary"
	target: ["scope"]
	labels: {"core.opm.dev/category": "connectivity"}
	schema: #NetworkScopeSpec
}

#NetworkScope: opm.#Component & {
	#elements: (#NetworkScopeElement.#fullyQualifiedName): #NetworkScopeElement

	networkScope: #NetworkScopeSpec
}
