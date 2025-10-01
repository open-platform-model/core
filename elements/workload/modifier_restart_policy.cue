package workload

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

// Add Restart Policy to component
#RestartPolicyElement: core.#Modifier & {
	name:        "RestartPolicy"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #RestartPolicySpec
	modifies: []
	description: "Restart policy for all containers within the component"
	labels: {"core.opm.dev/category": "workload"}
}

#RestartPolicy: close(core.#ElementBase & {
	#metadata: _
	#elements: (#RestartPolicyElement.#fullyQualifiedName): #RestartPolicyElement
	restartPolicy: #RestartPolicySpec
	if #metadata.workloadType == "stateless" || #metadata.workloadType == "stateful" || #metadata.workloadType == "daemonSet" {
		// Stateless workloads default to Always
		restartPolicy: #RestartPolicySpec & {
			policy: "Always"
		}
	}
	if #metadata.workloadType == "task" || #metadata.workloadType == "scheduled-task" {
		// Task workloads default to OnFailure
		restartPolicy: #RestartPolicySpec & {
			policy: "OnFailure" | "Never" | *"Never"
		}
	}
})

// Re-export schema types for convenience
#RestartPolicySpec: schema.#RestartPolicySpec
