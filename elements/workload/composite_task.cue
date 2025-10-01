package workload

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

// Task workload - A containerized workload that runs to completion
#TaskWorkloadElement: core.#Composite & {
	name:        "TaskWorkload"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #TaskWorkloadSpec
	composes: [
		#ContainerElement,
		#RestartPolicyElement,
		#SidecarContainersElement,
		#InitContainersElement,
	]
	workloadType: "task"
	description:  "A task workload that runs to completion"
	labels: {"core.opm.dev/category": "workload"}
}

#TaskWorkload: close(core.#ElementBase & {
	#elements: (#TaskWorkloadElement.#fullyQualifiedName): #TaskWorkloadElement
	task: #TaskWorkloadSpec
})

// Re-export schema types for convenience
#TaskWorkloadSpec: schema.#TaskWorkloadSpec
