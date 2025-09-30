package schema

import (
	"strings"
)

/////////////////////////////////////////////////////////////////
//// Workload Schema Definitions
/////////////////////////////////////////////////////////////////

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

// Volume mount specification
#VolumeMountSpec: {
	name!:      string
	mountPath!: string
	subPath?:   string
	readOnly?:  bool | *false
}

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

// Replicas specification
#ReplicasSpec: {
	count: int | *1
}

// Restart policy specification
#RestartPolicySpec: {
	policy: "Always" | "OnFailure" | "Never" | *"Always"
}

// Update strategy specification
#UpdateStrategySpec: {
	type: "RollingUpdate" | "Recreate" | "OnDelete" | *"RollingUpdate"
	rollingUpdate?: {
		maxUnavailable?: int | *1
		maxSurge?:       int | *1
		partition?:      int | *0
	}
}

// Health check specification
#HealthCheckSpec: {
	liveness?:  #ProbeSpec
	readiness?: #ProbeSpec
}

// Probe specification
#ProbeSpec: {
	httpGet?: {
		path:   string
		port:   uint & >=1 & <=65535
		scheme: "HTTP" | "HTTPS"
	}
}

// Stateless workload specification
#StatelessSpec: {
	container:       #ContainerSpec
	replicas?:       #ReplicasSpec
	restartPolicy?:  #RestartPolicySpec
	updateStrategy?: #UpdateStrategySpec
	healthCheck?:    #HealthCheckSpec
	sidecarContainers?: [#ContainerSpec]
	initContainers?: [#ContainerSpec]
}

// Stateful workload specification
#StatefulWorkloadSpec: {
	container:       #ContainerSpec
	replicas?:       #ReplicasSpec
	restartPolicy?:  #RestartPolicySpec
	updateStrategy?: #UpdateStrategySpec
	healthCheck?:    #HealthCheckSpec
	sidecarContainers?: [#ContainerSpec]
	initContainers?: [#ContainerSpec]
	volume: #VolumeSpec
}

// DaemonSet workload specification
#DaemonSetSpec: {
	container:       #ContainerSpec
	restartPolicy?:  #RestartPolicySpec
	updateStrategy?: #UpdateStrategySpec
	healthCheck?:    #HealthCheckSpec
	sidecarContainers?: [#ContainerSpec]
	initContainers?: [#ContainerSpec]
}

// Task workload specification
#TaskWorkloadSpec: {
	container:      #ContainerSpec
	restartPolicy?: #RestartPolicySpec
	sidecarContainers?: [#ContainerSpec]
	initContainers?: [#ContainerSpec]

	completions?:             int | *1
	parallelism?:             int | *1
	backoffLimit?:            int | *6
	activeDeadlineSeconds?:   int | *300
	ttlSecondsAfterFinished?: int | *100
}

// Scheduled task workload specification
#ScheduledTaskWorkloadSpec: {
	container:      #ContainerSpec
	restartPolicy?: #RestartPolicySpec
	sidecarContainers?: [#ContainerSpec]
	initContainers?: [#ContainerSpec]

	scheduleCron!:               string // Cron format
	concurrencyPolicy?:          "Allow" | "Forbid" | "Replace" | *"Allow"
	startingDeadlineSeconds?:    int
	successfulJobsHistoryLimit?: int | *3
	failedJobsHistoryLimit?:     int | *1
}
