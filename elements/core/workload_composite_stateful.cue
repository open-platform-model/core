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
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: #StatefulWorkloadSpec
	composes: [
		"elements.opm.dev/core/v0.Container",
		"elements.opm.dev/core/v0.SidecarContainers",
		"elements.opm.dev/core/v0.InitContainers",
		"elements.opm.dev/core/v0.Replicas",
		"elements.opm.dev/core/v0.RestartPolicy",
		"elements.opm.dev/core/v0.UpdateStrategy",
		"elements.opm.dev/core/v0.HealthCheck",
	]
	description: "A stateful workload that requires stable identity and storage"
	labels: {
		"core.opm.dev/category":      "workload"
		"core.opm.dev/workload-type": "stateful"
	}
}

#StatefulWorkload: close(opm.#Component & {
	#elements: (#StatefulWorkloadElement.#fullyQualifiedName): #StatefulWorkloadElement

	// Add composed elements
	#Container
	#SidecarContainers
	#InitContainers
	#Replicas
	#RestartPolicy
	#UpdateStrategy
	#HealthCheck

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
