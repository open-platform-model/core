package data

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

// Volumes as Resources (claims, ephemeral, projected)
#VolumeElement: core.#Primitive & {
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

// Re-export schema types for convenience
#VolumeSpec:          schema.#VolumeSpec
#PersistentClaimSpec: schema.#PersistentClaimSpec
