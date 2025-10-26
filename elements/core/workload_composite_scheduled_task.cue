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
	restartPolicy?: "OnFailure" | "Never" | *"Never"
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
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: #ScheduledTaskWorkloadSpec
	composes: [
		"elements.opm.dev/core/v0.Container",
		"elements.opm.dev/core/v0.SidecarContainers",
		"elements.opm.dev/core/v0.InitContainers",
		"elements.opm.dev/core/v0.RestartPolicy",
	]
	description: "A scheduled task workload that runs on a schedule"
	labels: {
		"core.opm.dev/category":      "workload"
		"core.opm.dev/workload-type": "scheduled-task"
	}
}

#ScheduledTaskWorkload: close(opm.#Component & {
	#elements: (#ScheduledTaskWorkloadElement.#fullyQualifiedName): #ScheduledTaskWorkloadElement

	// Add composed elements
	#Container
	#SidecarContainers
	#InitContainers
	#RestartPolicy

	scheduledTaskWorkload: #ScheduledTaskWorkloadSpec

	container: scheduledTaskWorkload.container
	if scheduledTaskWorkload.sidecarContainers != _|_ {
		sidecarContainers: scheduledTaskWorkload.sidecarContainers
	}
	if scheduledTaskWorkload.initContainers != _|_ {
		initContainers: scheduledTaskWorkload.initContainers
	}
	if scheduledTaskWorkload.restartPolicy != _|_ {
		restartPolicy: scheduledTaskWorkload.restartPolicy
	}
})
