package core

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Expose Schemas
/////////////////////////////////////////////////////////////////

// Expose port specification (extends PortSpec from workload schema)
#ExposePortSpec: close(#PortSpec & {
	// The port that will be exposed outside the container.
	// exposedPort in combination with exposed must inform the platform of what port to map to the container when exposing.
	// This must be a valid port number, 0 < x < 65536.
	exposedPort?: uint & >=1 & <=65535
})

// Expose specification
#ExposeSpec: {
	ports: [portName=string]: #ExposePortSpec & {name: portName}
	type: "ClusterIP" | "NodePort" | "LoadBalancer" | *"ClusterIP"
}

/////////////////////////////////////////////////////////////////
//// Expose Element
/////////////////////////////////////////////////////////////////

// Expose a component as a service
// TODO: Investigate if this should be a modifier or primitive or split into two elements
#ExposeElement: opm.#Primitive & {
	name:        "Expose"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema:      #ExposeSpec
	description: "Expose component as a service"
	labels: {"core.opm.dev/category": "connectivity"}
}

#Expose: close(opm.#Component & {
	#elements: (#ExposeElement.#fullyQualifiedName): #ExposeElement
	expose: #ExposeSpec
})
