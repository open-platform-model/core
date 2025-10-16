package core

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// ConfigMap Schema
/////////////////////////////////////////////////////////////////

// ConfigMap specification
#ConfigMapSpec: {
	data: [string]: string
}

/////////////////////////////////////////////////////////////////
//// ConfigMap Element
/////////////////////////////////////////////////////////////////

// ConfigMaps as Resources
#ConfigMapElement: opm.#Primitive & {
	name:        "ConfigMap"
	#apiVersion: "elements.opm.dev/core/v0"
	description: "Key-value pairs for configuration data"
	target: ["component"]
	labels: {"core.opm.dev/category": "data"}
	schema: #ConfigMapSpec
}

#ConfigMap: close(opm.#Component & {
	#elements: (#ConfigMapElement.#fullyQualifiedName): #ConfigMapElement

	configMaps: [string]: #ConfigMapSpec
})
