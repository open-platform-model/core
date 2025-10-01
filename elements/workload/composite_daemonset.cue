package workload

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

// DaemonSet workload - A containerized workload that runs on all (or some) nodes in the cluster
#DaemonSetWorkloadElement: core.#Composite & {
	name:        "DaemonSetWorkload"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #DaemonSetSpec
	composes: [
		#ContainerElement,
		#RestartPolicyElement,
		#UpdateStrategyElement,
		#HealthCheckElement,
		#SidecarContainersElement,
		#InitContainersElement,
	]
	workloadType: "daemonSet"
	description:  "A daemonSet workload that runs on all (or some) nodes in the cluster"
	labels: {"core.opm.dev/category": "workload"}
}

#DaemonSetWorkload: close(core.#ElementBase & {
	#elements: (#DaemonSetWorkloadElement.#fullyQualifiedName): #DaemonSetWorkloadElement
	daemonSet: #DaemonSetSpec
})

// Re-export schema types for convenience
#DaemonSetSpec: schema.#DaemonSetSpec
