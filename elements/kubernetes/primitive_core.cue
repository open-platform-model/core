package kubernetes

import (
	opm "github.com/open-platform-model/core"
)

// Core API Group - elements.opm.dev/k8s/core/v1

#PodElement: opm.#Primitive & {
	name:        "Pod"
	#apiVersion: "elements.opm.dev/k8s/core/v1"
	target: ["component"]
	schema:      #PodSpec
	description: "Kubernetes Pod - smallest deployable unit"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "core"
	}
}

#ServiceElement: opm.#Primitive & {
	name:        "Service"
	#apiVersion: "elements.opm.dev/k8s/core/v1"
	target: ["component"]
	schema:      #ServiceSpec
	description: "Kubernetes Service - network service abstraction"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "core"
	}
}

#PersistentVolumeClaimElement: opm.#Primitive & {
	name:        "PersistentVolumeClaim"
	#apiVersion: "elements.opm.dev/k8s/core/v1"
	target: ["component"]
	schema:      #PersistentVolumeClaimSpec
	description: "Kubernetes PersistentVolumeClaim - storage request"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "core"
	}
}

#ConfigMapElement: opm.#Primitive & {
	name:        "ConfigMap"
	#apiVersion: "elements.opm.dev/k8s/core/v1"
	target: ["component"]
	schema:      #ConfigMapSpec
	description: "Kubernetes ConfigMap - configuration data"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "core"
	}
}

#SecretElement: opm.#Primitive & {
	name:        "Secret"
	#apiVersion: "elements.opm.dev/k8s/core/v1"
	target: ["component"]
	schema:      #SecretSpec
	description: "Kubernetes Secret - sensitive data"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "core"
	}
}

#ServiceAccountElement: opm.#Primitive & {
	name:        "ServiceAccount"
	#apiVersion: "elements.opm.dev/k8s/core/v1"
	target: ["component"]
	schema:      #ServiceAccountSpec
	description: "Kubernetes ServiceAccount - pod identity"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "core"
	}
}

#NamespaceElement: opm.#Primitive & {
	name:        "Namespace"
	#apiVersion: "elements.opm.dev/k8s/core/v1"
	target: ["scope"]
	schema:      #NamespaceSpec
	description: "Kubernetes Namespace - resource isolation"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "core"
	}
}

#NodeElement: opm.#Primitive & {
	name:        "Node"
	#apiVersion: "elements.opm.dev/k8s/core/v1"
	target: ["component"]
	schema:      #NodeSpec
	description: "Kubernetes Node - cluster worker machine"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "core"
	}
}

#EndpointsElement: opm.#Primitive & {
	name:        "Endpoints"
	#apiVersion: "elements.opm.dev/k8s/core/v1"
	target: ["component"]
	schema:      #EndpointsSpec
	description: "Kubernetes Endpoints - service backend addresses"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "core"
	}
}

#EventElement: opm.#Primitive & {
	name:        "Event"
	#apiVersion: "elements.opm.dev/k8s/core/v1"
	target: ["component"]
	schema:      #EventSpec
	description: "Kubernetes Event - cluster event record"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "core"
	}
}

#LimitRangeElement: opm.#Primitive & {
	name:        "LimitRange"
	#apiVersion: "elements.opm.dev/k8s/core/v1"
	target: ["scope"]
	schema:      #LimitRangeSpec
	description: "Kubernetes LimitRange - resource limit constraints"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "core"
	}
}

#ResourceQuotaElement: opm.#Primitive & {
	name:        "ResourceQuota"
	#apiVersion: "elements.opm.dev/k8s/core/v1"
	target: ["scope"]
	schema:      #ResourceQuotaSpec
	description: "Kubernetes ResourceQuota - namespace resource limits"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "core"
	}
}
