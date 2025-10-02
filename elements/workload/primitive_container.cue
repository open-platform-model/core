package workload

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

// Container - Defines a container within a workload
#ContainerElement: core.#Primitive & {
	name:        "Container"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema:       #ContainerSpec
	workloadType: "stateless" | "stateful" | "daemon" | "task" | "scheduled-task"
	description:  "A container definition for workloads"
	labels: {"core.opm.dev/category": "workload"}
}

#Container: close(core.#ElementBase & {
	#elements: (#ContainerElement.#fullyQualifiedName): #ContainerElement
	container: #ContainerSpec
})

// Re-export schema types for convenience
#ContainerSpec:   schema.#ContainerSpec
#VolumeMountSpec: schema.#VolumeMountSpec
#PortSpec:        schema.#PortSpec
#IANA_SVC_NAME:   schema.#IANA_SVC_NAME
