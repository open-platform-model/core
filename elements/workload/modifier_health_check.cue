package workload

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

// Add Health Check to component
#HealthCheckElement: core.#Modifier & {
	name:        "HealthCheck"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #HealthCheckSpec
	modifies: []
	description: "Liveness and readiness probes for the main container"
	labels: {"core.opm.dev/category": "workload"}
}

#HealthCheck: close(core.#ElementBase & {
	#elements: (#HealthCheckElement.#fullyQualifiedName): #HealthCheckElement
	healthCheck: #HealthCheckSpec
})

// Re-export schema types for convenience
#HealthCheckSpec: schema.#HealthCheckSpec
#ProbeSpec:       schema.#ProbeSpec
