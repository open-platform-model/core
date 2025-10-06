package kubernetes

import (
	opm "github.com/open-platform-model/core"
)

// Policy API Group - elements.opm.dev/k8s/policy/v1

#PodDisruptionBudgetElement: opm.#Primitive & {
	name:        "PodDisruptionBudget"
	#apiVersion: "elements.opm.dev/k8s/policy/v1"
	target: ["component"]
	schema:      #PodDisruptionBudgetSpec
	description: "Kubernetes PodDisruptionBudget - availability guarantees"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "policy"
	}
}

#PodDisruptionBudget: close(opm.#Component & {
	#elements: (#PodDisruptionBudgetElement.#fullyQualifiedName): #PodDisruptionBudgetElement

	podDisruptionBudgets: [string]: #PodDisruptionBudgetSpec
})

// Autoscaling API Group - elements.opm.dev/k8s/autoscaling/v2

#HorizontalPodAutoscalerElement: opm.#Primitive & {
	name:        "HorizontalPodAutoscaler"
	#apiVersion: "elements.opm.dev/k8s/autoscaling/v2"
	target: ["component"]
	schema:      #HorizontalPodAutoscalerSpec
	description: "Kubernetes HorizontalPodAutoscaler - automatic scaling"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "autoscaling"
	}
}

#HorizontalPodAutoscaler: close(opm.#Component & {
	#elements: (#HorizontalPodAutoscalerElement.#fullyQualifiedName): #HorizontalPodAutoscalerElement

	horizontalPodAutoscalers: [string]: #HorizontalPodAutoscalerSpec
})

// Certificates API Group - elements.opm.dev/k8s/certificates/v1

#CertificateSigningRequestElement: opm.#Primitive & {
	name:        "CertificateSigningRequest"
	#apiVersion: "elements.opm.dev/k8s/certificates/v1"
	target: ["component"]
	schema:      #CertificateSigningRequestSpec
	description: "Kubernetes CertificateSigningRequest - certificate request"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "certificates"
	}
}

#CertificateSigningRequest: close(opm.#Component & {
	#elements: (#CertificateSigningRequestElement.#fullyQualifiedName): #CertificateSigningRequestElement

	certificateSigningRequests: [string]: #CertificateSigningRequestSpec
})

// Coordination API Group - elements.opm.dev/k8s/coordination/v1

#LeaseElement: opm.#Primitive & {
	name:        "Lease"
	#apiVersion: "elements.opm.dev/k8s/coordination/v1"
	target: ["component"]
	schema:      #LeaseSpec
	description: "Kubernetes Lease - distributed locking"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "coordination"
	}
}

#Lease: close(opm.#Component & {
	#elements: (#LeaseElement.#fullyQualifiedName): #LeaseElement

	leases: [string]: #LeaseSpec
})

// Discovery API Group - elements.opm.dev/k8s/discovery/v1

#EndpointSliceElement: opm.#Primitive & {
	name:        "EndpointSlice"
	#apiVersion: "elements.opm.dev/k8s/discovery/v1"
	target: ["component"]
	schema:      #EndpointSliceSpec
	description: "Kubernetes EndpointSlice - scalable service endpoints"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "discovery"
	}
}

#EndpointSlice: close(opm.#Component & {
	#elements: (#EndpointSliceElement.#fullyQualifiedName): #EndpointSliceElement

	endpointSlices: [string]: #EndpointSliceSpec
})

// Events API Group - elements.opm.dev/k8s/events/v1

#EventV1Element: opm.#Primitive & {
	name:        "Event"
	#apiVersion: "elements.opm.dev/k8s/events/v1"
	target: ["component"]
	schema:      #EventV1Spec
	description: "Kubernetes Event (v1) - structured event record"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "events"
	}
}

#EventV1: close(opm.#Component & {
	#elements: (#EventV1Element.#fullyQualifiedName): #EventV1Element

	eventsV1: [string]: #EventV1Spec
})

// Node API Group - elements.opm.dev/k8s/node/v1

#RuntimeClassElement: opm.#Primitive & {
	name:        "RuntimeClass"
	#apiVersion: "elements.opm.dev/k8s/node/v1"
	target: ["scope"]
	schema:      #RuntimeClassSpec
	description: "Kubernetes RuntimeClass - container runtime selection"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "node"
	}
}

#RuntimeClass: close(opm.#Component & {
	#elements: (#RuntimeClassElement.#fullyQualifiedName): #RuntimeClassElement

	runtimeClasses: [string]: #RuntimeClassSpec
})

// Admission Registration API Group - elements.opm.dev/k8s/admissionregistration/v1

#MutatingWebhookConfigurationElement: opm.#Primitive & {
	name:        "MutatingWebhookConfiguration"
	#apiVersion: "elements.opm.dev/k8s/admissionregistration/v1"
	target: ["scope"]
	schema:      #MutatingWebhookConfigurationSpec
	description: "Kubernetes MutatingWebhookConfiguration - admission webhook"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "admissionregistration"
	}
}

#MutatingWebhookConfiguration: close(opm.#Component & {
	#elements: (#MutatingWebhookConfigurationElement.#fullyQualifiedName): #MutatingWebhookConfigurationElement

	mutatingWebhookConfigurations: [string]: #MutatingWebhookConfigurationSpec
})

#ValidatingWebhookConfigurationElement: opm.#Primitive & {
	name:        "ValidatingWebhookConfiguration"
	#apiVersion: "elements.opm.dev/k8s/admissionregistration/v1"
	target: ["scope"]
	schema:      #ValidatingWebhookConfigurationSpec
	description: "Kubernetes ValidatingWebhookConfiguration - validation webhook"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "admissionregistration"
	}
}

#ValidatingWebhookConfiguration: close(opm.#Component & {
	#elements: (#ValidatingWebhookConfigurationElement.#fullyQualifiedName): #ValidatingWebhookConfigurationElement

	validatingWebhookConfigurations: [string]: #ValidatingWebhookConfigurationSpec
})

#ValidatingAdmissionPolicyElement: opm.#Primitive & {
	name:        "ValidatingAdmissionPolicy"
	#apiVersion: "elements.opm.dev/k8s/admissionregistration/v1"
	target: ["scope"]
	schema:      #ValidatingAdmissionPolicySpec
	description: "Kubernetes ValidatingAdmissionPolicy - CEL-based validation"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "admissionregistration"
	}
}

#ValidatingAdmissionPolicy: close(opm.#Component & {
	#elements: (#ValidatingAdmissionPolicyElement.#fullyQualifiedName): #ValidatingAdmissionPolicyElement

	validatingAdmissionPolicies: [string]: #ValidatingAdmissionPolicySpec
})

#ValidatingAdmissionPolicyBindingElement: opm.#Primitive & {
	name:        "ValidatingAdmissionPolicyBinding"
	#apiVersion: "elements.opm.dev/k8s/admissionregistration/v1"
	target: ["scope"]
	schema:      #ValidatingAdmissionPolicyBindingSpec
	description: "Kubernetes ValidatingAdmissionPolicyBinding - policy binding"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "admissionregistration"
	}
}

#ValidatingAdmissionPolicyBinding: close(opm.#Component & {
	#elements: (#ValidatingAdmissionPolicyBindingElement.#fullyQualifiedName): #ValidatingAdmissionPolicyBindingElement

	validatingAdmissionPolicyBindings: [string]: #ValidatingAdmissionPolicyBindingSpec
})

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

#CustomResourceDefinition: close(opm.#Component & {
	#elements: (#CustomResourceDefinitionElement.#fullyQualifiedName): #CustomResourceDefinitionElement

	customResourceDefinitions: [string]: #CustomResourceDefinitionSpec
})

// Flow Control API Group - elements.opm.dev/k8s/flowcontrol/v1

#FlowSchemaElement: opm.#Primitive & {
	name:        "FlowSchema"
	#apiVersion: "elements.opm.dev/k8s/flowcontrol/v1"
	target: ["scope"]
	schema:      #FlowSchemaSpec
	description: "Kubernetes FlowSchema - API priority and fairness"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "flowcontrol"
	}
}

#FlowSchema: close(opm.#Component & {
	#elements: (#FlowSchemaElement.#fullyQualifiedName): #FlowSchemaElement

	flowSchemas: [string]: #FlowSchemaSpec
})

#PriorityLevelConfigurationElement: opm.#Primitive & {
	name:        "PriorityLevelConfiguration"
	#apiVersion: "elements.opm.dev/k8s/flowcontrol/v1"
	target: ["scope"]
	schema:      #PriorityLevelConfigurationSpec
	description: "Kubernetes PriorityLevelConfiguration - request priority levels"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "flowcontrol"
	}
}

#PriorityLevelConfiguration: close(opm.#Component & {
	#elements: (#PriorityLevelConfigurationElement.#fullyQualifiedName): #PriorityLevelConfigurationElement

	priorityLevelConfigurations: [string]: #PriorityLevelConfigurationSpec
})

// Scheduling API Group - elements.opm.dev/k8s/scheduling/v1

#PriorityClassElement: opm.#Primitive & {
	name:        "PriorityClass"
	#apiVersion: "elements.opm.dev/k8s/scheduling/v1"
	target: ["scope"]
	schema:      #PriorityClassSpec
	description: "Kubernetes PriorityClass - pod scheduling priority"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "scheduling"
	}
}

#PriorityClass: close(opm.#Component & {
	#elements: (#PriorityClassElement.#fullyQualifiedName): #PriorityClassElement

	priorityClasses: [string]: #PriorityClassSpec
})
