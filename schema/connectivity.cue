package schema

/////////////////////////////////////////////////////////////////
//// Connectivity Schema Definitions
/////////////////////////////////////////////////////////////////

// Network scope specification
#NetworkScopeSpec: {
	networkPolicy: {
		// Whether components in this scope can communicate with each other
		internalCommunication?: bool | *true

		// Whether components in this scope can communicate with components outside the scope
		externalCommunication?: bool | *false
	}
}

// Expose specification
#ExposeSpec: {
	ports: [portName=string]: #ExposePortSpec & {name: portName}
	type: "ClusterIP" | "NodePort" | "LoadBalancer" | *"ClusterIP"
}

// Expose port specification (extends PortSpec from workload schema)
#ExposePortSpec: close(#PortSpec & {
	// The port that will be exposed outside the container.
	// exposedPort in combination with exposed must inform the platform of what port to map to the container when exposing.
	// This must be a valid port number, 0 < x < 65536.
	exposedPort?: uint & >=1 & <=65535
})
