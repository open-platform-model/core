package core

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Replicas Schema
/////////////////////////////////////////////////////////////////

// Replicas specification
#ReplicasSpec: {
	count: int | *1
}

/////////////////////////////////////////////////////////////////
//// Replicas Element
/////////////////////////////////////////////////////////////////

// Add Replicas to component
#ReplicasElement: opm.#Modifier & {
	name:        "Replicas"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #ReplicasSpec
	modifies: []
	description: "Number of desired replicas"
	labels: {"core.opm.dev/category": "workload"}
}

#Replicas: close(opm.#ElementBase & {
	#elements: (#ReplicasElement.#fullyQualifiedName): #ReplicasElement
	replicas: #ReplicasSpec
})
