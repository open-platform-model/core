package core

import (
	"strings"
)

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
	(#ContainerElement.#fullyQualifiedName):           #ContainerElement
	(#SidecarContainersElement.#fullyQualifiedName):   #SidecarContainersElement
	(#InitContainersElement.#fullyQualifiedName):      #InitContainersElement
	(#EphemeralContainersElement.#fullyQualifiedName): #EphemeralContainersElement
	(#ReplicasElement.#fullyQualifiedName):            #ReplicasElement
	(#RestartPolicyElement.#fullyQualifiedName):       #RestartPolicyElement
	(#UpdateStrategyElement.#fullyQualifiedName):      #UpdateStrategyElement
	(#ExposeElement.#fullyQualifiedName):              #ExposeElement
}

// Containers
#ContainerElement: #PrimitiveTrait & {
	#name:       "Container"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "Single container primitive"
	target: ["component"]
	labels: {"core.opm.dev/category": "workload"}
	#schema: #ContainerSpec
}

#Container: close(#ElementBase & {
	#elements: (#ContainerElement.#fullyQualifiedName): #ContainerElement
	container: #ContainerSpec
})

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

// Add Sidecar Containers to component
#SidecarContainersElement: #PrimitiveTrait & {
	#name:       "SidecarContainers"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "List of sidecar containers"
	target: ["component"]
	labels: {"core.opm.dev/category": "workload"}
	#schema: [#ContainerSpec]
}

#SidecarContainers: close(#ElementBase & {
	#elements: (#SidecarContainersElement.#fullyQualifiedName): #SidecarContainersElement
	sidecarContainers: [#ContainerSpec]
})

// Add Init Containers to component
#InitContainersElement: #PrimitiveTrait & {
	#name:       "InitContainers"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "List of init containers"
	target: ["component"]
	labels: {"core.opm.dev/category": "workload"}
	#schema: [#ContainerSpec]
}

#InitContainers: close(#ElementBase & {
	#elements: InitContainers: #InitContainersElement
	initContainers: [#ContainerSpec]
})

// Add Ephemeral Containers to component
#EphemeralContainersElement: #PrimitiveTrait & {
	#name:       "EphemeralContainers"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "List of ephemeral containers"
	target: ["component"]
	labels: {"core.opm.dev/category": "workload"}
	#schema: [#ContainerSpec]
}

#EphemeralContainers: close(#ElementBase & {
	#elements: (#EphemeralContainersElement.#fullyQualifiedName): #EphemeralContainersElement
	ephemeralContainers: [#ContainerSpec]
})

// Add Replicas to component
#ReplicasElement: #PrimitiveTrait & {
	#name:       "Replicas"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "Number of desired replicas"
	target: ["component"]
	labels: {"core.opm.dev/category": "workload"}
	#schema: #ReplicasSpec
}

#Replicas: close(#ElementBase & {
	#elements: (#ReplicasElement.#fullyQualifiedName): #ReplicasElement
	replicas: #ReplicasSpec
})

#ReplicasSpec: {
	count: int | *1
}

// Add Restart Policy to component
#RestartPolicyElement: #PrimitiveTrait & {
	#name:       "RestartPolicy"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "Restart policy for all containers within the component"
	target: ["component"]
	labels: {"core.opm.dev/category": "workload"}
	#schema: #RestartPolicySpec
}

#RestartPolicy: close(#ElementBase & {
	#elements: (#RestartPolicyElement.#fullyQualifiedName): #RestartPolicyElement
	restartPolicy: #RestartPolicySpec
})

#RestartPolicySpec: {
	policy: "Always" | "OnFailure" | "Never" | *"Always"
}

// Add Update Strategy to component
#UpdateStrategyElement: #PrimitiveTrait & {
	#name:       "UpdateStrategy"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "Update strategy for the component"
	target: ["component"]
	labels: {"core.opm.dev/category": "workload"}
	#schema: #UpdateStrategySpec
}

#UpdateStrategy: close(#ElementBase & {
	#elements: (#UpdateStrategyElement.#fullyQualifiedName): #UpdateStrategyElement
	updateStrategy: #UpdateStrategySpec
})

#UpdateStrategySpec: {
	type: "RollingUpdate" | "Recreate" | *"RollingUpdate"
	rollingUpdate?: {
		maxUnavailable: int | string | *1
		maxSurge:       int | string | *1
	}
}

// Expose a component as a service
#ExposeElement: #PrimitiveTrait & {
	#name:       "Expose"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "Expose component as a service"
	target: ["component"]
	labels: {"core.opm.dev/category": "connectivity"}
	#schema: #ExposeSpec
}

#Expose: close(#ElementBase & {
	#elements: (#ExposeElement.#fullyQualifiedName): #ExposeElement
	expose: #ExposeSpec
})

#ExposeSpec: {
	ports: [string]: #ExposePortSpec
	type: "ClusterIP" | "NodePort" | "LoadBalancer" | *"ClusterIP"
}

// Must start with lowercase letter [a–z],
// end with lowercase letter or digit [a–z0–9],
// and may include hyphens in between.
#IANA_SVC_NAME: string & strings.MinRunes(1) & strings.MaxRunes(15) & =~"^[a-z]([-a-z0-9]{0,13}[a-z0-9])?$"

#PortSpec: {
	// The port that the container will bind to.
	// This must be a valid port number, 0 < x < 65536.
	// If exposedPort is not specified, this value will be used for exposing the port outside the container.
	targetPort!: uint & >=1 & <=65535
	// This must be an IANA_SVC_NAME and unique within the pod. Each named port in a pod must have a unique name.
	// Name for the port that can be referred to by services.
	name!: #IANA_SVC_NAME
	// Protocol for port. Must be UDP, TCP, or SCTP. Defaults to "TCP". 
	protocol: *"TCP" | "UDP" | "SCTP"
	// What host IP to bind the external port to.
	hostIP?: string
	// What port to expose on the host.
	// This must be a valid port number, 0 < x < 65536.
	hostPort?: uint & >=1 & <=65535
	...
}

#ExposePortSpec: close(#PortSpec & {
	// The port that will be exposed outside the container.
	// exposedPort in combination with exposed must inform the platform of what port to map to the container when exposing.
	// This must be a valid port number, 0 < x < 65536.
	exposedPort?: uint & >=1 & <=65535
})
