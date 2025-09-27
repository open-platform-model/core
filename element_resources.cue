package core

/////////////////////////////////////////////////////////////////
//// Resource catalog
/////////////////////////////////////////////////////////////////
// Categories for traits and resources
//
// workload - workload-related (e.g., container, scaling, networking)
// data - data-related (e.g., configmap, secret, volume)
// connectivity - connectivity-related (e.g., service, ingress, api)
// security - security-related (e.g., network policy, pod security)
// observability - observability-related (e.g., logging, monitoring, alerting)
// governance - governance-related (e.g., resource quota, priority, compliance)

// Volumes as Resources (claims, ephemeral, projected)
#VolumeElement: {
	Volume: #PrimitiveResource & {
		description: "A set of volume types for data storage and sharing"
		target: ["component"]
		labels: {"core.opm.dev/category": "data"}
		#schema: #VolumeSpec
	}
}

#Volume: #ElementBase & {
	#elements: #VolumeElement

	volumes: [string]: #VolumeSpec
}

#VolumeMountSpec: #VolumeSpec & {
	mountPath!: string
	subPath?:   string
	readOnly?:  bool | *false
}

#VolumeSpec: {
	emptyDir?: {
		medium?:    *"node" | "memory"
		sizeLimit?: string
	}
	persistentClaim?: #PersistentClaimSpec
	configMap?:       #ConfigMapSpec
	secret?:          #SecretSpec
	...
}

#PersistentClaimSpec: {
	size:          string | *"1Gi"
	accessMode:    "ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany" | *"ReadWriteOnce"
	storageClass?: string | *"standard"
}

// ConfigMaps as Resources
#ConfigMapElement: {
	ConfigMap: #PrimitiveResource & {
		name:        "ConfigMap"
		description: "Key-value pairs for configuration data"
		target: ["component"]
		labels: {"core.opm.dev/category": "data"}
		#schema: #ConfigMapSpec
	}
}

#ConfigMap: #ElementBase & {
	#elements: #ConfigMapElement

	configMaps: [string]: #ConfigMapSpec
}

#ConfigMapSpec: {
	data: [string]: string
}

// Secrets as Resources
#SecretElement: {
	Secret: #PrimitiveResource & {
		name:        "Secret"
		description: "Sensitive data such as passwords, tokens, or keys"
		target: ["component"]
		labels: {"core.opm.dev/category": "data"}
		#schema: #SecretSpec
	}
}

#Secret: #ElementBase & {
	#elements: #SecretElement

	secrets: [string]: #SecretSpec
}

#SecretSpec: {
	type?: string | *"Opaque"
	data: [string]: string // Base64-encoded values
}
