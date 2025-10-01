package workload

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

// Stateful workload - A containerized workload that requires stable identity and storage
#StatefulWorkloadElement: core.#Composite & {
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
	workloadType: "stateful"
	description:  "A stateful workload that requires stable identity and storage"
	labels: {"core.opm.dev/category": "workload"}
}

#StatefulWorkload: close(core.#ElementBase & {
	#elements: (#StatefulWorkloadElement.#fullyQualifiedName): #StatefulWorkloadElement
	stateful: #StatefulWorkloadSpec
})

// Re-export schema types for convenience
#StatefulWorkloadSpec: schema.#StatefulWorkloadSpec
