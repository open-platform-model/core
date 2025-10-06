package core

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Volume Schemas
/////////////////////////////////////////////////////////////////

// Persistent claim specification
#PersistentClaimSpec: {
	size:          string
	accessMode:    "ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany" | *"ReadWriteOnce"
	storageClass?: string | *"standard"
}

// Volume specification
#VolumeSpec: {
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
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "A set of volume types for data storage and sharing"
	target: ["component"]
	labels: {"core.opm.dev/category": "data"}
	schema: #VolumeSpec
}

#Volume: close(opm.#Component & {
	#elements: (#VolumeElement.#fullyQualifiedName): #VolumeElement

	volumes: [string]: #VolumeSpec
})
