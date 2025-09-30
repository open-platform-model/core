package elements

/////////////////////////////////////////////////////////////////
//// Element Registry
/////////////////////////////////////////////////////////////////

#CoreElementRegistry: {
	// Primitive Traits
	(#ContainerElement.#fullyQualifiedName):    #ContainerElement
	(#NetworkScopeElement.#fullyQualifiedName): #NetworkScopeElement
	// Primitive Resources
	(#VolumeElement.#fullyQualifiedName):    #VolumeElement
	(#ConfigMapElement.#fullyQualifiedName): #ConfigMapElement
	(#SecretElement.#fullyQualifiedName):    #SecretElement
	// Modifier Traits
	(#SidecarContainersElement.#fullyQualifiedName):   #SidecarContainersElement
	(#InitContainersElement.#fullyQualifiedName):      #InitContainersElement
	(#EphemeralContainersElement.#fullyQualifiedName): #EphemeralContainersElement
	(#ReplicasElement.#fullyQualifiedName):            #ReplicasElement
	(#RestartPolicyElement.#fullyQualifiedName):       #RestartPolicyElement
	(#UpdateStrategyElement.#fullyQualifiedName):      #UpdateStrategyElement
	(#HealthCheckElement.#fullyQualifiedName):         #HealthCheckElement
	(#ExposeElement.#fullyQualifiedName):              #ExposeElement
	// Composite Traits
	(#StatelessWorkloadElement.#fullyQualifiedName):     #StatelessWorkloadElement
	(#StatefulWorkloadElement.#fullyQualifiedName):      #StatefulWorkloadElement
	(#DaemonSetWorkloadElement.#fullyQualifiedName):     #DaemonSetWorkloadElement
	(#TaskWorkloadElement.#fullyQualifiedName):          #TaskWorkloadElement
	(#ScheduledTaskWorkloadElement.#fullyQualifiedName): #ScheduledTaskWorkloadElement
	(#SimpleDatabaseElement.#fullyQualifiedName):        #SimpleDatabaseElement
}
