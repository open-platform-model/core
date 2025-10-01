package data

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

// ConfigMaps as Resources
#ConfigMapElement: core.#Primitive & {
	name:        "ConfigMap"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "Key-value pairs for configuration data"
	target: ["component"]
	labels: {"core.opm.dev/category": "data"}
	schema: #ConfigMapSpec
}

#ConfigMap: close(core.#ElementBase & {
	#elements: (#ConfigMapElement.#fullyQualifiedName): #ConfigMapElement

	configMaps: [string]: #ConfigMapSpec
})

// Re-export schema types for convenience
#ConfigMapSpec: schema.#ConfigMapSpec
