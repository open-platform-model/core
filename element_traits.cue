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

// Containers as Traits
#Container: #ElementBase & {
	#elements: Container: #PrimitiveTrait & {
		description: "Single container primitive"
		target: ["component"]
		labels: {"core.opm.dev/category": "workload"}
		#schema: #ContainerSpec
	}

	container: #ContainerSpec
}

#ContainerSpec: {
	name:            string
	image:           string
	imagePullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"
	ports?: [string]: {
		containerPort: int
		protocol?:     "TCP" | "UDP" | *"TCP"
	}
	env?: [string]: {
		name:  string
		value: string
	}
	resources?: {
		limits?: {
			cpu?:    string
			memory?: string
		}
		requests?: {
			cpu?:    string
			memory?: string
		}
	}
	volumeMounts?: [string]: #VolumeMountSpec
}

// Sidecar Containers as Traits
#SideCarContainers: #ElementBase & {
	#elements: SideCarContainers: #PrimitiveTrait & {
		description: "List of sidecar containers"
		target: ["component"]
		labels: {"core.opm.dev/category": "workload"}
		#schema: [#ContainerSpec]
	}

	sideCarContainers: [#ContainerSpec]
}

// Network Scope as Trait
#NetworkScope: #ElementBase & {
	#elements: NetworkScope: #PrimitiveTrait & {
		description: "Primitive scope to define a shared network boundary"
		target: ["scope"]
		labels: {"core.opm.dev/category": "connectivity"}
		#schema: #NetworkScopeSpec
	}

	networkScope: #NetworkScopeSpec
}

#NetworkScopeSpec: {
	policy: {
		// Whether components in this scope can communicate with each other
		internalCommunication?: bool | *true

		// Whether components in this scope can communicate with components outside the scope
		externalCommunication?: bool | *false
	}
}
