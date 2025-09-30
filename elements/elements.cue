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
//// Workload Elements Re-exports
/////////////////////////////////////////////////////////////////

// Workload - Primitive Traits
#ContainerElement: workload.#ContainerElement
#Container:        workload.#Container
#ContainerSpec:    workload.#ContainerSpec

// Workload - Modifier Traits
#SidecarContainersElement:   workload.#SidecarContainersElement
#SidecarContainers:          workload.#SidecarContainers
#InitContainersElement:      workload.#InitContainersElement
#InitContainers:             workload.#InitContainers
#EphemeralContainersElement: workload.#EphemeralContainersElement
#EphemeralContainers:        workload.#EphemeralContainers
#ReplicasElement:            workload.#ReplicasElement
#Replicas:                   workload.#Replicas
#ReplicasSpec:               workload.#ReplicasSpec
#RestartPolicyElement:       workload.#RestartPolicyElement
#RestartPolicy:              workload.#RestartPolicy
#RestartPolicySpec:          workload.#RestartPolicySpec
#UpdateStrategyElement:      workload.#UpdateStrategyElement
#UpdateStrategy:             workload.#UpdateStrategy
#UpdateStrategySpec:         workload.#UpdateStrategySpec
#HealthCheckElement:         workload.#HealthCheckElement
#HealthCheck:                workload.#HealthCheck
#HealthCheckSpec:            workload.#HealthCheckSpec

// Workload - Composite Traits
#StatelessWorkloadElement:     workload.#StatelessWorkloadElement
#StatelessWorkload:            workload.#StatelessWorkload
#StatelessSpec:                workload.#StatelessSpec
#StatefulWorkloadElement:      workload.#StatefulWorkloadElement
#StatefulWorkload:             workload.#StatefulWorkload
#StatefulWorkloadSpec:         workload.#StatefulWorkloadSpec
#DaemonSetWorkloadElement:     workload.#DaemonSetWorkloadElement
#DaemonSetWorkload:            workload.#DaemonSetWorkload
#DaemonSetSpec:                workload.#DaemonSetSpec
#TaskWorkloadElement:          workload.#TaskWorkloadElement
#TaskWorkload:                 workload.#TaskWorkload
#TaskWorkloadSpec:             workload.#TaskWorkloadSpec
#ScheduledTaskWorkloadElement: workload.#ScheduledTaskWorkloadElement
#ScheduledTaskWorkload:        workload.#ScheduledTaskWorkload
#ScheduledTaskWorkloadSpec:    workload.#ScheduledTaskWorkloadSpec

// Workload - Supporting Types
#PortSpec:        workload.#PortSpec
#IANA_SVC_NAME:   workload.#IANA_SVC_NAME
#VolumeMountSpec: workload.#VolumeMountSpec

#ProbeSpec: workload.#ProbeSpec

/////////////////////////////////////////////////////////////////
//// Data Elements Re-exports
/////////////////////////////////////////////////////////////////

// Data - Primitive Resources
#VolumeElement:       data.#VolumeElement
#Volume:              data.#Volume
#VolumeSpec:          data.#VolumeSpec
#PersistentClaimSpec: data.#PersistentClaimSpec
#ConfigMapElement:    data.#ConfigMapElement
#ConfigMap:           data.#ConfigMap
#ConfigMapSpec:       data.#ConfigMapSpec
#SecretElement:       data.#SecretElement
#Secret:              data.#Secret
#SecretSpec:          data.#SecretSpec

// Data - Composite Traits
#SimpleDatabaseElement: data.#SimpleDatabaseElement
#SimpleDatabase:        data.#SimpleDatabase

#SimpleDatabaseSpec: data.#SimpleDatabaseSpec

/////////////////////////////////////////////////////////////////
//// Connectivity Elements Re-exports
/////////////////////////////////////////////////////////////////

// Connectivity - Primitive Traits
#NetworkScopeElement: connectivity.#NetworkScopeElement
#NetworkScope:        connectivity.#NetworkScope
#NetworkScopeSpec:    connectivity.#NetworkScopeSpec

// Connectivity - Modifier Traits
#ExposeElement: connectivity.#ExposeElement
#Expose:        connectivity.#Expose
#ExposeSpec:    connectivity.#ExposeSpec

#ExposePortSpec: connectivity.#ExposePortSpec

/////////////////////////////////////////////////////////////////
//// Core Element Registry
/////////////////////////////////////////////////////////////////

#CoreElementRegistry: {
	// Workload - Primitive Traits
	(#ContainerElement.#fullyQualifiedName): #ContainerElement

	// Workload - Modifier Traits
	(#SidecarContainersElement.#fullyQualifiedName):   #SidecarContainersElement
	(#InitContainersElement.#fullyQualifiedName):      #InitContainersElement
	(#EphemeralContainersElement.#fullyQualifiedName): #EphemeralContainersElement
	(#ReplicasElement.#fullyQualifiedName):            #ReplicasElement
	(#RestartPolicyElement.#fullyQualifiedName):       #RestartPolicyElement
	(#UpdateStrategyElement.#fullyQualifiedName):      #UpdateStrategyElement
	(#HealthCheckElement.#fullyQualifiedName):         #HealthCheckElement

	// Workload - Composite Traits
	(#StatelessWorkloadElement.#fullyQualifiedName):     #StatelessWorkloadElement
	(#StatefulWorkloadElement.#fullyQualifiedName):      #StatefulWorkloadElement
	(#DaemonSetWorkloadElement.#fullyQualifiedName):     #DaemonSetWorkloadElement
	(#TaskWorkloadElement.#fullyQualifiedName):          #TaskWorkloadElement
	(#ScheduledTaskWorkloadElement.#fullyQualifiedName): #ScheduledTaskWorkloadElement

	// Data - Primitive Resources
	(#VolumeElement.#fullyQualifiedName):    #VolumeElement
	(#ConfigMapElement.#fullyQualifiedName): #ConfigMapElement
	(#SecretElement.#fullyQualifiedName):    #SecretElement

	// Data - Composite Traits
	(#SimpleDatabaseElement.#fullyQualifiedName): #SimpleDatabaseElement

	// Connectivity - Primitive Traits
	(#NetworkScopeElement.#fullyQualifiedName): #NetworkScopeElement

	// Connectivity - Modifier Traits
	(#ExposeElement.#fullyQualifiedName): #ExposeElement
}
