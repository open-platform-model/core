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
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #DaemonSpec
	composes: [
		#ContainerElement,
		#RestartPolicyElement,
		#UpdateStrategyElement,
		#HealthCheckElement,
		#SidecarContainersElement,
		#InitContainersElement,
	]
	annotations: {
		"core.opm.dev/workload-type": "daemon"
	}
	description: "A daemonSet workload that runs on all (or some) nodes in the cluster"
	labels: {"core.opm.dev/category": "workload"}
}

#DaemonWorkload: close(opm.#Component & {
	#elements: (#DaemonWorkloadElement.#fullyQualifiedName): #DaemonWorkloadElement
	daemon: #DaemonSpec
})
