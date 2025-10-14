package core

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Task Workload Schema
/////////////////////////////////////////////////////////////////

// Task workload specification
#TaskWorkloadSpec: {
	container:      #ContainerSpec
	restartPolicy?: #RestartPolicySpec
	sidecarContainers?: [#ContainerSpec]
	initContainers?: [#ContainerSpec]

	completions?:             int | *1
	parallelism?:             int | *1
	backoffLimit?:            int | *6
	activeDeadlineSeconds?:   int | *300
	ttlSecondsAfterFinished?: int | *100
}

/////////////////////////////////////////////////////////////////
//// Task Workload Element
/////////////////////////////////////////////////////////////////

// Task workload - A containerized workload that runs to completion
#TaskWorkloadElement: opm.#Composite & {
	name:        "TaskWorkload"
	#apiVersion: "elements.opm.dev/core/v0alpha1"
	target: ["component"]
	schema: #TaskWorkloadSpec
	composes: [
		#ContainerElement,
		#SidecarContainersElement,
		#InitContainersElement,
		#RestartPolicyElement,
	]
	description: "A task workload that runs to completion"
	annotations: {
		"core.opm.dev/workload-type": "task"
	}
	labels: {"core.opm.dev/category": "workload"}
}

#TaskWorkload: close(opm.#Component & {
	#elements: (#TaskWorkloadElement.#fullyQualifiedName): #TaskWorkloadElement
	taskWorkload: #TaskWorkloadSpec

	container: taskWorkload.container
	if taskWorkload.sidecarContainers != _|_ {
		sidecarContainers: taskWorkload.sidecarContainers
	}
	if taskWorkload.initContainers != _|_ {
		initContainers: taskWorkload.initContainers
	}
	if taskWorkload.restartPolicy != _|_ {
		restartPolicy: taskWorkload.restartPolicy
	}
})
