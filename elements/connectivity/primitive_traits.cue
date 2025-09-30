package connectivity

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

/////////////////////////////////////////////////////////////////
//// Connectivity Primitive Traits
/////////////////////////////////////////////////////////////////

// Network Scope as Trait
#NetworkScopeElement: core.#PrimitiveTrait & {
	name:        "NetworkScope"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "Primitive scope to define a shared network boundary"
	target: ["scope"]
	labels: {"core.opm.dev/category": "connectivity"}
	schema: #NetworkScopeSpec
}

#NetworkScope: core.#ElementBase & {
	#elements: (#NetworkScopeElement.#fullyQualifiedName): #NetworkScopeElement

	networkScope: #NetworkScopeSpec
}

// Re-export schema types for convenience
#NetworkScopeSpec: schema.#NetworkScopeSpec
