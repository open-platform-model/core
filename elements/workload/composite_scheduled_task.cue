package workload

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

// ScheduledTask workload - A containerized workload that runs on a schedule
#ScheduledTaskWorkloadElement: core.#Composite & {
	name:        "ScheduledTaskWorkload"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #ScheduledTaskWorkloadSpec
	composes: [
		#ContainerElement,
		#RestartPolicyElement,
		#SidecarContainersElement,
		#InitContainersElement,
	]
	workloadType: "scheduled-task"
	description:  "A scheduled task workload that runs on a schedule"
	labels: {"core.opm.dev/category": "workload"}
}

#ScheduledTaskWorkload: close(core.#ElementBase & {
	#elements: (#ScheduledTaskWorkloadElement.#fullyQualifiedName): #ScheduledTaskWorkloadElement
	scheduledTask: #ScheduledTaskWorkloadSpec
})

// Re-export schema types for convenience
#ScheduledTaskWorkloadSpec: schema.#ScheduledTaskWorkloadSpec
