package core

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Volume Schemas
/////////////////////////////////////////////////////////////////

// Persistent claim specification
#PersistentClaimSpec: {
	size:         string
	accessMode:   "ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany" | *"ReadWriteOnce"
	storageClass: string | *"standard"
}

// Volume specification
#VolumeSpec: {
	name!: string
	emptyDir?: {
		medium?:    *"node" | "memory"
		sizeLimit?: string
	}
	persistentClaim?: #PersistentClaimSpec
	configMap?:       #ConfigMapSpec
	secret?:          #SecretSpec
	...
}

/////////////////////////////////////////////////////////////////
//// Volume Element
/////////////////////////////////////////////////////////////////

// Volumes as Resources (claims, ephemeral, projected)
#VolumeElement: opm.#Primitive & {
	name:        "Volume"
	#apiVersion: "elements.opm.dev/core/v0"
	description: "A set of volume types for data storage and sharing"
	target: ["component"]
	labels: {"core.opm.dev/category": "data"}
	schema: [volumeName=string]: #VolumeSpec & {name: string | *volumeName}
}

#Volume: close(opm.#Component & {
	#elements: (#VolumeElement.#fullyQualifiedName): #VolumeElement

	// Volume field matches the element name's camelCase (volume)
	volume: [volumeName=string]: #VolumeSpec & {name: string | *volumeName}
})
