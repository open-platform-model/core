package connectivity

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

// Expose a component as a service
// TODO: Investigate if this should be a modifier or primitive or split into two elements
#ExposeElement: core.#Primitive & {
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
