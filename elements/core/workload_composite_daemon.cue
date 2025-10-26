package core

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Daemon Workload Schema
/////////////////////////////////////////////////////////////////

// Daemon workload specification
#DaemonSpec: {
	container:       #ContainerSpec
	restartPolicy?:  #RestartPolicySpec
	updateStrategy?: #UpdateStrategySpec
	healthCheck?:    #HealthCheckSpec
	sidecarContainers?: [#ContainerSpec]
	initContainers?: [#ContainerSpec]
}

/////////////////////////////////////////////////////////////////
//// Daemon Workload Element
/////////////////////////////////////////////////////////////////

// Daemon workload - A containerized workload that runs on all (or some) nodes in the cluster
#DaemonWorkloadElement: opm.#Composite & {
	name:        "DaemonWorkload"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: #DaemonSpec
	composes: [
		"elements.opm.dev/core/v0.Container",
		"elements.opm.dev/core/v0.SidecarContainers",
		"elements.opm.dev/core/v0.InitContainers",
		"elements.opm.dev/core/v0.RestartPolicy",
		"elements.opm.dev/core/v0.UpdateStrategy",
		"elements.opm.dev/core/v0.HealthCheck",
	]
	description: "A daemonSet workload that runs on all (or some) nodes in the cluster"
	labels: {
		"core.opm.dev/category":      "workload"
		"core.opm.dev/workload-type": "daemon"
	}
}

#DaemonWorkload: close(opm.#Component & {
	#elements: (#DaemonWorkloadElement.#fullyQualifiedName): #DaemonWorkloadElement

	// Add composed elements
	#Container
	#SidecarContainers
	#InitContainers
	#RestartPolicy
	#UpdateStrategy
	#HealthCheck

	daemonWorkload: #DaemonSpec

	container: daemonWorkload.container
	if daemonWorkload.sidecarContainers != _|_ {
		sidecarContainers: daemonWorkload.sidecarContainers
	}
	if daemonWorkload.initContainers != _|_ {
		initContainers: daemonWorkload.initContainers
	}
	if daemonWorkload.restartPolicy != _|_ {
		restartPolicy: daemonWorkload.restartPolicy
	}
	if daemonWorkload.updateStrategy != _|_ {
		updateStrategy: daemonWorkload.updateStrategy
	}
	if daemonWorkload.healthCheck != _|_ {
		healthCheck: daemonWorkload.healthCheck
	}
})
