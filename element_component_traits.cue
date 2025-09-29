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
	// Primitive Traits
	(#ContainerElement.#fullyQualifiedName): #ContainerElement
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

// Container - Defines a container within a workload
#ContainerElement: #PrimitiveTrait & {
	#name:       "Container"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "A container definition for workloads"
	// Only allow workloadType to be one of the supported types
	workloadType: "stateless" | "stateful" | "daemonSet" | "task" | "scheduled-task"
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
	ports?: [PortName=string]: #PortSpec & {name: PortName}
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
#SidecarContainersElement: #ModifierTrait & {
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
#InitContainersElement: #ModifierTrait & {
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
#EphemeralContainersElement: #ModifierTrait & {
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
#ReplicasElement: #ModifierTrait & {
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
#RestartPolicyElement: #ModifierTrait & {
	#name:       "RestartPolicy"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "Restart policy for all containers within the component"
	target: ["component"]
	labels: {"core.opm.dev/category": "workload"}
	#schema: #RestartPolicySpec
}

#RestartPolicy: close(#ElementBase & {
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
#UpdateStrategyElement: #ModifierTrait & {
	#name:       "UpdateStrategy"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "Update strategy for the component"
	target: ["component"]
	labels: {"core.opm.dev/category": "workload"}
	#schema: #UpdateStrategySpec
}

#UpdateStrategy: close(#ElementBase & {
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
#HealthCheckElement: #ModifierTrait & {
	#name:       "HealthCheck"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "Liveness and readiness probes for the main container"
	target: ["component"]
	labels: {"core.opm.dev/category": "workload"}
	#schema: #HealthCheckSpec
}

#HealthCheck: close(#ElementBase & {
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
#ExposeElement: #ModifierTrait & {
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

/////////////////////////////////////////////////////////////////
//// Composite Traits
/////////////////////////////////////////////////////////////////

// Sateless workload - A horizontally scalable containerized workload with no requirement for stable identity or storage
#StatelessWorkloadElement: #CompositeTrait & {
	#name:        "StatelessWorkload"
	#apiVersion:  "elements.opm.dev/core/v1alpha1"
	description:  "A stateless workload with no requirement for stable identity or storage"
	workloadType: "stateless"
	target: ["component"]
	composes: [#ContainerElement, #ReplicasElement, #RestartPolicyElement, #UpdateStrategyElement, #HealthCheckElement, #SidecarContainersElement, #InitContainersElement]
	labels: {"core.opm.dev/category": "workload"}
	#schema: #StatelessSpec
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

#StatelessWorkload: close(#ElementBase & {
	#elements: (#StatelessWorkloadElement.#fullyQualifiedName): #StatelessWorkloadElement
	stateless: #StatelessSpec
})

// Stateful workload - A containerized workload that requires stable identity and storage
#StatefulWorkloadElement: #CompositeTrait & {
	#name:        "StatefulWorkload"
	#apiVersion:  "elements.opm.dev/core/v1alpha1"
	description:  "A stateful workload that requires stable identity and storage"
	workloadType: "stateful"
	target: ["component"]
	composes: [#ContainerElement, #ReplicasElement, #RestartPolicyElement, #UpdateStrategyElement, #HealthCheckElement, #SidecarContainersElement, #InitContainersElement, #VolumeElement]
	labels: {"core.opm.dev/category": "workload"}
	#schema: #StatefulWorkloadSpec
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

#StatefulWorkload: close(#ElementBase & {
	#elements: (#StatefulWorkloadElement.#fullyQualifiedName): #StatefulWorkloadElement
	stateful: #StatefulWorkloadSpec
})

// DaemonSet workload - A containerized workload that runs on all (or some) nodes in the cluster
#DaemonSetWorkloadElement: #CompositeTrait & {
	#name:        "DaemonSetWorkload"
	#apiVersion:  "elements.opm.dev/core/v1alpha1"
	description:  "A daemonSet workload that runs on all (or some) nodes in the cluster"
	workloadType: "daemonSet"
	target: ["component"]
	composes: [#ContainerElement, #RestartPolicyElement, #UpdateStrategyElement, #HealthCheckElement, #SidecarContainersElement, #InitContainersElement]
	labels: {"core.opm.dev/category": "workload"}
	#schema: #DaemonSetSpec
}

#DaemonSetWorkload: close(#ElementBase & {
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
#TaskWorkloadElement: #CompositeTrait & {
	#name:        "TaskWorkload"
	#apiVersion:  "elements.opm.dev/core/v1alpha1"
	description:  "A task workload that runs to completion"
	workloadType: "task"
	target: ["component"]
	composes: [#ContainerElement, #RestartPolicyElement, #SidecarContainersElement, #InitContainersElement]
	labels: {"core.opm.dev/category": "workload"}
	#schema: #TaskWorkloadSpec
}

#TaskWorkload: close(#ElementBase & {
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
#ScheduledTaskWorkloadElement: #CompositeTrait & {
	#name:        "ScheduledTaskWorkload"
	#apiVersion:  "elements.opm.dev/core/v1alpha1"
	description:  "A scheduled task workload that runs on a schedule"
	workloadType: "scheduled-task"
	target: ["component"]
	composes: [#ContainerElement, #RestartPolicyElement, #SidecarContainersElement, #InitContainersElement]
	labels: {"core.opm.dev/category": "workload"}
	#schema: #ScheduledTaskWorkloadSpec
}

#ScheduledTaskWorkload: close(#ElementBase & {
	#elements: (#ScheduledTaskWorkloadElement.#fullyQualifiedName): #ScheduledTaskWorkloadElement
	scheduledTask: #ScheduledTaskWorkloadSpec
})

#ScheduledTaskWorkloadSpec: {
	container:      #ContainerSpec
	restartPolicy?: #RestartPolicySpec
	sidecarContainers?: [#ContainerSpec]
	initContainers?: [#ContainerSpec]

	schedule!:                   string // Cron format
	concurrencyPolicy?:          "Allow" | "Forbid" | "Replace" | *"Allow"
	startingDeadlineSeconds?:    int
	successfulJobsHistoryLimit?: int | *3
	failedJobsHistoryLimit?:     int | *1
}

#SimpleDatabaseElement: #CompositeTrait & {
	#name:       "SimpleDatabase"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "Composite trait to add a simple database to a component"
	target: ["component"]
	labels: {"core.opm.dev/category": "data"}
	composes: [#StatefulWorkloadElement, #VolumeElement]
	#schema: #SimpleDatabaseSpec
}

#SimpleDatabase: close(#ElementBase & {
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
			liveness: #ProbeSpec & {
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
