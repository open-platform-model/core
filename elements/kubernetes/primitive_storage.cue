package kubernetes

import (
	opm "github.com/open-platform-model/core"
)

// Storage API Group - k8s.io/api/storage/v1

#StorageClassElement: opm.#Primitive & {
	name:        "StorageClass"
	#apiVersion: "k8s.io/api/storage/v1"
	target: ["scope"]
	schema:      #StorageClassSpec
	description: "Kubernetes StorageClass - dynamic storage provisioning"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "storage"
	}
}

#VolumeAttachmentElement: opm.#Primitive & {
	name:        "VolumeAttachment"
	#apiVersion: "k8s.io/api/storage/v1"
	target: ["component"]
	schema:      #VolumeAttachmentSpec
	description: "Kubernetes VolumeAttachment - volume to node binding"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "storage"
	}
}

#CSIDriverElement: opm.#Primitive & {
	name:        "CSIDriver"
	#apiVersion: "k8s.io/api/storage/v1"
	target: ["scope"]
	schema:      #CSIDriverSpec
	description: "Kubernetes CSIDriver - CSI driver specification"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "storage"
	}
}

#CSINodeElement: opm.#Primitive & {
	name:        "CSINode"
	#apiVersion: "k8s.io/api/storage/v1"
	target: ["component"]
	schema:      #CSINodeSpec
	description: "Kubernetes CSINode - CSI node information"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "storage"
	}
}

#CSIStorageCapacityElement: opm.#Primitive & {
	name:        "CSIStorageCapacity"
	#apiVersion: "k8s.io/api/storage/v1"
	target: ["scope"]
	schema:      #CSIStorageCapacitySpec
	description: "Kubernetes CSIStorageCapacity - storage capacity info"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "storage"
	}
}
