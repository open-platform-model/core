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
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: #ReplicasSpec
	modifies: ["elements.opm.dev/core/v0.Container"]
	description: "Number of desired replicas"
	labels: {"core.opm.dev/category": "workload"}
}

#Replicas: close(opm.#Component & {
	#elements: (#ReplicasElement.#fullyQualifiedName): #ReplicasElement
	replicas: #ReplicasSpec
})
