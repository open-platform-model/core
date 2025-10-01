package elements

import (
	workload "github.com/open-platform-model/core/elements/workload"
	data "github.com/open-platform-model/core/elements/data"
	connectivity "github.com/open-platform-model/core/elements/connectivity"
)

/////////////////////////////////////////////////////////////////
//// Element Index & Registry
/////////////////////////////////////////////////////////////////
//
// This file serves as the main entry point for all elements.
// Import this package to access all element definitions:
//
//   import elements "github.com/open-platform-model/core/elements"
//
// All element definitions from subdirectories are re-exported here.
//
// Elements are organized by category and kind:
//   - primitive_{name}.cue: Basic building blocks
//   - modifier_{name}.cue: Elements that modify other elements
//   - composite_{name}.cue: Compositions of multiple elements
//
/////////////////////////////////////////////////////////////////

// Categories for traits and resources
//
// workload - workload-related (e.g., container, scaling, networking)
// data - data-related (e.g., configmap, secret, volume)
// connectivity - connectivity-related (e.g., service, ingress, api)
// security - security-related (e.g., network policy, pod security)
// observability - observability-related (e.g., logging, monitoring, alerting)
// governance - governance-related (e.g., resource quota, priority, compliance)

/////////////////////////////////////////////////////////////////
//// Core Element Registry
/////////////////////////////////////////////////////////////////

#CoreElementRegistry: {
	// Workload - Primitive Traits
	(#ContainerElement.#fullyQualifiedName): workload.#ContainerElement

	// Workload - Modifier Traits
	(#SidecarContainersElement.#fullyQualifiedName):   workload.#SidecarContainersElement
	(#InitContainersElement.#fullyQualifiedName):      workload.#InitContainersElement
	(#EphemeralContainersElement.#fullyQualifiedName): workload.#EphemeralContainersElement
	(#ReplicasElement.#fullyQualifiedName):            workload.#ReplicasElement
	(#RestartPolicyElement.#fullyQualifiedName):       workload.#RestartPolicyElement
	(#UpdateStrategyElement.#fullyQualifiedName):      workload.#UpdateStrategyElement
	(#HealthCheckElement.#fullyQualifiedName):         workload.#HealthCheckElement

	// Workload - Composite Traits
	(#StatelessWorkloadElement.#fullyQualifiedName):     workload.#StatelessWorkloadElement
	(#StatefulWorkloadElement.#fullyQualifiedName):      workload.#StatefulWorkloadElement
	(#DaemonSetWorkloadElement.#fullyQualifiedName):     workload.#DaemonSetWorkloadElement
	(#TaskWorkloadElement.#fullyQualifiedName):          workload.#TaskWorkloadElement
	(#ScheduledTaskWorkloadElement.#fullyQualifiedName): workload.#ScheduledTaskWorkloadElement

	// Data - Primitive Resources
	(#VolumeElement.#fullyQualifiedName):    data.#VolumeElement
	(#ConfigMapElement.#fullyQualifiedName): data.#ConfigMapElement
	(#SecretElement.#fullyQualifiedName):    data.#SecretElement

	// Data - Composite Traits
	(#SimpleDatabaseElement.#fullyQualifiedName): data.#SimpleDatabaseElement

	// Connectivity - Primitive Traits
	(#NetworkScopeElement.#fullyQualifiedName): connectivity.#NetworkScopeElement

	// Connectivity - Modifier Traits
	(#ExposeElement.#fullyQualifiedName): connectivity.#ExposeElement
}
