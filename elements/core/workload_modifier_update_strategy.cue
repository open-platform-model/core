package core

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Update Strategy Schema
/////////////////////////////////////////////////////////////////

// Update strategy specification
#UpdateStrategySpec: {
	type: "RollingUpdate" | "Recreate" | "OnDelete" | *"RollingUpdate"
	rollingUpdate?: {
		maxUnavailable?: int | *1
		maxSurge?:       int | *1
		partition?:      int | *0
	}
}

/////////////////////////////////////////////////////////////////
//// Update Strategy Element
/////////////////////////////////////////////////////////////////

// Add Update Strategy to component
#UpdateStrategyElement: opm.#Modifier & {
	name:        "UpdateStrategy"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: #UpdateStrategySpec
	modifies: []
	description: "Update strategy for the component"
	labels: {"core.opm.dev/category": "workload"}
}

#UpdateStrategy: close(opm.#Component & {
	#metadata: _
	#elements: (#UpdateStrategyElement.#fullyQualifiedName): #UpdateStrategyElement
	updateStrategy: #UpdateStrategySpec & {
		if #metadata.labels["core.opm.dev/workload-type"] == "stateless" {
			type: "RollingUpdate" | "Recreate" | *"RollingUpdate"
			rollingUpdate?: {
				maxUnavailable: int | *1
				maxSurge:       int | *1
			}
		}
		if #metadata.labels["core.opm.dev/workload-type"] == "stateful" {
			type: "RollingUpdate" | "OnDelete" | *"RollingUpdate"
			rollingUpdate?: {
				partition: int | *0
			}
		}
		if #metadata.labels["core.opm.dev/workload-type"] == "daemon" {
			type: "RollingUpdate" | "OnDelete" | *"RollingUpdate"
			rollingUpdate: {
				maxUnavailable: int | *1
			}
		}
	}
})
