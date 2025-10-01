package workload

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

// Add Update Strategy to component
#UpdateStrategyElement: core.#Modifier & {
	name:        "UpdateStrategy"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #UpdateStrategySpec
	modifies: []
	description: "Update strategy for the component"
	labels: {"core.opm.dev/category": "workload"}
}

#UpdateStrategy: close(core.#ElementBase & {
	#metadata: _
	#elements: (#UpdateStrategyElement.#fullyQualifiedName): #UpdateStrategyElement
	updateStrategy: #UpdateStrategySpec & {
		if #metadata.workloadType == "stateless" {
			type: "RollingUpdate" | "Recreate" | *"RollingUpdate"
			rollingUpdate?: {
				maxUnavailable: int | *1
				maxSurge:       int | *1
			}
		}
		if #metadata.workloadType == "stateful" {
			type: "RollingUpdate" | "OnDelete" | *"RollingUpdate"
			rollingUpdate?: {
				partition: int | *0
			}
		}
		if #metadata.workloadType == "daemonSet" {
			type: "RollingUpdate" | "OnDelete" | *"RollingUpdate"
			rollingUpdate: {
				maxUnavailable: int | *1
			}
		}
	}
})

// Re-export schema types for convenience
#UpdateStrategySpec: schema.#UpdateStrategySpec
