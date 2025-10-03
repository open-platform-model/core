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
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #HealthCheckSpec
	modifies: []
	description: "Liveness and readiness probes for the main container"
	labels: {"core.opm.dev/category": "workload"}
}

#HealthCheck: close(opm.#ElementBase & {
	#elements: (#HealthCheckElement.#fullyQualifiedName): #HealthCheckElement
	healthCheck: #HealthCheckSpec
})
