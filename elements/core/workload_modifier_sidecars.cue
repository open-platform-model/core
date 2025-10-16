package core

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Sidecar, Init, and Ephemeral Container Modifiers
/////////////////////////////////////////////////////////////////

// Add Sidecar Containers to component
#SidecarContainersElement: opm.#Modifier & {
	name:        "SidecarContainers"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: [#ContainerSpec]
	modifies: []
	description: "List of sidecar containers"
	labels: {"core.opm.dev/category": "workload"}
}

#SidecarContainers: close(opm.#Component & {
	#elements: (#SidecarContainersElement.#fullyQualifiedName): #SidecarContainersElement
	sidecarContainers: [#ContainerSpec]
})

// Add Init Containers to component
#InitContainersElement: opm.#Modifier & {
	name:        "InitContainers"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: [#ContainerSpec]
	modifies: []
	description: "List of init containers"
	labels: {"core.opm.dev/category": "workload"}
}

#InitContainers: close(opm.#Component & {
	#elements: (#InitContainersElement.#fullyQualifiedName): #InitContainersElement
	initContainers: [#ContainerSpec]
})

// Add Ephemeral Containers to component (for debugging)
#EphemeralContainersElement: opm.#Modifier & {
	name:        "EphemeralContainers"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: [#ContainerSpec]
	modifies: []
	description: "List of ephemeral containers for debugging"
	labels: {"core.opm.dev/category": "workload"}
}

#EphemeralContainers: close(opm.#Component & {
	#elements: (#EphemeralContainersElement.#fullyQualifiedName): #EphemeralContainersElement
	ephemeralContainers: [#ContainerSpec]
})
