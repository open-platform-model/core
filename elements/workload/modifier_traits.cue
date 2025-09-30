package workload

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

/////////////////////////////////////////////////////////////////
//// Workload Modifier Traits
/////////////////////////////////////////////////////////////////

// Add Sidecar Containers to component
#SidecarContainersElement: core.#ModifierTrait & {
	name:        "SidecarContainers"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: [#ContainerSpec]
	description: "List of sidecar containers"
	labels: {"core.opm.dev/category": "workload"}
}

#SidecarContainers: close(core.#ElementBase & {
	#elements: (#SidecarContainersElement.#fullyQualifiedName): #SidecarContainersElement
	sidecarContainers: [#ContainerSpec]
})

// Add Init Containers to component
#InitContainersElement: core.#ModifierTrait & {
	name:        "InitContainers"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: [#ContainerSpec]
	description: "List of init containers"
	labels: {"core.opm.dev/category": "workload"}
}

#InitContainers: close(core.#ElementBase & {
	#elements: InitContainers: #InitContainersElement
	initContainers: [#ContainerSpec]
})

// Add Ephemeral Containers to component
#EphemeralContainersElement: core.#ModifierTrait & {
	name:        "EphemeralContainers"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: [#ContainerSpec]
	description: "List of ephemeral containers"
	labels: {"core.opm.dev/category": "workload"}
}

#EphemeralContainers: close(core.#ElementBase & {
	#elements: (#EphemeralContainersElement.#fullyQualifiedName): #EphemeralContainersElement
	ephemeralContainers: [#ContainerSpec]
})

// Add Replicas to component
#ReplicasElement: core.#ModifierTrait & {
	name:        "Replicas"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema:      #ReplicasSpec
	description: "Number of desired replicas"
	labels: {"core.opm.dev/category": "workload"}
}

#Replicas: close(core.#ElementBase & {
	#elements: (#ReplicasElement.#fullyQualifiedName): #ReplicasElement
	replicas: #ReplicasSpec
})

// Add Restart Policy to component
#RestartPolicyElement: core.#ModifierTrait & {
	name:        "RestartPolicy"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema:      #RestartPolicySpec
	description: "Restart policy for all containers within the component"
	labels: {"core.opm.dev/category": "workload"}
}

#RestartPolicy: close(core.#ElementBase & {
	#metadata: _
	#elements: (#RestartPolicyElement.#fullyQualifiedName): #RestartPolicyElement
	restartPolicy: #RestartPolicySpec
	if #metadata.workloadType == "stateless" || #metadata.workloadType == "stateful" || #metadata.workloadType == "daemonSet" {
		// Stateless workloads default to Always
		restartPolicy: #RestartPolicySpec & {
			policy: "Always"
		}
	}
	if #metadata.workloadType == "task" || #metadata.workloadType == "scheduled-task" {
		// Task workloads default to OnFailure
		restartPolicy: #RestartPolicySpec & {
			policy: "OnFailure" | "Never" | *"Never"
		}
	}
})

// Add Update Strategy to component
#UpdateStrategyElement: core.#ModifierTrait & {
	name:        "UpdateStrategy"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema:      #UpdateStrategySpec
	description: "Update strategy for the component"
	labels: {"core.opm.dev/category": "workload"}
}

#UpdateStrategy: close(core.#ElementBase & {
	#metadata: _
	#elements: (#UpdateStrategyElement.#fullyQualifiedName): #UpdateStrategyElement
	updateStrategy: #UpdateStrategySpec & {
		if #metadata.workloadType == "stateless" {
			type: "RollingUpdate" | "Recreate" | *"RollingUpdate"
			rollingUpdate?: {
				maxUnavailable: int | *1
				maxSurge:       int | *1
			}
		}
		if #metadata.workloadType == "stateful" {
			type: "RollingUpdate" | "OnDelete" | *"RollingUpdate"
			rollingUpdate?: {
				partition: int | *0
			}
		}
		if #metadata.workloadType == "daemonSet" {
			type: "RollingUpdate" | "OnDelete" | *"RollingUpdate"
			rollingUpdate: {
				maxUnavailable: int | *1
			}
		}
	}
})

// Add Health Check to component
#HealthCheckElement: core.#ModifierTrait & {
	name:        "HealthCheck"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema:      #HealthCheckSpec
	description: "Liveness and readiness probes for the main container"
	labels: {"core.opm.dev/category": "workload"}
}

#HealthCheck: close(core.#ElementBase & {
	#elements: (#HealthCheckElement.#fullyQualifiedName): #HealthCheckElement
	healthCheck: #HealthCheckSpec
})

// Re-export schema types for convenience
#ReplicasSpec:       schema.#ReplicasSpec
#RestartPolicySpec:  schema.#RestartPolicySpec
#UpdateStrategySpec: schema.#UpdateStrategySpec
#HealthCheckSpec:    schema.#HealthCheckSpec
#ProbeSpec:          schema.#ProbeSpec
