package core

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Health Check Schemas
/////////////////////////////////////////////////////////////////

// Probe specification
#ProbeSpec: {
	httpGet?: {
		path:   string
		port:   uint & >=1 & <=65535
		scheme: "HTTP" | "HTTPS"
	}
	exec?: {
		command: [...string]
	}
	initialDelaySeconds?: int | *0
	periodSeconds?:       int | *10
	timeoutSeconds?:      int | *1
	successThreshold?:    int | *1
	failureThreshold?:    int | *3
}

// Health check specification
#HealthCheckSpec: {
	liveness?:  #ProbeSpec
	readiness?: #ProbeSpec
}

/////////////////////////////////////////////////////////////////
//// Health Check Element
/////////////////////////////////////////////////////////////////

// Add Health Check to component
#HealthCheckElement: opm.#Modifier & {
	name:        "HealthCheck"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: #HealthCheckSpec
	modifies: []
	description: "Liveness and readiness probes for the main container"
	labels: {"core.opm.dev/category": "workload"}
}

#HealthCheck: close(opm.#Component & {
	#elements: (#HealthCheckElement.#fullyQualifiedName): #HealthCheckElement
	healthCheck: #HealthCheckSpec
})
