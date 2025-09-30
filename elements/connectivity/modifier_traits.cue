package connectivity

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

/////////////////////////////////////////////////////////////////
//// Connectivity Modifier Traits
/////////////////////////////////////////////////////////////////

// Expose a component as a service
#ExposeElement: core.#ModifierTrait & {
	name:        "Expose"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema:      #ExposeSpec
	description: "Expose component as a service"
	labels: {"core.opm.dev/category": "connectivity"}
}

#Expose: close(core.#ElementBase & {
	#elements: (#ExposeElement.#fullyQualifiedName): #ExposeElement
	expose: #ExposeSpec
})

// Re-export schema types for convenience
#ExposeSpec:     schema.#ExposeSpec
#ExposePortSpec: schema.#ExposePortSpec
