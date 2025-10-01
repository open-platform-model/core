package workload

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

// Add Replicas to component
#ReplicasElement: core.#Modifier & {
	name:        "Replicas"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #ReplicasSpec
	modifies: []
	description: "Number of desired replicas"
	labels: {"core.opm.dev/category": "workload"}
}

#Replicas: close(core.#ElementBase & {
	#elements: (#ReplicasElement.#fullyQualifiedName): #ReplicasElement
	replicas: #ReplicasSpec
})

// Re-export schema types for convenience
#ReplicasSpec: schema.#ReplicasSpec
