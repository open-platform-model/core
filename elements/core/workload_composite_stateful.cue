package core

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Stateful Workload Schema
/////////////////////////////////////////////////////////////////

// Stateful workload specification
#StatefulWorkloadSpec: {
	container:       #ContainerSpec
	replicas?:       #ReplicasSpec
	restartPolicy?:  #RestartPolicySpec
	updateStrategy?: #UpdateStrategySpec
	healthCheck?:    #HealthCheckSpec
	sidecarContainers?: [#ContainerSpec]
	initContainers?: [#ContainerSpec]

	serviceName?: string // Optional name of the service governing this stateful workload
}

/////////////////////////////////////////////////////////////////
//// Stateful Workload Element
/////////////////////////////////////////////////////////////////

// Stateful workload - A containerized workload that requires stable identity and storage
#StatefulWorkloadElement: opm.#Composite & {
	name:        "StatefulWorkload"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #StatefulWorkloadSpec
	composes: [
		#ContainerElement,
		#SidecarContainersElement,
		#InitContainersElement,
		#ReplicasElement,
		#RestartPolicyElement,
		#UpdateStrategyElement,
		#HealthCheckElement,
	]
	annotations: {
		"core.opm.dev/workload-type": "stateful"
	}
	description: "A stateful workload that requires stable identity and storage"
	labels: {"core.opm.dev/category": "workload"}
}

#StatefulWorkload: close(opm.#Component & {
	#elements: (#StatefulWorkloadElement.#fullyQualifiedName): #StatefulWorkloadElement
	statefulWorkload: #StatefulWorkloadSpec

	container: statefulWorkload.container
	if statefulWorkload.sidecarContainers != _|_ {
		sidecarContainers: statefulWorkload.sidecarContainers
	}
	if statefulWorkload.initContainers != _|_ {
		initContainers: statefulWorkload.initContainers
	}
	if statefulWorkload.replicas != _|_ {
		replicas: statefulWorkload.replicas
	}
	if statefulWorkload.restartPolicy != _|_ {
		restartPolicy: statefulWorkload.restartPolicy
	}
	if statefulWorkload.updateStrategy != _|_ {
		updateStrategy: statefulWorkload.updateStrategy
	}
	if statefulWorkload.healthCheck != _|_ {
		healthCheck: statefulWorkload.healthCheck
	}
})
