package elements

import (
	"strings"

	core "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Trait catalog
/////////////////////////////////////////////////////////////////
//
// Categories for traits and resources
//
// workload - workload-related (e.g., container, scaling, networking)
// data - data-related (e.g., configmap, secret, volume, database)
// connectivity - connectivity-related (e.g., service, ingress, api)
// security - security-related (e.g., network policy, pod security)
// observability - observability-related (e.g., logging, monitoring, alerting)
// governance - governance-related (e.g., resource quota, priority, compliance)
//
/////////////////////////////////////////////////////////////////
//// Primitives Traits
/////////////////////////////////////////////////////////////////

// Container - Defines a container within a workload
#ContainerElement: core.#PrimitiveTrait & {
	name:       "Container"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #ContainerSpec
	// Only allow workloadType to be one of the supported types
	workloadType: "stateless" | "stateful" | "daemonSet" | "task" | "scheduled-task"
	description: "A container definition for workloads"
	labels: {"core.opm.dev/category": "workload"}
}

#Container: close(core.#ElementBase & {
	#elements: (#ContainerElement.#fullyQualifiedName): #ContainerElement
	container: #ContainerSpec
})

#ContainerSpec: {
	name!:            string
	image!:           string
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
//// Modifier Traits
/////////////////////////////////////////////////////////////////

// Add Sidecar Containers to component
#SidecarContainersElement: core.#ModifierTrait & {
	name:       "SidecarContainers"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: [#ContainerSpec]
	description: "List of sidecar containers"
	labels: {"core.opm.dev/category": "workload"}
}

#SidecarContainers: close(core.#ElementBase & {
	#elements: (#SidecarContainersElement.#fullyQualifiedName): #SidecarContainersElement
	sidecarContainers: [#ContainerSpec]
})

// Add Init Containers to component
#InitContainersElement: core.#ModifierTrait & {
	name:       "InitContainers"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: [#ContainerSpec]
	description: "List of init containers"
	labels: {"core.opm.dev/category": "workload"}
}

#InitContainers: close(core.#ElementBase & {
	#elements: InitContainers: #InitContainersElement
	initContainers: [#ContainerSpec]
})

// Add Ephemeral Containers to component
#EphemeralContainersElement: core.#ModifierTrait & {
	name:       "EphemeralContainers"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: [#ContainerSpec]
	description: "List of ephemeral containers"
	labels: {"core.opm.dev/category": "workload"}
}

#EphemeralContainers: close(core.#ElementBase & {
	#elements: (#EphemeralContainersElement.#fullyQualifiedName): #EphemeralContainersElement
	ephemeralContainers: [#ContainerSpec]
})

// Add Replicas to component
#ReplicasElement: core.#ModifierTrait & {
	name:       "Replicas"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #ReplicasSpec
	description: "Number of desired replicas"
	labels: {"core.opm.dev/category": "workload"}
}

#Replicas: close(core.#ElementBase & {
	#elements: (#ReplicasElement.#fullyQualifiedName): #ReplicasElement
	replicas: #ReplicasSpec
})

#ReplicasSpec: {
	count: int | *1
}

// Add Restart Policy to component
#RestartPolicyElement: core.#ModifierTrait & {
	name:       "RestartPolicy"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #RestartPolicySpec
	description: "Restart policy for all containers within the component"
	labels: {"core.opm.dev/category": "workload"}
}

#RestartPolicy: close(core.#ElementBase & {
	#metadata: _
	#elements: (#RestartPolicyElement.#fullyQualifiedName): #RestartPolicyElement
	restartPolicy: #RestartPolicySpec
	if #metadata.workloadType == "stateless" || #metadata.workloadType == "stateful" || #metadata.workloadType == "daemonSet" {
		// Stateless workloads default to Always
		restartPolicy: #RestartPolicySpec & {
			policy: "Always"
		}
	}
	if #metadata.workloadType == "task" || #metadata.workloadType == "scheduled-task" {
		// Task workloads default to OnFailure
		restartPolicy: #RestartPolicySpec & {
			policy: "OnFailure" | "Never" | *"Never"
		}
	}
})

#RestartPolicySpec: {
	policy: "Always" | "OnFailure" | "Never" | *"Always"
}

// Add Update Strategy to component
#UpdateStrategyElement: core.#ModifierTrait & {
	name:       "UpdateStrategy"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #UpdateStrategySpec
	description: "Update strategy for the component"
	labels: {"core.opm.dev/category": "workload"}
}

#UpdateStrategy: close(core.#ElementBase & {
	#metadata: _
	#elements: (#UpdateStrategyElement.#fullyQualifiedName): #UpdateStrategyElement
	updateStrategy: #UpdateStrategySpec & {
		if #metadata.workloadType == "stateless" {
			type: "RollingUpdate" | "Recreate" | *"RollingUpdate"
			rollingUpdate?: {
				maxUnavailable: int | *1
				maxSurge:       int | *1
			}
		}
		if #metadata.workloadType == "stateful" {
			type: "RollingUpdate" | "OnDelete" | *"RollingUpdate"
			rollingUpdate?: {
				partition: int | *0
			}
		}
		if #metadata.workloadType == "daemonSet" {
			type: "RollingUpdate" | "OnDelete" | *"RollingUpdate"
			rollingUpdate: {
				maxUnavailable: int | *1
			}
		}
	}
})

#UpdateStrategySpec: {
	type: "RollingUpdate" | "Recreate" | "OnDelete" | *"RollingUpdate"
	rollingUpdate?: {
		maxUnavailable?: int | *1
		maxSurge?:       int | *1
		partition?:      int | *0
	}
}

// Add Health Check to component
#HealthCheckElement: core.#ModifierTrait & {
	name:       "HealthCheck"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #HealthCheckSpec
	description: "Liveness and readiness probes for the main container"
	labels: {"core.opm.dev/category": "workload"}
}

#HealthCheck: close(core.#ElementBase & {
	#elements: (#HealthCheckElement.#fullyQualifiedName): #HealthCheckElement
	healthCheck: #HealthCheckSpec
})

#HealthCheckSpec: {
	liveness?:  #ProbeSpec
	readiness?: #ProbeSpec
}

#ProbeSpec: {
	httpGet?: {
		path:   string
		port:   uint & >=1 & <=65535
		scheme: "HTTP" | "HTTPS"
	}
}

// Expose a component as a service
#ExposeElement: core.#ModifierTrait & {
	name:       "Expose"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #ExposeSpec
	description: "Expose component as a service"
	labels: {"core.opm.dev/category": "connectivity"}
}

#Expose: close(core.#ElementBase & {
	#elements: (#ExposeElement.#fullyQualifiedName): #ExposeElement
	expose: #ExposeSpec
})

#ExposeSpec: {
	ports: [portName=string]: #ExposePortSpec & {name: portName}
	type: "ClusterIP" | "NodePort" | "LoadBalancer" | *"ClusterIP"
}

// Must start with lowercase letter [a–z],
// end with lowercase letter or digit [a–z0–9],
// and may include hyphens in between.
#IANA_SVC_NAME: string & strings.MinRunes(1) & strings.MaxRunes(15) & =~"^[a-z]([-a-z0-9]{0,13}[a-z0-9])?$"

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

#ExposePortSpec: close(#PortSpec & {
	// The port that will be exposed outside the container.
	// exposedPort in combination with exposed must inform the platform of what port to map to the container when exposing.
	// This must be a valid port number, 0 < x < 65536.
	exposedPort?: uint & >=1 & <=65535
})

/////////////////////////////////////////////////////////////////
//// Composite Traits
/////////////////////////////////////////////////////////////////

// Sateless workload - A horizontally scalable containerized workload with no requirement for stable identity or storage
#StatelessWorkloadElement: core.#CompositeTrait & {
	name:        "StatelessWorkload"
	#apiVersion:  "elements.opm.dev/core/v1alpha1"
	workloadType: "stateless"
	target: ["component"]
	schema: #StatelessSpec
	composes: [#ContainerElement, #ReplicasElement, #RestartPolicyElement, #UpdateStrategyElement, #HealthCheckElement, #SidecarContainersElement, #InitContainersElement]
	description:  "A stateless workload with no requirement for stable identity or storage"
	labels: {"core.opm.dev/category": "workload"}
}

#StatelessSpec: {
	container:       #ContainerSpec
	replicas?:       #ReplicasSpec
	restartPolicy?:  #RestartPolicySpec
	updateStrategy?: #UpdateStrategySpec
	healthCheck?:    #HealthCheckSpec
	sidecarContainers?: [#ContainerSpec]
	initContainers?: [#ContainerSpec]
}

#StatelessWorkload: close(core.#ElementBase & {
	#elements: (#StatelessWorkloadElement.#fullyQualifiedName): #StatelessWorkloadElement
	stateless: #StatelessSpec
})

// Stateful workload - A containerized workload that requires stable identity and storage
#StatefulWorkloadElement: core.#CompositeTrait & {
	name:        "StatefulWorkload"
	#apiVersion:  "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #StatefulWorkloadSpec
	composes: [#ContainerElement, #ReplicasElement, #RestartPolicyElement, #UpdateStrategyElement, #HealthCheckElement, #SidecarContainersElement, #InitContainersElement, #VolumeElement]
	workloadType: "stateful"
	description:  "A stateful workload that requires stable identity and storage"
	labels: {"core.opm.dev/category": "workload"}
}

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

#StatefulWorkload: close(core.#ElementBase & {
	#elements: (#StatefulWorkloadElement.#fullyQualifiedName): #StatefulWorkloadElement
	stateful: #StatefulWorkloadSpec
})

// DaemonSet workload - A containerized workload that runs on all (or some) nodes in the cluster
#DaemonSetWorkloadElement: core.#CompositeTrait & {
	name:        "DaemonSetWorkload"
	#apiVersion:  "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #DaemonSetSpec
	composes: [#ContainerElement, #RestartPolicyElement, #UpdateStrategyElement, #HealthCheckElement, #SidecarContainersElement, #InitContainersElement]
	workloadType: "daemonSet"
	description:  "A daemonSet workload that runs on all (or some) nodes in the cluster"
	labels: {"core.opm.dev/category": "workload"}
}

#DaemonSetWorkload: close(core.#ElementBase & {
	#elements: (#DaemonSetWorkloadElement.#fullyQualifiedName): #DaemonSetWorkloadElement
	daemonSet: #DaemonSetSpec
})

#DaemonSetSpec: {
	container:       #ContainerSpec
	restartPolicy?:  #RestartPolicySpec
	updateStrategy?: #UpdateStrategySpec
	healthCheck?:    #HealthCheckSpec
	sidecarContainers?: [#ContainerSpec]
	initContainers?: [#ContainerSpec]
}

// Task workload - A containerized workload that runs to completion
#TaskWorkloadElement: core.#CompositeTrait & {
	name:        "TaskWorkload"
	#apiVersion:  "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #TaskWorkloadSpec
	composes: [#ContainerElement, #RestartPolicyElement, #SidecarContainersElement, #InitContainersElement]
	workloadType: "task"
	description:  "A task workload that runs to completion"
	labels: {"core.opm.dev/category": "workload"}
}

#TaskWorkload: close(core.#ElementBase & {
	#elements: (#TaskWorkloadElement.#fullyQualifiedName): #TaskWorkloadElement
	task: #TaskWorkloadSpec
})

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

// ScheduledTask workload - A containerized workload that runs on a schedule
#ScheduledTaskWorkloadElement: core.#CompositeTrait & {
	name:        "ScheduledTaskWorkload"
	#apiVersion:  "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #ScheduledTaskWorkloadSpec
	composes: [#ContainerElement, #RestartPolicyElement, #SidecarContainersElement, #InitContainersElement]
	workloadType: "scheduled-task"
	description:  "A scheduled task workload that runs on a schedule"
	labels: {"core.opm.dev/category": "workload"}
}

#ScheduledTaskWorkload: close(core.#ElementBase & {
	#elements: (#ScheduledTaskWorkloadElement.#fullyQualifiedName): #ScheduledTaskWorkloadElement
	scheduledTask: #ScheduledTaskWorkloadSpec
})

#ScheduledTaskWorkloadSpec: {
	container:      #ContainerSpec
	restartPolicy?: #RestartPolicySpec
	sidecarContainers?: [#ContainerSpec]
	initContainers?: [#ContainerSpec]

	scheduleCron!:                   string // Cron format
	concurrencyPolicy?:          "Allow" | "Forbid" | "Replace" | *"Allow"
	startingDeadlineSeconds?:    int
	successfulJobsHistoryLimit?: int | *3
	failedJobsHistoryLimit?:     int | *1
}

#SimpleDatabaseElement: core.#CompositeTrait & {
	name:       "SimpleDatabase"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	target: ["component"]
	schema: #SimpleDatabaseSpec
	composes: [#StatefulWorkloadElement, #VolumeElement]
	workloadType: "stateful"
	description: "Composite trait to add a simple database to a component"
	labels: {"core.opm.dev/category": "data"}
}

#SimpleDatabase: close(core.#ElementBase & {
	#elements: (#SimpleDatabaseElement.#fullyQualifiedName): #SimpleDatabaseElement

	database: #SimpleDatabaseSpec

	stateful: #StatefulWorkloadSpec & {
		container: #ContainerSpec & {
			if database.engine == "postgres" {
				name:  "database"
				image: "postgres:latest"
				ports: {
					db: {
						targetPort: 5432
					}
				}
				env: {
					DB_NAME: {
						name:  "DB_NAME"
						value: database.dbName
					}
					DB_USER: {
						name:  "DB_USER"
						value: database.username
					}
					DB_PASSWORD: {
						name:  "DB_PASSWORD"
						value: database.password
					}
				}
				volumeMounts: {
					data: {
						name:      "data"
						mountPath: "/var/lib/postgresql/data"
					}
				}
			}
		}
		restartPolicy: #RestartPolicySpec & {
			policy: "Always"
		}
		updateStrategy: #UpdateStrategySpec & {
			type: "RollingUpdate"
		}
		healthCheck: #HealthCheckSpec & {
			liveness: {
				httpGet: {
					path:   "/healthz"
					port:   5432
					scheme: "HTTP"
				}
			}
		}
	}
})

#SimpleDatabaseSpec: {
	engine:   "postgres" | "mysql" | "mongodb" | "redis" | *"postgres"
	version:  string | *"latest"
	dbName:   string | *"appdb"
	username: string | *"admin"
	password: string | *"password"
	persistence: {
		enabled: bool | *true
		size:    string | *"1Gi"
	}
}
