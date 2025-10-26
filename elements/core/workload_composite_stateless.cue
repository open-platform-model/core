package core

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Stateless Workload Schema
/////////////////////////////////////////////////////////////////

// Stateless workload specification
#StatelessSpec: {
	container:       #ContainerSpec
	replicas?:       #ReplicasSpec
	restartPolicy?:  #RestartPolicySpec
	updateStrategy?: #UpdateStrategySpec
	healthCheck?:    #HealthCheckSpec
	sidecarContainers?: [#ContainerSpec]
	initContainers?: [#ContainerSpec]
}

/////////////////////////////////////////////////////////////////
//// Stateless Workload Element
/////////////////////////////////////////////////////////////////

// Stateless workload - A horizontally scalable containerized workload with no requirement for stable identity or storage
#StatelessWorkloadElement: opm.#Composite & {
	name:        "StatelessWorkload"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: #StatelessSpec
	composes: [
		"elements.opm.dev/core/v0.Container",
		"elements.opm.dev/core/v0.SidecarContainers",
		"elements.opm.dev/core/v0.InitContainers",
		"elements.opm.dev/core/v0.Replicas",
		"elements.opm.dev/core/v0.RestartPolicy",
		"elements.opm.dev/core/v0.UpdateStrategy",
		"elements.opm.dev/core/v0.HealthCheck",
	]
	description: "A stateless workload with no requirement for stable identity or storage"
	labels: {
		"core.opm.dev/category":      "workload"
		"core.opm.dev/workload-type": "stateless"
	}
}

#StatelessWorkload: close(opm.#Component & {
	#elements: (#StatelessWorkloadElement.#fullyQualifiedName): #StatelessWorkloadElement

	// Add composed elements
	#Container
	#SidecarContainers
	#InitContainers
	#Replicas
	#RestartPolicy
	#UpdateStrategy
	#HealthCheck

	statelessWorkload: #StatelessSpec

	container: statelessWorkload.container
	if statelessWorkload.sidecarContainers != _|_ {
		sidecarContainers: statelessWorkload.sidecarContainers
	}
	if statelessWorkload.initContainers != _|_ {
		initContainers: statelessWorkload.initContainers
	}
	if statelessWorkload.replicas != _|_ {
		replicas: statelessWorkload.replicas
	}
	if statelessWorkload.restartPolicy != _|_ {
		restartPolicy: statelessWorkload.restartPolicy
	}
	if statelessWorkload.updateStrategy != _|_ {
		updateStrategy: statelessWorkload.updateStrategy
	}
	if statelessWorkload.healthCheck != _|_ {
		healthCheck: statelessWorkload.healthCheck
	}
})
