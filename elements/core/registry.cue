// Core Element Registry
// This file aggregates all core elements into a registry
package core

#ElementRegistry: {
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
	(#DaemonWorkloadElement.#fullyQualifiedName):        #DaemonWorkloadElement
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
