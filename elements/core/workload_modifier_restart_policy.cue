package core

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Restart Policy Schema
/////////////////////////////////////////////////////////////////

// Restart policy specification
#RestartPolicySpec: {
	policy: "Always" | "OnFailure" | "Never" | *"Always"
}

/////////////////////////////////////////////////////////////////
//// Restart Policy Element
/////////////////////////////////////////////////////////////////

// Add Restart Policy to component
#RestartPolicyElement: opm.#Modifier & {
	name:        "RestartPolicy"
	#apiVersion: "elements.opm.dev/core/v0alpha1"
	target: ["component"]
	schema: #RestartPolicySpec
	modifies: []
	description: "Restart policy for all containers within the component"
	labels: {"core.opm.dev/category": "workload"}
}

#RestartPolicy: close(opm.#Component & {
	#metadata: _
	#elements: (#RestartPolicyElement.#fullyQualifiedName): #RestartPolicyElement
	restartPolicy: #RestartPolicySpec
	if #metadata.workloadType == "stateless" || #metadata.workloadType == "stateful" || #metadata.workloadType == "daemon" {
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
