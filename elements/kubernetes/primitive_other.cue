package kubernetes

import (
	opm "github.com/open-platform-model/core"
)

// Policy API Group - k8s.io/api/policy/v1

#PodDisruptionBudgetElement: opm.#Primitive & {
	name:        "PodDisruptionBudget"
	#apiVersion: "k8s.io/api/policy/v1"
	target: ["component"]
	schema:      #PodDisruptionBudgetSpec
	description: "Kubernetes PodDisruptionBudget - availability guarantees"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "policy"
	}
}

// Autoscaling API Group - k8s.io/api/autoscaling/v2

#HorizontalPodAutoscalerElement: opm.#Primitive & {
	name:        "HorizontalPodAutoscaler"
	#apiVersion: "k8s.io/api/autoscaling/v2"
	target: ["component"]
	schema:      #HorizontalPodAutoscalerSpec
	description: "Kubernetes HorizontalPodAutoscaler - automatic scaling"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "autoscaling"
	}
}

// Certificates API Group - k8s.io/api/certificates/v1

#CertificateSigningRequestElement: opm.#Primitive & {
	name:        "CertificateSigningRequest"
	#apiVersion: "k8s.io/api/certificates/v1"
	target: ["component"]
	schema:      #CertificateSigningRequestSpec
	description: "Kubernetes CertificateSigningRequest - certificate request"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "certificates"
	}
}

// Coordination API Group - k8s.io/api/coordination/v1

#LeaseElement: opm.#Primitive & {
	name:        "Lease"
	#apiVersion: "k8s.io/api/coordination/v1"
	target: ["component"]
	schema:      #LeaseSpec
	description: "Kubernetes Lease - distributed locking"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "coordination"
	}
}

// Discovery API Group - k8s.io/api/discovery/v1

#EndpointSliceElement: opm.#Primitive & {
	name:        "EndpointSlice"
	#apiVersion: "k8s.io/api/discovery/v1"
	target: ["component"]
	schema:      #EndpointSliceSpec
	description: "Kubernetes EndpointSlice - scalable service endpoints"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "discovery"
	}
}

// Events API Group - k8s.io/api/events/v1

#EventV1Element: opm.#Primitive & {
	name:        "Event"
	#apiVersion: "k8s.io/api/events/v1"
	target: ["component"]
	schema:      #EventV1Spec
	description: "Kubernetes Event (v1) - structured event record"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "events"
	}
}

// Node API Group - k8s.io/api/node/v1

#RuntimeClassElement: opm.#Primitive & {
	name:        "RuntimeClass"
	#apiVersion: "k8s.io/api/node/v1"
	target: ["scope"]
	schema:      #RuntimeClassSpec
	description: "Kubernetes RuntimeClass - container runtime selection"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "node"
	}
}

// Admission Registration API Group - k8s.io/api/admissionregistration/v1

#MutatingWebhookConfigurationElement: opm.#Primitive & {
	name:        "MutatingWebhookConfiguration"
	#apiVersion: "k8s.io/api/admissionregistration/v1"
	target: ["scope"]
	schema:      #MutatingWebhookConfigurationSpec
	description: "Kubernetes MutatingWebhookConfiguration - admission webhook"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "admissionregistration"
	}
}

#ValidatingWebhookConfigurationElement: opm.#Primitive & {
	name:        "ValidatingWebhookConfiguration"
	#apiVersion: "k8s.io/api/admissionregistration/v1"
	target: ["scope"]
	schema:      #ValidatingWebhookConfigurationSpec
	description: "Kubernetes ValidatingWebhookConfiguration - validation webhook"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "admissionregistration"
	}
}

#ValidatingAdmissionPolicyElement: opm.#Primitive & {
	name:        "ValidatingAdmissionPolicy"
	#apiVersion: "k8s.io/api/admissionregistration/v1"
	target: ["scope"]
	schema:      #ValidatingAdmissionPolicySpec
	description: "Kubernetes ValidatingAdmissionPolicy - CEL-based validation"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "admissionregistration"
	}
}

#ValidatingAdmissionPolicyBindingElement: opm.#Primitive & {
	name:        "ValidatingAdmissionPolicyBinding"
	#apiVersion: "k8s.io/api/admissionregistration/v1"
	target: ["scope"]
	schema:      #ValidatingAdmissionPolicyBindingSpec
	description: "Kubernetes ValidatingAdmissionPolicyBinding - policy binding"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "admissionregistration"
	}
}

// API Extensions - k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1

#CustomResourceDefinitionElement: opm.#Primitive & {
	name:        "CustomResourceDefinition"
	#apiVersion: "k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1"
	target: ["scope"]
	schema:      #CustomResourceDefinitionSpec
	description: "Kubernetes CustomResourceDefinition - API extension"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "apiextensions"
	}
}

// Flow Control API Group - k8s.io/api/flowcontrol/v1

#FlowSchemaElement: opm.#Primitive & {
	name:        "FlowSchema"
	#apiVersion: "k8s.io/api/flowcontrol/v1"
	target: ["scope"]
	schema:      #FlowSchemaSpec
	description: "Kubernetes FlowSchema - API priority and fairness"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "flowcontrol"
	}
}

#PriorityLevelConfigurationElement: opm.#Primitive & {
	name:        "PriorityLevelConfiguration"
	#apiVersion: "k8s.io/api/flowcontrol/v1"
	target: ["scope"]
	schema:      #PriorityLevelConfigurationSpec
	description: "Kubernetes PriorityLevelConfiguration - request priority levels"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "flowcontrol"
	}
}

// Scheduling API Group - k8s.io/api/scheduling/v1

#PriorityClassElement: opm.#Primitive & {
	name:        "PriorityClass"
	#apiVersion: "k8s.io/api/scheduling/v1"
	target: ["scope"]
	schema:      #PriorityClassSpec
	description: "Kubernetes PriorityClass - pod scheduling priority"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "scheduling"
	}
}
