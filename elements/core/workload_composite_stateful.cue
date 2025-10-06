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
	volume: #VolumeSpec
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
		#ReplicasElement,
		#RestartPolicyElement,
		#UpdateStrategyElement,
		#HealthCheckElement,
		#SidecarContainersElement,
		#InitContainersElement,
	]
	annotations: {
		"core.opm.dev/workload-type": "stateful"
	}
	description: "A stateful workload that requires stable identity and storage"
	labels: {"core.opm.dev/category": "workload"}
}

#StatefulWorkload: close(opm.#Component & {
	#elements: (#StatefulWorkloadElement.#fullyQualifiedName): #StatefulWorkloadElement
	stateful: #StatefulWorkloadSpec
})
