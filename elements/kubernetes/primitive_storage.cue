package kubernetes

import (
	opm "github.com/open-platform-model/core"
)

// Storage API Group - elements.opm.dev/k8s/storage/v1

#StorageClassElement: opm.#Primitive & {
	name:        "StorageClass"
	#apiVersion: "elements.opm.dev/k8s/storage/v1"
	target: ["scope"]
	schema:      #StorageClassSpec
	description: "Kubernetes StorageClass - dynamic storage provisioning"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "storage"
	}
}

#StorageClass: close(opm.#Component & {
	#elements: (#StorageClassElement.#fullyQualifiedName): #StorageClassElement

	storageClasses: [string]: #StorageClassSpec
})

#VolumeAttachmentElement: opm.#Primitive & {
	name:        "VolumeAttachment"
	#apiVersion: "elements.opm.dev/k8s/storage/v1"
	target: ["component"]
	schema:      #VolumeAttachmentSpec
	description: "Kubernetes VolumeAttachment - volume to node binding"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "storage"
	}
}

#VolumeAttachment: close(opm.#Component & {
	#elements: (#VolumeAttachmentElement.#fullyQualifiedName): #VolumeAttachmentElement

	volumeAttachments: [string]: #VolumeAttachmentSpec
})

#CSIDriverElement: opm.#Primitive & {
	name:        "CSIDriver"
	#apiVersion: "elements.opm.dev/k8s/storage/v1"
	target: ["scope"]
	schema:      #CSIDriverSpec
	description: "Kubernetes CSIDriver - CSI driver specification"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "storage"
	}
}

#CSIDriver: close(opm.#Component & {
	#elements: (#CSIDriverElement.#fullyQualifiedName): #CSIDriverElement

	csiDrivers: [string]: #CSIDriverSpec
})

#CSINodeElement: opm.#Primitive & {
	name:        "CSINode"
	#apiVersion: "elements.opm.dev/k8s/storage/v1"
	target: ["component"]
	schema:      #CSINodeSpec
	description: "Kubernetes CSINode - CSI node information"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "storage"
	}
}

#CSINode: close(opm.#Component & {
	#elements: (#CSINodeElement.#fullyQualifiedName): #CSINodeElement

	csiNodes: [string]: #CSINodeSpec
})

#CSIStorageCapacityElement: opm.#Primitive & {
	name:        "CSIStorageCapacity"
	#apiVersion: "elements.opm.dev/k8s/storage/v1"
	target: ["scope"]
	schema:      #CSIStorageCapacitySpec
	description: "Kubernetes CSIStorageCapacity - storage capacity info"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "storage"
	}
}

#CSIStorageCapacity: close(opm.#Component & {
	#elements: (#CSIStorageCapacityElement.#fullyQualifiedName): #CSIStorageCapacityElement

	csiStorageCapacities: [string]: #CSIStorageCapacitySpec
})
