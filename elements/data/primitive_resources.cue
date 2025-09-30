package data

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

/////////////////////////////////////////////////////////////////
//// Data Primitive Resources
/////////////////////////////////////////////////////////////////

// Volumes as Resources (claims, ephemeral, projected)
#VolumeElement: core.#PrimitiveResource & {
	name:        "Volume"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "A set of volume types for data storage and sharing"
	target: ["component"]
	labels: {"core.opm.dev/category": "data"}
	schema: #VolumeSpec
}

#Volume: close(core.#ElementBase & {
	#elements: (#VolumeElement.#fullyQualifiedName): #VolumeElement

	volumes: [string]: #VolumeSpec
})

// ConfigMaps as Resources
#ConfigMapElement: core.#PrimitiveResource & {
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

// Secrets as Resources
#SecretElement: core.#PrimitiveResource & {
	name:        "Secret"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "Sensitive data such as passwords, tokens, or keys"
	target: ["component"]
	labels: {"core.opm.dev/category": "data"}
	schema: #SecretSpec
}

#Secret: close(core.#ElementBase & {
	#elements: (#SecretElement.#fullyQualifiedName): #SecretElement

	secrets: [string]: #SecretSpec
})

// Re-export schema types for convenience
#VolumeSpec:          schema.#VolumeSpec
#PersistentClaimSpec: schema.#PersistentClaimSpec
#ConfigMapSpec:       schema.#ConfigMapSpec
#SecretSpec:          schema.#SecretSpec
