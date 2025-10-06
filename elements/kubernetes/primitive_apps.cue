package kubernetes

import (
	opm "github.com/open-platform-model/core"
)

// Apps API Group - elements.opm.dev/k8s/apps/v1

#DeploymentElement: opm.#Primitive & {
	name:        "Deployment"
	#apiVersion: "elements.opm.dev/k8s/apps/v1"
	target: ["component"]
	schema: #DeploymentSpec
	annotations: {
		"core.opm.dev/workload-type": "stateless"
	}
	description: "Kubernetes Deployment - stateless workload controller"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "apps"
	}
}

#Deployment: close(opm.#Component & {
	#elements: (#DeploymentElement.#fullyQualifiedName): #DeploymentElement

	deployments: [string]: #DeploymentSpec
})

#StatefulSetElement: opm.#Primitive & {
	name:        "StatefulSet"
	#apiVersion: "elements.opm.dev/k8s/apps/v1"
	target: ["component"]
	schema: #StatefulSetSpec
	annotations: {
		"core.opm.dev/workload-type": "stateful"
	}
	description: "Kubernetes StatefulSet - stateful workload controller"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "apps"
	}
}

#StatefulSet: close(opm.#Component & {
	#elements: (#StatefulSetElement.#fullyQualifiedName): #StatefulSetElement

	statefulSets: [string]: #StatefulSetSpec
})

#DaemonSetElement: opm.#Primitive & {
	name:        "DaemonSet"
	#apiVersion: "elements.opm.dev/k8s/apps/v1"
	target: ["component"]
	schema: #DaemonSetSpec
	annotations: {
		"core.opm.dev/workload-type": "daemon"
	}
	description: "Kubernetes DaemonSet - node-level workload controller"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "apps"
	}
}

#DaemonSet: close(opm.#Component & {
	#elements: (#DaemonSetElement.#fullyQualifiedName): #DaemonSetElement

	daemonSets: [string]: #DaemonSetSpec
})

#ReplicaSetElement: opm.#Primitive & {
	name:        "ReplicaSet"
	#apiVersion: "elements.opm.dev/k8s/apps/v1"
	target: ["component"]
	schema: #ReplicaSetSpec
	annotations: {
		"core.opm.dev/workload-type": "stateless"
	}
	description: "Kubernetes ReplicaSet - maintains replica pods"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "apps"
	}
}

#ReplicaSet: close(opm.#Component & {
	#elements: (#ReplicaSetElement.#fullyQualifiedName): #ReplicaSetElement

	replicaSets: [string]: #ReplicaSetSpec
})

#ControllerRevisionElement: opm.#Primitive & {
	name:        "ControllerRevision"
	#apiVersion: "elements.opm.dev/k8s/apps/v1"
	target: ["component"]
	schema:      #ControllerRevisionSpec
	description: "Kubernetes ControllerRevision - controller state snapshot"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "apps"
	}
}

#ControllerRevision: close(opm.#Component & {
	#elements: (#ControllerRevisionElement.#fullyQualifiedName): #ControllerRevisionElement

	controllerRevisions: [string]: #ControllerRevisionSpec
})
