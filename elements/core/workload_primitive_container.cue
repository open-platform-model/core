package core

import (
	"strings"
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Container Schemas
/////////////////////////////////////////////////////////////////

// Must start with lowercase letter [a–z],
// end with lowercase letter or digit [a–z0–9],
// and may include hyphens in between.
#IANA_SVC_NAME: string & strings.MinRunes(1) & strings.MaxRunes(15) & =~"^[a-z]([-a-z0-9]{0,13}[a-z0-9])?$"

// Port specification
#PortSpec: {
	// This must be an IANA_SVC_NAME and unique within the pod. Each named port in a pod must have a unique name.
	// Name for the port that can be referred to by services.
	name!: #IANA_SVC_NAME
	// The port that the container will bind to.
	// This must be a valid port number, 0 < x < 65536.
	// If exposedPort is not specified, this value will be used for exposing the port outside the container.
	targetPort!: uint & >=1 & <=65535
	// Protocol for port. Must be UDP, TCP, or SCTP. Defaults to "TCP".
	protocol: *"TCP" | "UDP" | "SCTP"
	// What host IP to bind the external port to.
	hostIP?: string
	// What port to expose on the host.
	// This must be a valid port number, 0 < x < 65536.
	hostPort?: uint & >=1 & <=65535
	...
}

// Volume mount specification
#VolumeMountSpec: close(#VolumeSpec & {
	mountPath!: string
	subPath?:   string
	readOnly?:  bool | *false
})

// Container specification
#ContainerSpec: {
	name!:           string
	image!:          string
	imagePullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"
	ports?: [portName=string]: #PortSpec & {name: portName}
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

/////////////////////////////////////////////////////////////////
//// Container Element
/////////////////////////////////////////////////////////////////

// Container - Defines a container within a workload
#ContainerElement: opm.#Primitive & {
	name:        "Container"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema:      #ContainerSpec
	description: "A container definition for workloads"
	labels: {
		"core.opm.dev/category": "workload"
		// Note: workload-type is determined by the composite element that includes this primitive
	}
}

#Container: close(opm.#Component & {
	#elements: (#ContainerElement.#fullyQualifiedName): #ContainerElement
	container: #ContainerSpec
})
