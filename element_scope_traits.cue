package core

/////////////////////////////////////////////////////////////////
//// Trait catalog
/////////////////////////////////////////////////////////////////
// Categories for traits and resources
//
// workload - workload-related (e.g., container, scaling, networking)
// data - data-related (e.g., configmap, secret, volume)
// connectivity - connectivity-related (e.g., service, ingress, api)
// security - security-related (e.g., network policy, pod security)
// observability - observability-related (e.g., logging, monitoring, alerting)
// governance - governance-related (e.g., resource quota, priority, compliance)

#CoreElementRegistry: {
	(#NetworkScopeElement.#fullyQualifiedName): #NetworkScopeElement
}

// Network Scope as Trait
#NetworkScopeElement: #PrimitiveTrait & {
	#name:       "NetworkScope"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "Primitive scope to define a shared network boundary"
	target: ["scope"]
	labels: {"core.opm.dev/category": "connectivity"}
	#schema: #NetworkScopeSpec
}

#NetworkScope: #ElementBase & {
	#elements: (#NetworkScopeElement.#fullyQualifiedName): #NetworkScopeElement

	networkScope: #NetworkScopeSpec
}

#NetworkScopeSpec: {
	networkPolicy: {
		// Whether components in this scope can communicate with each other
		internalCommunication?: bool | *true

		// Whether components in this scope can communicate with components outside the scope
		externalCommunication?: bool | *false
	}
}
