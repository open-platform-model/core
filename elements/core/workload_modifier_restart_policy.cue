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
	#apiVersion: "elements.opm.dev/core/v0"
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
	if #metadata.labels["core.opm.dev/workload-type"] == "stateless" || #metadata.labels["core.opm.dev/workload-type"] == "stateful" || #metadata.labels["core.opm.dev/workload-type"] == "daemon" {
		// Stateless workloads default to Always
		restartPolicy: #RestartPolicySpec & {
			policy: "Always"
		}
	}
	if #metadata.labels["core.opm.dev/workload-type"] == "task" || #metadata.labels["core.opm.dev/workload-type"] == "scheduled-task" {
		// Task workloads default to OnFailure
		restartPolicy: #RestartPolicySpec & {
			policy: "OnFailure" | "Never" | *"Never"
		}
	}
})
