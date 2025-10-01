package workload

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

// Stateless workload - A horizontally scalable containerized workload with no requirement for stable identity or storage
#StatelessWorkloadElement: core.#Composite & {
	name:         "StatelessWorkload"
	#apiVersion:  "elements.opm.dev/core/v1alpha1"
	workloadType: "stateless"
	target: ["component"]
	schema: #StatelessSpec
	composes: [
		#ContainerElement,
		#ReplicasElement,
		#RestartPolicyElement,
		#UpdateStrategyElement,
		#HealthCheckElement,
		#SidecarContainersElement,
		#InitContainersElement,
	]
	description: "A stateless workload with no requirement for stable identity or storage"
	labels: {"core.opm.dev/category": "workload"}
}

#StatelessWorkload: close(core.#ElementBase & {
	#elements: (#StatelessWorkloadElement.#fullyQualifiedName): #StatelessWorkloadElement
	stateless: #StatelessSpec
})

// Re-export schema types for convenience
#StatelessSpec: schema.#StatelessSpec
