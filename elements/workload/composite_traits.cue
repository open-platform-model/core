package workload

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

/////////////////////////////////////////////////////////////////
//// Workload Composite Traits
/////////////////////////////////////////////////////////////////

// Stateless workload - A horizontally scalable containerized workload with no requirement for stable identity or storage
#StatelessWorkloadElement: core.#CompositeTrait & {
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
		#InitContainersElement
	]
	description: "A stateless workload with no requirement for stable identity or storage"
	labels: {"core.opm.dev/category": "workload"}
}

#StatelessWorkload: close(core.#ElementBase & {
	#elements: (#StatelessWorkloadElement.#fullyQualifiedName): #StatelessWorkloadElement
	stateless: #StatelessSpec
})

// Stateful workload - A containerized workload that requires stable identity and storage
#StatefulWorkloadElement: core.#CompositeTrait & {
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
		#InitContainersElement
	]
	workloadType: "stateful"
	description:  "A stateful workload that requires stable identity and storage"
	labels: {"core.opm.dev/category": "workload"}
}

#StatefulWorkload: close(core.#ElementBase & {
	#elements: (#StatefulWorkloadElement.#fullyQualifiedName): #StatefulWorkloadElement
	stateful: #StatefulWorkloadSpec
})

// DaemonSet workload - A containerized workload that runs on all (or some) nodes in the cluster
#DaemonSetWorkloadElement: core.#CompositeTrait & {
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
		#InitContainersElement
	]
	workloadType: "daemonSet"
	description:  "A daemonSet workload that runs on all (or some) nodes in the cluster"
	labels: {"core.opm.dev/category": "workload"}
}

#DaemonSetWorkload: close(core.#ElementBase & {
	#elements: (#DaemonSetWorkloadElement.#fullyQualifiedName): #DaemonSetWorkloadElement
	daemonSet: #DaemonSetSpec
})

// Task workload - A containerized workload that runs to completion
#TaskWorkloadElement: core.#CompositeTrait & {
	name:        "TaskWorkload"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #TaskWorkloadSpec
	composes: [
		#ContainerElement,
		#RestartPolicyElement,
		#SidecarContainersElement,
		#InitContainersElement
	]
	workloadType: "task"
	description:  "A task workload that runs to completion"
	labels: {"core.opm.dev/category": "workload"}
}

#TaskWorkload: close(core.#ElementBase & {
	#elements: (#TaskWorkloadElement.#fullyQualifiedName): #TaskWorkloadElement
	task: #TaskWorkloadSpec
})

// ScheduledTask workload - A containerized workload that runs on a schedule
#ScheduledTaskWorkloadElement: core.#CompositeTrait & {
	name:        "ScheduledTaskWorkload"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #ScheduledTaskWorkloadSpec
	composes: [
		#ContainerElement,
		#RestartPolicyElement,
		#SidecarContainersElement,
		#InitContainersElement
	]
	workloadType: "scheduled-task"
	description:  "A scheduled task workload that runs on a schedule"
	labels: {"core.opm.dev/category": "workload"}
}

#ScheduledTaskWorkload: close(core.#ElementBase & {
	#elements: (#ScheduledTaskWorkloadElement.#fullyQualifiedName): #ScheduledTaskWorkloadElement
	scheduledTask: #ScheduledTaskWorkloadSpec
})

// Re-export schema types for convenience
#StatelessSpec:             schema.#StatelessSpec
#StatefulWorkloadSpec:      schema.#StatefulWorkloadSpec
#DaemonSetSpec:             schema.#DaemonSetSpec
#TaskWorkloadSpec:          schema.#TaskWorkloadSpec
#ScheduledTaskWorkloadSpec: schema.#ScheduledTaskWorkloadSpec
#ContainerSpec:             schema.#ContainerSpec
#ReplicasSpec:              schema.#ReplicasSpec
#RestartPolicySpec:         schema.#RestartPolicySpec
#UpdateStrategySpec:        schema.#UpdateStrategySpec
#HealthCheckSpec:           schema.#HealthCheckSpec
