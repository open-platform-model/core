package elements

import (
	core "github.com/open-platform-model/core/elements/core"
	k8s "github.com/open-platform-model/core/elements/kubernetes"
)

/////////////////////////////////////////////////////////////////
//// Element Index & Registry
/////////////////////////////////////////////////////////////////
//
// This file serves as the main entry point for all elements.
// Import this package to access all element definitions:
//
//   import elements "github.com/open-platform-model/core/elements"
//
// All element definitions from subdirectories are re-exported here.
//
// Elements are organized by category and kind:
//   - primitive_{name}.cue: Basic building blocks
//   - modifier_{name}.cue: Elements that modify other elements
//   - composite_{name}.cue: Compositions of multiple elements
//
/////////////////////////////////////////////////////////////////

// Categories for traits and resources
//
// workload - workload-related (e.g., container, scaling, networking)
// data - data-related (e.g., configmap, secret, volume)
// connectivity - connectivity-related (e.g., service, ingress, api)
// security - security-related (e.g., network policy, pod security)
// observability - observability-related (e.g., logging, monitoring, alerting)
// governance - governance-related (e.g., resource quota, priority, compliance)

/////////////////////////////////////////////////////////////////
//// Core Element Registry
/////////////////////////////////////////////////////////////////

#CoreElementRegistry: {
	// Workload - Primitive Traits
	(core.#ContainerElement.#fullyQualifiedName): core.#ContainerElement

	// Workload - Modifier Traits
	(core.#SidecarContainersElement.#fullyQualifiedName):   core.#SidecarContainersElement
	(core.#InitContainersElement.#fullyQualifiedName):      core.#InitContainersElement
	(core.#EphemeralContainersElement.#fullyQualifiedName): core.#EphemeralContainersElement
	(core.#ReplicasElement.#fullyQualifiedName):            core.#ReplicasElement
	(core.#RestartPolicyElement.#fullyQualifiedName):       core.#RestartPolicyElement
	(core.#UpdateStrategyElement.#fullyQualifiedName):      core.#UpdateStrategyElement
	(core.#HealthCheckElement.#fullyQualifiedName):         core.#HealthCheckElement

	// Workload - Composite Traits
	(core.#StatelessWorkloadElement.#fullyQualifiedName):     core.#StatelessWorkloadElement
	(core.#StatefulWorkloadElement.#fullyQualifiedName):      core.#StatefulWorkloadElement
	(core.#DaemonWorkloadElement.#fullyQualifiedName):        core.#DaemonWorkloadElement
	(core.#TaskWorkloadElement.#fullyQualifiedName):          core.#TaskWorkloadElement
	(core.#ScheduledTaskWorkloadElement.#fullyQualifiedName): core.#ScheduledTaskWorkloadElement

	// Data - Primitive Resources
	(core.#VolumeElement.#fullyQualifiedName):    core.#VolumeElement
	(core.#ConfigMapElement.#fullyQualifiedName): core.#ConfigMapElement
	(core.#SecretElement.#fullyQualifiedName):    core.#SecretElement

	// Data - Composite Traits
	(core.#SimpleDatabaseElement.#fullyQualifiedName): core.#SimpleDatabaseElement

	// Connectivity - Primitive Traits
	(core.#NetworkScopeElement.#fullyQualifiedName): core.#NetworkScopeElement

	// Connectivity - Modifier Traits
	(core.#ExposeElement.#fullyQualifiedName): core.#ExposeElement
}

#KubernetesElementRegistry: {
	// Kubernetes - Core API Group (elements.opm.dev/k8s/core/v1)
	(k8s.#PodElement.#fullyQualifiedName):                   k8s.#PodElement
	(k8s.#ServiceElement.#fullyQualifiedName):               k8s.#ServiceElement
	(k8s.#PersistentVolumeClaimElement.#fullyQualifiedName): k8s.#PersistentVolumeClaimElement
	(k8s.#ConfigMapElement.#fullyQualifiedName):             k8s.#ConfigMapElement
	(k8s.#SecretElement.#fullyQualifiedName):                k8s.#SecretElement
	(k8s.#ServiceAccountElement.#fullyQualifiedName):        k8s.#ServiceAccountElement
	(k8s.#NamespaceElement.#fullyQualifiedName):             k8s.#NamespaceElement
	(k8s.#NodeElement.#fullyQualifiedName):                  k8s.#NodeElement
	(k8s.#EndpointsElement.#fullyQualifiedName):             k8s.#EndpointsElement
	(k8s.#EventElement.#fullyQualifiedName):                 k8s.#EventElement
	(k8s.#LimitRangeElement.#fullyQualifiedName):            k8s.#LimitRangeElement
	(k8s.#ResourceQuotaElement.#fullyQualifiedName):         k8s.#ResourceQuotaElement

	// Kubernetes - Apps API Group (elements.opm.dev/k8s/apps/v1)
	(k8s.#DeploymentElement.#fullyQualifiedName):         k8s.#DeploymentElement
	(k8s.#StatefulSetElement.#fullyQualifiedName):        k8s.#StatefulSetElement
	(k8s.#DaemonSetElement.#fullyQualifiedName):          k8s.#DaemonSetElement
	(k8s.#ReplicaSetElement.#fullyQualifiedName):         k8s.#ReplicaSetElement
	(k8s.#ControllerRevisionElement.#fullyQualifiedName): k8s.#ControllerRevisionElement

	// Kubernetes - Batch API Group (elements.opm.dev/k8s/batch/v1)
	(k8s.#JobElement.#fullyQualifiedName):     k8s.#JobElement
	(k8s.#CronJobElement.#fullyQualifiedName): k8s.#CronJobElement

	// Kubernetes - Networking API Group (elements.opm.dev/k8s/networking/v1)
	(k8s.#IngressElement.#fullyQualifiedName):       k8s.#IngressElement
	(k8s.#IngressClassElement.#fullyQualifiedName):  k8s.#IngressClassElement
	(k8s.#NetworkPolicyElement.#fullyQualifiedName): k8s.#NetworkPolicyElement

	// Kubernetes - Storage API Group (elements.opm.dev/k8s/storage/v1)
	(k8s.#StorageClassElement.#fullyQualifiedName):       k8s.#StorageClassElement
	(k8s.#VolumeAttachmentElement.#fullyQualifiedName):   k8s.#VolumeAttachmentElement
	(k8s.#CSIDriverElement.#fullyQualifiedName):          k8s.#CSIDriverElement
	(k8s.#CSINodeElement.#fullyQualifiedName):            k8s.#CSINodeElement
	(k8s.#CSIStorageCapacityElement.#fullyQualifiedName): k8s.#CSIStorageCapacityElement

	// Kubernetes - RBAC API Group (elements.opm.dev/k8s/rbac/v1)
	(k8s.#RoleElement.#fullyQualifiedName):               k8s.#RoleElement
	(k8s.#RoleBindingElement.#fullyQualifiedName):        k8s.#RoleBindingElement
	(k8s.#ClusterRoleElement.#fullyQualifiedName):        k8s.#ClusterRoleElement
	(k8s.#ClusterRoleBindingElement.#fullyQualifiedName): k8s.#ClusterRoleBindingElement

	// Kubernetes - Policy API Group (elements.opm.dev/k8s/policy/v1)
	(k8s.#PodDisruptionBudgetElement.#fullyQualifiedName): k8s.#PodDisruptionBudgetElement

	// Kubernetes - Autoscaling API Group (elements.opm.dev/k8s/autoscaling/v2)
	(k8s.#HorizontalPodAutoscalerElement.#fullyQualifiedName): k8s.#HorizontalPodAutoscalerElement

	// Kubernetes - Certificates API Group (elements.opm.dev/k8s/certificates/v1)
	(k8s.#CertificateSigningRequestElement.#fullyQualifiedName): k8s.#CertificateSigningRequestElement

	// Kubernetes - Coordination API Group (elements.opm.dev/k8s/coordination/v1)
	(k8s.#LeaseElement.#fullyQualifiedName): k8s.#LeaseElement

	// Kubernetes - Discovery API Group (elements.opm.dev/k8s/discovery/v1)
	(k8s.#EndpointSliceElement.#fullyQualifiedName): k8s.#EndpointSliceElement

	// Kubernetes - Events API Group (elements.opm.dev/k8s/events/v1)
	(k8s.#EventV1Element.#fullyQualifiedName): k8s.#EventV1Element

	// Kubernetes - Node API Group (elements.opm.dev/k8s/node/v1)
	(k8s.#RuntimeClassElement.#fullyQualifiedName): k8s.#RuntimeClassElement

	// Kubernetes - Admission Registration API Group (elements.opm.dev/k8s/admissionregistration/v1)
	(k8s.#MutatingWebhookConfigurationElement.#fullyQualifiedName):     k8s.#MutatingWebhookConfigurationElement
	(k8s.#ValidatingWebhookConfigurationElement.#fullyQualifiedName):   k8s.#ValidatingWebhookConfigurationElement
	(k8s.#ValidatingAdmissionPolicyElement.#fullyQualifiedName):        k8s.#ValidatingAdmissionPolicyElement
	(k8s.#ValidatingAdmissionPolicyBindingElement.#fullyQualifiedName): k8s.#ValidatingAdmissionPolicyBindingElement

	// Kubernetes - API Extensions (elements.opm.dev/k8sextensions-apiserver/pkg/apis/apiextensions/v1)
	(k8s.#CustomResourceDefinitionElement.#fullyQualifiedName): k8s.#CustomResourceDefinitionElement

	// Kubernetes - Flow Control API Group (elements.opm.dev/k8s/flowcontrol/v1)
	(k8s.#FlowSchemaElement.#fullyQualifiedName):                 k8s.#FlowSchemaElement
	(k8s.#PriorityLevelConfigurationElement.#fullyQualifiedName): k8s.#PriorityLevelConfigurationElement

	// Kubernetes - Scheduling API Group (elements.opm.dev/k8s/scheduling/v1)
	(k8s.#PriorityClassElement.#fullyQualifiedName): k8s.#PriorityClassElement
}
