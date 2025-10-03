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
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	annotations: {
		"core.opm.dev/workload-type": "stateless"
	}
	target: ["component"]
	schema: #StatelessSpec
	composes: [
		#ContainerElement,
		#SidecarContainersElement,
		#InitContainersElement,
		#ReplicasElement,
		#RestartPolicyElement,
		#UpdateStrategyElement,
		#HealthCheckElement,
	]
	description: "A stateless workload with no requirement for stable identity or storage"
	labels: {"core.opm.dev/category": "workload"}
}

#StatelessWorkload: close(opm.#ElementBase & {
	#elements: (#StatelessWorkloadElement.#fullyQualifiedName): #StatelessWorkloadElement
	stateless: #StatelessSpec
})
