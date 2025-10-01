package workload

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

// Add Sidecar Containers to component
#SidecarContainersElement: core.#Modifier & {
	name:        "SidecarContainers"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: [#ContainerSpec]
	modifies: []
	description: "List of sidecar containers"
	labels: {"core.opm.dev/category": "workload"}
}

#SidecarContainers: close(core.#ElementBase & {
	#elements: (#SidecarContainersElement.#fullyQualifiedName): #SidecarContainersElement
	sidecarContainers: [#ContainerSpec]
})

// Add Init Containers to component
#InitContainersElement: core.#Modifier & {
	name:        "InitContainers"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: [#ContainerSpec]
	modifies: []
	description: "List of init containers"
	labels: {"core.opm.dev/category": "workload"}
}

#InitContainers: close(core.#ElementBase & {
	#elements: InitContainers: #InitContainersElement
	initContainers: [#ContainerSpec]
})

// Add Ephemeral Containers to component (for debugging)
#EphemeralContainersElement: core.#Modifier & {
	name:        "EphemeralContainers"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: [#ContainerSpec]
	modifies: []
	description: "List of ephemeral containers for debugging"
	labels: {"core.opm.dev/category": "workload"}
}

#EphemeralContainers: close(core.#ElementBase & {
	#elements: EphemeralContainers: #EphemeralContainersElement
	ephemeralContainers: [#ContainerSpec]
})

// Re-export schema types for convenience
#ContainerSpec: schema.#ContainerSpec
