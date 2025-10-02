package kubernetes

import (
	opm "github.com/open-platform-model/core"
)

// Apps API Group - k8s.io/api/apps/v1

#DeploymentElement: opm.#Primitive & {
	name:        "Deployment"
	#apiVersion: "k8s.io/api/apps/v1"
	target: ["component"]
	schema:       #DeploymentSpec
	workloadType: "stateless"
	description:  "Kubernetes Deployment - stateless workload controller"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "apps"
	}
}

#StatefulSetElement: opm.#Primitive & {
	name:        "StatefulSet"
	#apiVersion: "k8s.io/api/apps/v1"
	target: ["component"]
	schema:       #StatefulSetSpec
	workloadType: "stateful"
	description:  "Kubernetes StatefulSet - stateful workload controller"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "apps"
	}
}

#DaemonSetElement: opm.#Primitive & {
	name:        "DaemonSet"
	#apiVersion: "k8s.io/api/apps/v1"
	target: ["component"]
	schema:       #DaemonSetSpec
	workloadType: "daemon"
	description:  "Kubernetes DaemonSet - node-level workload controller"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "apps"
	}
}

#ReplicaSetElement: opm.#Primitive & {
	name:        "ReplicaSet"
	#apiVersion: "k8s.io/api/apps/v1"
	target: ["component"]
	schema:       #ReplicaSetSpec
	workloadType: "stateless"
	description:  "Kubernetes ReplicaSet - maintains replica pods"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "apps"
	}
}

#ControllerRevisionElement: opm.#Primitive & {
	name:        "ControllerRevision"
	#apiVersion: "k8s.io/api/apps/v1"
	target: ["component"]
	schema:      #ControllerRevisionSpec
	description: "Kubernetes ControllerRevision - controller state snapshot"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "apps"
	}
}
