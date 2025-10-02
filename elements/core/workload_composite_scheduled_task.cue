package core

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Scheduled Task Workload Schema
/////////////////////////////////////////////////////////////////

// Scheduled task workload specification
#ScheduledTaskWorkloadSpec: {
	container:      #ContainerSpec
	restartPolicy?: #RestartPolicySpec
	sidecarContainers?: [#ContainerSpec]
	initContainers?: [#ContainerSpec]

	scheduleCron!:               string // Cron format
	concurrencyPolicy?:          "Allow" | "Forbid" | "Replace" | *"Allow"
	startingDeadlineSeconds?:    int
	successfulJobsHistoryLimit?: int | *3
	failedJobsHistoryLimit?:     int | *1
}

/////////////////////////////////////////////////////////////////
//// Scheduled Task Workload Element
/////////////////////////////////////////////////////////////////

// ScheduledTask workload - A containerized workload that runs on a schedule
#ScheduledTaskWorkloadElement: opm.#Composite & {
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

#ScheduledTaskWorkload: close(opm.#ElementBase & {
	#elements: (#ScheduledTaskWorkloadElement.#fullyQualifiedName): #ScheduledTaskWorkloadElement
	scheduledTask: #ScheduledTaskWorkloadSpec
})
