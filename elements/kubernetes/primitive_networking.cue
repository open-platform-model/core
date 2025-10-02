package kubernetes

import (
	opm "github.com/open-platform-model/core"
)

// Networking API Group - k8s.io/api/networking/v1

#IngressElement: opm.#Primitive & {
	name:        "Ingress"
	#apiVersion: "k8s.io/api/networking/v1"
	target: ["component"]
	schema:      #IngressSpec
	description: "Kubernetes Ingress - HTTP/HTTPS routing"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "networking"
	}
}

#IngressClassElement: opm.#Primitive & {
	name:        "IngressClass"
	#apiVersion: "k8s.io/api/networking/v1"
	target: ["scope"]
	schema:      #IngressClassSpec
	description: "Kubernetes IngressClass - ingress controller selector"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "networking"
	}
}

#NetworkPolicyElement: opm.#Primitive & {
	name:        "NetworkPolicy"
	#apiVersion: "k8s.io/api/networking/v1"
	target: ["scope"]
	schema:      #NetworkPolicySpec
	description: "Kubernetes NetworkPolicy - network access control"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "networking"
	}
}
