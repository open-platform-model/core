package kubernetes

/////////////////////////////////////////////////////////////////
//// Kubernetes Resource Specifications
/////////////////////////////////////////////////////////////////
//
// This file contains CUE definitions for Kubernetes native resources.
// These specs represent the full K8s API resource types that can be
// output by transformers.
//
// Organization: Grouped by Kubernetes API group
// - Core (elements.opm.dev/k8s/core/v1)
// - Apps (elements.opm.dev/k8s/apps/v1)
// - Batch (elements.opm.dev/k8s/batch/v1)
// - Networking (elements.opm.dev/k8s/networking/v1)
// - Storage (elements.opm.dev/k8s/storage/v1)
// - RBAC (elements.opm.dev/k8s/rbac/v1)
// - Policy, Autoscaling, etc.
//
/////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////
//// Core API Group (elements.opm.dev/k8s/core/v1)
//////////////////////////////////////////////////////////////////

#PodSpec: {
	apiVersion: "v1"
	kind:       "Pod"
	metadata:   #ObjectMeta
	spec: {
		containers: [...#ContainerSpec]
		initContainers?: [...#ContainerSpec]
		ephemeralContainers?: [...#EphemeralContainer]
		volumes?: [...#Volume]
		restartPolicy?:                 "Always" | "OnFailure" | "Never"
		terminationGracePeriodSeconds?: int
		activeDeadlineSeconds?:         int
		dnsPolicy?:                     string
		nodeSelector?: [string]: string
		serviceAccountName?:    string
		hostNetwork?:           bool
		hostPID?:               bool
		hostIPC?:               bool
		shareProcessNamespace?: bool
		securityContext?:       #PodSecurityContext
		imagePullSecrets?: [...{name: string}]
		affinity?:      #Affinity
		schedulerName?: string
		tolerations?: [...#Toleration]
		priorityClassName?: string
		priority?:          int
		...
	}
	status?: {...}
}

#ServiceSpec: {
	apiVersion: "v1"
	kind:       "Service"
	metadata:   #ObjectMeta
	spec: {
		type?: "ClusterIP" | "NodePort" | "LoadBalancer" | "ExternalName"
		selector?: [string]: string
		ports?: [...{
			name?:       string
			protocol?:   "TCP" | "UDP" | "SCTP"
			port:        int
			targetPort?: int | string
			nodePort?:   int
		}]
		clusterIP?: string
		clusterIPs?: [...string]
		externalIPs?: [...string]
		sessionAffinity?: "ClientIP" | "None"
		loadBalancerIP?:  string
		loadBalancerSourceRanges?: [...string]
		externalName?:          string
		externalTrafficPolicy?: "Cluster" | "Local"
		healthCheckNodePort?:   int
		...
	}
	status?: {...}
}

#PersistentVolumeClaimSpec: {
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata:   #ObjectMeta
	spec: {
		accessModes?: [...string]
		selector?: {
			matchLabels?: [string]: string
			matchExpressions?: [...{
				key:      string
				operator: string
				values?: [...string]
			}]
		}
		resources?: {
			requests?: {
				storage?: string
			}
			limits?: {
				storage?: string
			}
		}
		volumeName?:       string
		storageClassName?: string
		volumeMode?:       "Filesystem" | "Block"
		dataSource?: {...}
		dataSourceRef?: {...}
		...
	}
	status?: {...}
}

#ConfigMapSpec: {
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata:   #ObjectMeta
	data?: [string]:       string
	binaryData?: [string]: string
	immutable?: bool
}

#SecretSpec: {
	apiVersion: "v1"
	kind:       "Secret"
	metadata:   #ObjectMeta
	type?:      string | *"Opaque"
	data?: [string]:       string
	stringData?: [string]: string
	immutable?: bool
}

#ServiceAccountSpec: {
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata:   #ObjectMeta
	secrets?: [...{name: string}]
	imagePullSecrets?: [...{name: string}]
	automountServiceAccountToken?: bool
}

#NamespaceSpec: {
	apiVersion: "v1"
	kind:       "Namespace"
	metadata:   #ObjectMeta
	spec?: {
		finalizers?: [...string]
	}
	status?: {...}
}

#NodeSpec: {
	apiVersion: "v1"
	kind:       "Node"
	metadata:   #ObjectMeta
	spec?: {
		podCIDR?: string
		podCIDRs?: [...string]
		providerID?:    string
		unschedulable?: bool
		taints?: [...#Taint]
		...
	}
	status?: {...}
}

#EndpointsSpec: {
	apiVersion: "v1"
	kind:       "Endpoints"
	metadata:   #ObjectMeta
	subsets?: [...{
		addresses?: [...{
			ip:        string
			hostname?: string
			nodeName?: string
			targetRef?: {
				kind:             string
				namespace?:       string
				name:             string
				uid?:             string
				apiVersion?:      string
				resourceVersion?: string
			}
		}]
		notReadyAddresses?: [...{
			ip:        string
			hostname?: string
			nodeName?: string
		}]
		ports?: [...{
			name?:     string
			port:      int
			protocol?: "TCP" | "UDP" | "SCTP"
		}]
	}]
}

#EventSpec: {
	apiVersion: "v1"
	kind:       "Event"
	metadata:   #ObjectMeta
	involvedObject: {
		kind:             string
		namespace?:       string
		name:             string
		uid?:             string
		apiVersion?:      string
		resourceVersion?: string
		fieldPath?:       string
	}
	reason?:  string
	message?: string
	source?: {...}
	firstTimestamp?:     string
	lastTimestamp?:      string
	count?:              int
	type?:               string
	eventTime?:          string
	reportingComponent?: string
	reportingInstance?:  string
}

#LimitRangeSpec: {
	apiVersion: "v1"
	kind:       "LimitRange"
	metadata:   #ObjectMeta
	spec: {
		limits: [...{
			type: string
			max?: [string]:                  string
			min?: [string]:                  string
			default?: [string]:              string
			defaultRequest?: [string]:       string
			maxLimitRequestRatio?: [string]: string
		}]
	}
}

#ResourceQuotaSpec: {
	apiVersion: "v1"
	kind:       "ResourceQuota"
	metadata:   #ObjectMeta
	spec?: {
		hard?: [string]: string
		scopes?: [...string]
		scopeSelector?: {...}
	}
	status?: {...}
}

//////////////////////////////////////////////////////////////////
//// Apps API Group (elements.opm.dev/k8s/apps/v1)
//////////////////////////////////////////////////////////////////

#DeploymentSpec: {
	replicas?: int
	selector:  #LabelSelector
	template:  #PodTemplateSpec
	strategy?: {
		type?: "RollingUpdate" | "Recreate"
		rollingUpdate?: {
			maxUnavailable?: int | string
			maxSurge?:       int | string
		}
	}
	minReadySeconds?:         int
	revisionHistoryLimit?:    int
	progressDeadlineSeconds?: int
	paused?:                  bool
}

#StatefulSetSpec: {
	replicas?:   int
	selector:    #LabelSelector
	template:    #PodTemplateSpec
	serviceName: string
	updateStrategy?: {
		type?: "RollingUpdate" | "OnDelete"
		rollingUpdate?: {
			partition?:      int
			maxUnavailable?: int | string
		}
	}
	volumeClaimTemplates?: [...#PersistentVolumeClaimSpec]
	podManagementPolicy?:  "OrderedReady" | "Parallel"
	revisionHistoryLimit?: int
	minReadySeconds?:      int
	persistentVolumeClaimRetentionPolicy?: {
		whenDeleted?: "Retain" | "Delete"
		whenScaled?:  "Retain" | "Delete"
	}
	ordinals?: {
		start?: int
	}
}

#DaemonSetSpec: {
	apiVersion: "apps/v1"
	kind:       "DaemonSet"
	metadata:   #ObjectMeta
	spec: {
		selector: #LabelSelector
		template: #PodTemplateSpec
		updateStrategy?: {
			type?: "RollingUpdate" | "OnDelete"
			rollingUpdate?: {
				maxUnavailable?: int | string
				maxSurge?:       int | string
			}
		}
		minReadySeconds?:      int
		revisionHistoryLimit?: int
	}
	status?: {...}
}

#ReplicaSetSpec: {
	apiVersion: "apps/v1"
	kind:       "ReplicaSet"
	metadata:   #ObjectMeta
	spec: {
		replicas?:        int
		selector:         #LabelSelector
		template:         #PodTemplateSpec
		minReadySeconds?: int
	}
	status?: {...}
}

#ControllerRevisionSpec: {
	apiVersion: "apps/v1"
	kind:       "ControllerRevision"
	metadata:   #ObjectMeta
	data?: {...}
	revision: int
}

//////////////////////////////////////////////////////////////////
//// Batch API Group (elements.opm.dev/k8s/batch/v1)
//////////////////////////////////////////////////////////////////

#JobSpec: {
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata:   #ObjectMeta
	spec: {
		template:                 #PodTemplateSpec
		parallelism?:             int
		completions?:             int
		activeDeadlineSeconds?:   int
		backoffLimit?:            int
		selector?:                #LabelSelector
		manualSelector?:          bool
		ttlSecondsAfterFinished?: int
		completionMode?:          "NonIndexed" | "Indexed"
		suspend?:                 bool
		podFailurePolicy?: {...}
	}
	status?: {...}
}

#CronJobSpec: {
	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata:   #ObjectMeta
	spec: {
		schedule:                    string
		timeZone?:                   string
		jobTemplate:                 #JobTemplateSpec
		concurrencyPolicy?:          "Allow" | "Forbid" | "Replace"
		suspend?:                    bool
		successfulJobsHistoryLimit?: int
		failedJobsHistoryLimit?:     int
		startingDeadlineSeconds?:    int
	}
	status?: {...}
}

//////////////////////////////////////////////////////////////////
//// Networking API Group (elements.opm.dev/k8s/networking/v1)
//////////////////////////////////////////////////////////////////

#IngressSpec: {
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata:   #ObjectMeta
	spec?: {
		ingressClassName?: string
		defaultBackend?:   #IngressBackend
		tls?: [...{
			hosts?: [...string]
			secretName?: string
		}]
		rules?: [...{
			host?: string
			http?: {
				paths: [...{
					path?:    string
					pathType: "Exact" | "Prefix" | "ImplementationSpecific"
					backend:  #IngressBackend
				}]
			}
		}]
	}
	status?: {...}
}

#IngressClassSpec: {
	apiVersion: "networking.k8s.io/v1"
	kind:       "IngressClass"
	metadata:   #ObjectMeta
	spec?: {
		controller?: string
		parameters?: {
			apiGroup?:  string
			kind:       string
			name:       string
			namespace?: string
			scope?:     string
		}
	}
}

#NetworkPolicySpec: {
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata:   #ObjectMeta
	spec: {
		podSelector: #LabelSelector
		policyTypes?: [...string]
		ingress?: [...{
			ports?: [...{
				protocol?: "TCP" | "UDP" | "SCTP"
				port?:     int | string
				endPort?:  int
			}]
			from?: [...{
				podSelector?:       #LabelSelector
				namespaceSelector?: #LabelSelector
				ipBlock?: {
					cidr: string
					except?: [...string]
				}
			}]
		}]
		egress?: [...{
			ports?: [...{
				protocol?: "TCP" | "UDP" | "SCTP"
				port?:     int | string
				endPort?:  int
			}]
			to?: [...{
				podSelector?:       #LabelSelector
				namespaceSelector?: #LabelSelector
				ipBlock?: {
					cidr: string
					except?: [...string]
				}
			}]
		}]
	}
}

//////////////////////////////////////////////////////////////////
//// Storage API Group (elements.opm.dev/k8s/storage/v1)
//////////////////////////////////////////////////////////////////

#StorageClassSpec: {
	apiVersion:  "storage.k8s.io/v1"
	kind:        "StorageClass"
	metadata:    #ObjectMeta
	provisioner: string
	parameters?: [string]: string
	reclaimPolicy?: "Retain" | "Delete" | "Recycle"
	mountOptions?: [...string]
	allowVolumeExpansion?: bool
	volumeBindingMode?:    "Immediate" | "WaitForFirstConsumer"
	allowedTopologies?: [...{
		matchLabelExpressions?: [...{
			key: string
			values: [...string]
		}]
	}]
}

#VolumeAttachmentSpec: {
	apiVersion: "storage.k8s.io/v1"
	kind:       "VolumeAttachment"
	metadata:   #ObjectMeta
	spec: {
		attacher: string
		source: {
			persistentVolumeName?: string
			inlineVolumeSpec?: {...}
		}
		nodeName: string
	}
	status?: {...}
}

#CSIDriverSpec: {
	apiVersion: "storage.k8s.io/v1"
	kind:       "CSIDriver"
	metadata:   #ObjectMeta
	spec: {
		attachRequired?: bool
		podInfoOnMount?: bool
		volumeLifecycleModes?: [...string]
		storageCapacity?: bool
		fsGroupPolicy?:   string
		tokenRequests?: [...{
			audience:           string
			expirationSeconds?: int
		}]
		requiresRepublish?: bool
		seLinuxMount?:      bool
	}
}

#CSINodeSpec: {
	apiVersion: "storage.k8s.io/v1"
	kind:       "CSINode"
	metadata:   #ObjectMeta
	spec: {
		drivers: [...{
			name:   string
			nodeID: string
			topologyKeys?: [...string]
			allocatable?: {
				count?: int
			}
		}]
	}
}

#CSIStorageCapacitySpec: {
	apiVersion:         "storage.k8s.io/v1"
	kind:               "CSIStorageCapacity"
	metadata:           #ObjectMeta
	storageClassName:   string
	capacity?:          string
	maximumVolumeSize?: string
	nodeTopology?:      #LabelSelector
}

//////////////////////////////////////////////////////////////////
//// RBAC API Group (elements.opm.dev/k8s/rbac/v1)
//////////////////////////////////////////////////////////////////

#RoleSpec: {
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata:   #ObjectMeta
	rules?: [...#PolicyRule]
}

#RoleBindingSpec: {
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata:   #ObjectMeta
	subjects?: [...#Subject]
	roleRef: {
		apiGroup: string
		kind:     string
		name:     string
	}
}

#ClusterRoleSpec: {
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata:   #ObjectMeta
	rules?: [...#PolicyRule]
	aggregationRule?: {
		clusterRoleSelectors?: [...#LabelSelector]
	}
}

#ClusterRoleBindingSpec: {
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRoleBinding"
	metadata:   #ObjectMeta
	subjects?: [...#Subject]
	roleRef: {
		apiGroup: string
		kind:     string
		name:     string
	}
}

//////////////////////////////////////////////////////////////////
//// Policy API Group (elements.opm.dev/k8s/policy/v1)
//////////////////////////////////////////////////////////////////

#PodDisruptionBudgetSpec: {
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata:   #ObjectMeta
	spec?: {
		minAvailable?:               int | string
		maxUnavailable?:             int | string
		selector?:                   #LabelSelector
		unhealthyPodEvictionPolicy?: "IfHealthyBudget" | "AlwaysAllow"
	}
	status?: {...}
}

//////////////////////////////////////////////////////////////////
//// Autoscaling API Group (elements.opm.dev/k8s/autoscaling/v2)
//////////////////////////////////////////////////////////////////

#HorizontalPodAutoscalerSpec: {
	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata:   #ObjectMeta
	spec: {
		scaleTargetRef: {
			apiVersion: string
			kind:       string
			name:       string
		}
		minReplicas?: int
		maxReplicas:  int
		metrics?: [...{
			type: "Object" | "Pods" | "Resource" | "ContainerResource" | "External"
			...
		}]
		behavior?: {
			scaleUp?: {
				stabilizationWindowSeconds?: int
				selectPolicy?:               "Max" | "Min" | "Disabled"
				policies?: [...{
					type:          "Pods" | "Percent"
					value:         int
					periodSeconds: int
				}]
			}
			scaleDown?: {
				stabilizationWindowSeconds?: int
				selectPolicy?:               "Max" | "Min" | "Disabled"
				policies?: [...{
					type:          "Pods" | "Percent"
					value:         int
					periodSeconds: int
				}]
			}
		}
	}
	status?: {...}
}

//////////////////////////////////////////////////////////////////
//// Certificates API Group (elements.opm.dev/k8s/certificates/v1)
//////////////////////////////////////////////////////////////////

#CertificateSigningRequestSpec: {
	apiVersion: "certificates.k8s.io/v1"
	kind:       "CertificateSigningRequest"
	metadata:   #ObjectMeta
	spec: {
		request:            string
		signerName:         string
		expirationSeconds?: int
		usages?: [...string]
		username?: string
		uid?:      string
		groups?: [...string]
		extra?: [string]: [...string]
	}
	status?: {...}
}

//////////////////////////////////////////////////////////////////
//// Coordination API Group (elements.opm.dev/k8s/coordination/v1)
//////////////////////////////////////////////////////////////////

#LeaseSpec: {
	apiVersion: "coordination.k8s.io/v1"
	kind:       "Lease"
	metadata:   #ObjectMeta
	spec?: {
		holderIdentity?:       string
		leaseDurationSeconds?: int
		acquireTime?:          string
		renewTime?:            string
		leaseTransitions?:     int
	}
}

//////////////////////////////////////////////////////////////////
//// Discovery API Group (elements.opm.dev/k8s/discovery/v1)
//////////////////////////////////////////////////////////////////

#EndpointSliceSpec: {
	apiVersion:  "discovery.k8s.io/v1"
	kind:        "EndpointSlice"
	metadata:    #ObjectMeta
	addressType: "IPv4" | "IPv6" | "FQDN"
	endpoints?: [...{
		addresses: [...string]
		conditions?: {
			ready?:       bool
			serving?:     bool
			terminating?: bool
		}
		hostname?: string
		targetRef?: {...}
		nodeName?: string
		zone?:     string
		hints?: {
			forZones?: [...{
				name: string
			}]
		}
	}]
	ports?: [...{
		name?:        string
		protocol?:    "TCP" | "UDP" | "SCTP"
		port?:        int
		appProtocol?: string
	}]
}

//////////////////////////////////////////////////////////////////
//// Events API Group (elements.opm.dev/k8s/events/v1)
//////////////////////////////////////////////////////////////////

#EventV1Spec: {
	apiVersion: "events.k8s.io/v1"
	kind:       "Event"
	metadata:   #ObjectMeta
	regarding?: {
		kind:             string
		namespace?:       string
		name?:            string
		uid?:             string
		apiVersion?:      string
		resourceVersion?: string
		fieldPath?:       string
	}
	related?: {...}
	reason?:    string
	note?:      string
	action?:    string
	type?:      "Normal" | "Warning"
	eventTime?: string
	series?: {...}
	reportingController?: string
	reportingInstance?:   string
}

//////////////////////////////////////////////////////////////////
//// Node API Group (elements.opm.dev/k8s/node/v1)
//////////////////////////////////////////////////////////////////

#RuntimeClassSpec: {
	apiVersion: "node.k8s.io/v1"
	kind:       "RuntimeClass"
	metadata:   #ObjectMeta
	handler:    string
	overhead?: {
		podFixed?: [string]: string
	}
	scheduling?: {
		nodeSelector?: [string]: string
		tolerations?: [...#Toleration]
	}
}

//////////////////////////////////////////////////////////////////
//// Admission Registration API Group (elements.opm.dev/k8s/admissionregistration/v1)
//////////////////////////////////////////////////////////////////

#MutatingWebhookConfigurationSpec: {
	apiVersion: "admissionregistration.k8s.io/v1"
	kind:       "MutatingWebhookConfiguration"
	metadata:   #ObjectMeta
	webhooks?: [...#MutatingWebhook]
}

#ValidatingWebhookConfigurationSpec: {
	apiVersion: "admissionregistration.k8s.io/v1"
	kind:       "ValidatingWebhookConfiguration"
	metadata:   #ObjectMeta
	webhooks?: [...#ValidatingWebhook]
}

#ValidatingAdmissionPolicySpec: {
	apiVersion: "admissionregistration.k8s.io/v1"
	kind:       "ValidatingAdmissionPolicy"
	metadata:   #ObjectMeta
	spec?: {
		paramKind?: {...}
		matchConstraints?: {...}
		validations?: [...{
			expression:         string
			message?:           string
			reason?:            string
			messageExpression?: string
		}]
		failurePolicy?: "Fail" | "Ignore"
		auditAnnotations?: [...{
			key:             string
			valueExpression: string
		}]
		matchConditions?: [...{
			name:       string
			expression: string
		}]
		variables?: [...{
			name:       string
			expression: string
		}]
	}
}

#ValidatingAdmissionPolicyBindingSpec: {
	apiVersion: "admissionregistration.k8s.io/v1"
	kind:       "ValidatingAdmissionPolicyBinding"
	metadata:   #ObjectMeta
	spec?: {
		policyName: string
		paramRef?: {...}
		matchResources?: {...}
		validationActions?: [...string]
	}
}

//////////////////////////////////////////////////////////////////
//// API Extensions (elements.opm.dev/k8sextensions-apiserver/pkg/apis/apiextensions/v1)
//////////////////////////////////////////////////////////////////

#CustomResourceDefinitionSpec: {
	apiVersion: "apiextensions.k8s.io/v1"
	kind:       "CustomResourceDefinition"
	metadata:   #ObjectMeta
	spec: {
		group: string
		names: {
			plural:    string
			singular?: string
			kind:      string
			shortNames?: [...string]
			listKind?: string
			categories?: [...string]
		}
		scope: "Namespaced" | "Cluster"
		versions: [...{
			name:    string
			served:  bool
			storage: bool
			schema?: {
				openAPIV3Schema?: {...}
			}
			subresources?: {...}
			additionalPrinterColumns?: [...{
				name:         string
				type:         string
				jsonPath:     string
				description?: string
				priority?:    int
				format?:      string
			}]
			deprecated?:         bool
			deprecationWarning?: string
		}]
		conversion?: {
			strategy: "None" | "Webhook"
			webhook?: {...}
		}
		preserveUnknownFields?: bool
	}
	status?: {...}
}

//////////////////////////////////////////////////////////////////
//// Flow Control API Group (elements.opm.dev/k8s/flowcontrol/v1)
//////////////////////////////////////////////////////////////////

#FlowSchemaSpec: {
	apiVersion: "flowcontrol.apiserver.k8s.io/v1"
	kind:       "FlowSchema"
	metadata:   #ObjectMeta
	spec?: {
		priorityLevelConfiguration: {
			name: string
		}
		matchingPrecedence?: int
		distinguisherMethod?: {
			type: string
		}
		rules?: [...{
			subjects: [...{
				kind: string
				...
			}]
			resourceRules?: [...{
				verbs: [...string]
				apiGroups: [...string]
				resources: [...string]
				clusterScope?: bool
				namespaces?: [...string]
			}]
			nonResourceRules?: [...{
				verbs: [...string]
				nonResourceURLs: [...string]
			}]
		}]
	}
	status?: {...}
}

#PriorityLevelConfigurationSpec: {
	apiVersion: "flowcontrol.apiserver.k8s.io/v1"
	kind:       "PriorityLevelConfiguration"
	metadata:   #ObjectMeta
	spec?: {
		type: "Limited" | "Exempt"
		limited?: {
			nominalConcurrencyShares?: int
			limitResponse?: {
				type: "Queue" | "Reject"
				queuing?: {
					queues?:           int
					handSize?:         int
					queueLengthLimit?: int
				}
			}
			lendablePercent?:       int
			borrowingLimitPercent?: int
		}
		exempt?: {
			nominalConcurrencyShares?: int
			lendablePercent?:          int
		}
	}
	status?: {...}
}

//////////////////////////////////////////////////////////////////
//// Scheduling API Group (elements.opm.dev/k8s/scheduling/v1)
//////////////////////////////////////////////////////////////////

#PriorityClassSpec: {
	apiVersion:        "scheduling.k8s.io/v1"
	kind:              "PriorityClass"
	metadata:          #ObjectMeta
	value:             int
	globalDefault?:    bool
	description?:      string
	preemptionPolicy?: "Never" | "PreemptLowerPriority"
}

//////////////////////////////////////////////////////////////////
//// Common Types (used across multiple resources)
//////////////////////////////////////////////////////////////////

#ObjectMeta: {
	name?:      string
	namespace?: string
	labels?: [string]:      string
	annotations?: [string]: string
	uid?:                        string
	resourceVersion?:            string
	generation?:                 int
	creationTimestamp?:          string
	deletionTimestamp?:          string
	deletionGracePeriodSeconds?: int
	finalizers?: [...string]
	ownerReferences?: [...{
		apiVersion:          string
		kind:                string
		name:                string
		uid:                 string
		controller?:         bool
		blockOwnerDeletion?: bool
	}]
	managedFields?: [...{...}]
	...
}

#LabelSelector: {
	matchLabels?: [string]: string
	matchExpressions?: [...{
		key:      string
		operator: "In" | "NotIn" | "Exists" | "DoesNotExist"
		values?: [...string]
	}]
}

#PodTemplateSpec: {
	metadata?: #ObjectMeta
	spec:      #PodSpec.spec
}

#ContainerSpec: {
	name:             string
	image:            string
	imagePullPolicy?: "Always" | "IfNotPresent" | "Never"
	command?: [...string]
	args?: [...string]
	workingDir?: string
	ports?: [...{
		name?:         string
		hostPort?:     int
		containerPort: int
		protocol?:     "TCP" | "UDP" | "SCTP"
		hostIP?:       string
	}]
	env?: [...{
		name:   string
		value?: string
		valueFrom?: {
			fieldRef?: {
				apiVersion?: string
				fieldPath:   string
			}
			resourceFieldRef?: {
				containerName?: string
				resource:       string
				divisor?:       string
			}
			configMapKeyRef?: {
				name:      string
				key:       string
				optional?: bool
			}
			secretKeyRef?: {
				name:      string
				key:       string
				optional?: bool
			}
		}
	}]
	envFrom?: [...{
		prefix?: string
		configMapRef?: {
			name:      string
			optional?: bool
		}
		secretRef?: {
			name:      string
			optional?: bool
		}
	}]
	resources?: {
		limits?: [string]:   string
		requests?: [string]: string
		claims?: [...{
			name: string
		}]
	}
	volumeMounts?: [...{
		name:              string
		mountPath:         string
		subPath?:          string
		mountPropagation?: string
		readOnly?:         bool
		subPathExpr?:      string
	}]
	livenessProbe?:  #Probe
	readinessProbe?: #Probe
	startupProbe?:   #Probe
	lifecycle?: {
		postStart?: #LifecycleHandler
		preStop?:   #LifecycleHandler
	}
	terminationMessagePath?:   string
	terminationMessagePolicy?: "File" | "FallbackToLogsOnError"
	stdin?:                    bool
	stdinOnce?:                bool
	tty?:                      bool
	securityContext?:          #SecurityContext
	...
}

#EphemeralContainer: {
	#ContainerSpec
	targetContainerName?: string
}

#Volume: {
	name: string
	emptyDir?: {
		medium?:    string
		sizeLimit?: string
	}
	hostPath?: {
		path:  string
		type?: string
	}
	secret?: {
		secretName: string
		items?: [...{
			key:   string
			path:  string
			mode?: int
		}]
		defaultMode?: int
		optional?:    bool
	}
	configMap?: {
		name: string
		items?: [...{
			key:   string
			path:  string
			mode?: int
		}]
		defaultMode?: int
		optional?:    bool
	}
	persistentVolumeClaim?: {
		claimName: string
		readOnly?: bool
	}
	projected?: {
		sources: [...{
			secret?: {
				name: string
				items?: [...{
					key:   string
					path:  string
					mode?: int
				}]
				optional?: bool
			}
			configMap?: {
				name: string
				items?: [...{
					key:   string
					path:  string
					mode?: int
				}]
				optional?: bool
			}
			downwardAPI?: {
				items?: [...{
					path: string
					fieldRef?: {...}
					resourceFieldRef?: {...}
					mode?: int
				}]
			}
			serviceAccountToken?: {
				audience:           string
				expirationSeconds?: int
				path:               string
			}
		}]
		defaultMode?: int
	}
	downwardAPI?: {...}
	csi?: {...}
	ephemeral?: {...}
	...
}

#Probe: {
	httpGet?: {
		path?:   string
		port:    int | string
		host?:   string
		scheme?: "HTTP" | "HTTPS"
		httpHeaders?: [...{
			name:  string
			value: string
		}]
	}
	tcpSocket?: {
		port:  int | string
		host?: string
	}
	exec?: {
		command?: [...string]
	}
	grpc?: {
		port:     int
		service?: string
	}
	initialDelaySeconds?:           int
	timeoutSeconds?:                int
	periodSeconds?:                 int
	successThreshold?:              int
	failureThreshold?:              int
	terminationGracePeriodSeconds?: int
}

#LifecycleHandler: {
	exec?: {
		command?: [...string]
	}
	httpGet?: {
		path?:   string
		port:    int | string
		host?:   string
		scheme?: "HTTP" | "HTTPS"
		httpHeaders?: [...{
			name:  string
			value: string
		}]
	}
	tcpSocket?: {
		port:  int | string
		host?: string
	}
	sleep?: {
		seconds: int
	}
}

#SecurityContext: {
	capabilities?: {
		add?: [...string]
		drop?: [...string]
	}
	privileged?: bool
	seLinuxOptions?: {...}
	windowsOptions?: {...}
	runAsUser?:                int
	runAsGroup?:               int
	runAsNonRoot?:             bool
	readOnlyRootFilesystem?:   bool
	allowPrivilegeEscalation?: bool
	procMount?:                string
	seccompProfile?: {...}
}

#PodSecurityContext: {
	seLinuxOptions?: {...}
	windowsOptions?: {...}
	runAsUser?:    int
	runAsGroup?:   int
	runAsNonRoot?: bool
	supplementalGroups?: [...int]
	fsGroup?:             int
	fsGroupChangePolicy?: "OnRootMismatch" | "Always"
	seccompProfile?: {...}
	sysctls?: [...{
		name:  string
		value: string
	}]
}

#Affinity: {
	nodeAffinity?: {
		requiredDuringSchedulingIgnoredDuringExecution?: {
			nodeSelectorTerms: [...{
				matchExpressions?: [...{
					key:      string
					operator: string
					values?: [...string]
				}]
				matchFields?: [...{
					key:      string
					operator: string
					values?: [...string]
				}]
			}]
		}
		preferredDuringSchedulingIgnoredDuringExecution?: [...{
			weight: int
			preference: {...}
		}]
	}
	podAffinity?: {...}
	podAntiAffinity?: {...}
}

#Toleration: {
	key?:               string
	operator?:          "Exists" | "Equal"
	value?:             string
	effect?:            "NoSchedule" | "PreferNoSchedule" | "NoExecute"
	tolerationSeconds?: int
}

#Taint: {
	key:        string
	value?:     string
	effect:     "NoSchedule" | "PreferNoSchedule" | "NoExecute"
	timeAdded?: string
}

#IngressBackend: {
	service?: {
		name: string
		port: {
			name?:   string
			number?: int
		}
	}
	resource?: {
		apiGroup: string
		kind:     string
		name:     string
	}
}

#JobTemplateSpec: {
	metadata?: #ObjectMeta
	spec:      #JobSpec.spec
}

#PolicyRule: {
	verbs: [...string]
	apiGroups?: [...string]
	resources?: [...string]
	resourceNames?: [...string]
	nonResourceURLs?: [...string]
}

#Subject: {
	kind:       "User" | "Group" | "ServiceAccount"
	name:       string
	namespace?: string
	apiGroup?:  string
}

#MutatingWebhook: {
	name: string
	clientConfig: {
		url?: string
		service?: {
			namespace: string
			name:      string
			path?:     string
			port?:     int
		}
		caBundle?: string
	}
	rules?: [...{
		operations?: [...string]
		apiGroups?: [...string]
		apiVersions?: [...string]
		resources?: [...string]
		scope?: string
	}]
	failurePolicy?:     "Fail" | "Ignore"
	matchPolicy?:       "Exact" | "Equivalent"
	namespaceSelector?: #LabelSelector
	objectSelector?:    #LabelSelector
	sideEffects:        "None" | "NoneOnDryRun" | "Some" | "Unknown"
	timeoutSeconds?:    int
	admissionReviewVersions: [...string]
	reinvocationPolicy?: "Never" | "IfNeeded"
	matchConditions?: [...{
		name:       string
		expression: string
	}]
}

#ValidatingWebhook: {
	name: string
	clientConfig: {
		url?: string
		service?: {
			namespace: string
			name:      string
			path?:     string
			port?:     int
		}
		caBundle?: string
	}
	rules?: [...{
		operations?: [...string]
		apiGroups?: [...string]
		apiVersions?: [...string]
		resources?: [...string]
		scope?: string
	}]
	failurePolicy?:     "Fail" | "Ignore"
	matchPolicy?:       "Exact" | "Equivalent"
	namespaceSelector?: #LabelSelector
	objectSelector?:    #LabelSelector
	sideEffects:        "None" | "NoneOnDryRun" | "Some" | "Unknown"
	timeoutSeconds?:    int
	admissionReviewVersions: [...string]
	matchConditions?: [...{
		name:       string
		expression: string
	}]
}
