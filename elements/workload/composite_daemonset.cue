package workload

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

// Daemon workload - A containerized workload that runs on all (or some) nodes in the cluster
#DaemonWorkloadElement: core.#Composite & {
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
	workloadType: "daemon"
	description:  "A daemonSet workload that runs on all (or some) nodes in the cluster"
	labels: {"core.opm.dev/category": "workload"}
}

#DaemonWorkload: close(core.#ElementBase & {
	#elements: (#DaemonWorkloadElement.#fullyQualifiedName): #DaemonWorkloadElement
	daemon: #DaemonSpec
})

// Re-export schema types for convenience
#DaemonSpec: schema.#DaemonSpec
