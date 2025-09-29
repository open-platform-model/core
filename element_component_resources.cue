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

#CoreElementRegistry: {
	(#VolumeElement.#fullyQualifiedName):    #VolumeElement
	(#ConfigMapElement.#fullyQualifiedName): #ConfigMapElement
	(#SecretElement.#fullyQualifiedName):    #SecretElement
}

// Volumes as Resources (claims, ephemeral, projected)
#VolumeElement: #PrimitiveResource & {
	#name:       "Volume"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "A set of volume types for data storage and sharing"
	target: ["component"]
	labels: {"core.opm.dev/category": "data"}
	#schema: #VolumeSpec
}

#Volume: close(#ElementBase & {
	#elements: (#VolumeElement.#fullyQualifiedName): #VolumeElement

	volumes: [string]: #VolumeSpec
})

#VolumeMountSpec: close(#VolumeSpec & {
	mountPath!: string
	subPath?:   string
	readOnly?:  bool | *false
})

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
	size:          string
	accessMode:    "ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany" | *"ReadWriteOnce"
	storageClass?: string | *"standard"
}

// ConfigMaps as Resources
#ConfigMapElement: #PrimitiveResource & {
	#name:       "ConfigMap"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "Key-value pairs for configuration data"
	target: ["component"]
	labels: {"core.opm.dev/category": "data"}
	#schema: #ConfigMapSpec
}

#ConfigMap: close(#ElementBase & {
	#elements: (#ConfigMapElement.#fullyQualifiedName): #ConfigMapElement

	configMaps: [string]: #ConfigMapSpec
})

#ConfigMapSpec: {
	data: [string]: string
}

// Secrets as Resources
#SecretElement: #PrimitiveResource & {
	#name:       "Secret"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "Sensitive data such as passwords, tokens, or keys"
	target: ["component"]
	labels: {"core.opm.dev/category": "data"}
	#schema: #SecretSpec
}

#Secret: close(#ElementBase & {
	#elements: (#SecretElement.#fullyQualifiedName): #SecretElement

	secrets: [string]: #SecretSpec
})

#SecretSpec: {
	type?: string | *"Opaque"
	data: [string]: string // Base64-encoded values
}
