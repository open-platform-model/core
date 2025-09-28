package core

/////////////////////////////////////////////////////////////////
//// Provider Definition
/////////////////////////////////////////////////////////////////

import (
	"list"
)

// Provider interface
#Provider: {
	#kind:       "Provider"
	#apiVersion: "core.opm.dev/v1alpha1"
	#metadata: {
		name:        string // The name of the provider
		description: string // A brief description of the provider
		version:     string // The version of the provider
		minVersion:  string // The minimum version of the provider
	}

	// Transformer registry - maps traits to transformers
	// Example:
	// transformers: {
	// 	"k8s.io/api/apps/v1.Deployment":            #DeploymentTransformer
	// 	"k8s.io/api/apps/v1.StatefulSet":           #StatefulSetTransformer
	// 	"k8s.io/api/apps/v1.DaemonSet":             #DaemonSetTransformer
	// 	"k8s.io/api/batch/v1.Job":                  #JobTransformer
	// 	"k8s.io/api/batch/v1.CronJob":              #CronJobTransformer
	// 	"k8s.io/api/core/v1.PersistentVolumeClaim": #PersistentVolumeClaimTransformer
	// 	"k8s.io/api/core/v1.Service":               #ServiceTransformer
	// }
	transformers: #TransformerMap

	#supportedElements: #ElementMap
	#supportedElements: {
		if transformers != null {
			for _, transformer in transformers {
				for elementName, element in transformer.#supportedElements {
					if element != _|_ {
						(elementName): element
					}
				}
			}
		}
	}

	// Render function
	render: {
		module: #Module
		output: _ // Provider-specific output format. e.g., Kubernetes List object
	}
}

#TransformerMap: [string]: #Transformer

// Transformer interface - generic for all providers
#Transformer: {
	// What native resource this transformer creates
	creates: string // e.g. "k8s.io/api/apps/v1.Deployment"

	// What type of component workloadType this transformer supports (if any)
	// If not specified, supports all workload types
	workloadType?: #WorkloadTypes // e.g. "stateless" | "stateful" | "daemon" | "task" | "scheduled-task"

	// Element registry - must be populated by provider implementation
	_registry: #ElementRegistry

	// Required OPM elements for this transformer to work
	required!: [...string] // e.g. ["core.opm.dev/v1alpha1.Container"]

	// Optional OPM elements that can enhance the resource
	optional: [...string] | *[] // e.g. ["core.opm.dev/v1alpha1.Replicas", "core.opm.dev/v1alpha1.UpdateStrategy", "core.opm.dev/v1alpha1.Expose", "core.opm.dev/v1alpha1.LivenessProbe", "core.opm.dev/v1alpha1.ReadinessProbe"]

	// All element names (required + optional)
	allElementNames: [...string] & list.Concat([required, optional])

	#supportedElements: #ElementMap
	#supportedElements: {
		for elementName in allElementNames {
			let resolvedElement = #ResolveElement & {
				name:      elementName
				_reg: _registry
			}
			if resolvedElement.element != _|_ {
				(elementName): resolvedElement.element
			}
		}
	}

	// Auto-generated defaults from optional element schemas
	defaults: {
		// Resolve schemas from optional elements only
		for elementName in (optional | *[]) {
			let resolvedSchema = #ResolveElement & {
				name:      elementName
				_reg: _registry
			}
			if resolvedSchema.elementSchema != _|_ {
				resolvedSchema.elementSchema
			}
		}
		// Allow transformer-specific additional defaults
		...
	}

	// Transform function
	transform: {...}
	// transform: {
	// 	component: #Component
	// 	context:   #ProviderContext
	// 	output:    _ // Provider-specific output format
	// }
}

// Helper to resolve element schema by name from registry
#ResolveElement: {
	name:      string
	_reg: #ElementRegistry

	element: {
		if _reg[name] != _|_ {
			_reg[name]
		}
	}
	elementSchema: {
		if element != _|_ {
			element.#schema
		}
	}
}

// Provider context passed to transformers
// Contains hierarchical metadata for resource generation
#ProviderContext: {
	name:      string // Application name
	namespace: string // Application namespace

	// Module and component being processed
	_module:    #Module
	_component: #Component

	// Shortcuts for easier access
	moduleMetadata:    _module.#metadata
	componentMetadata: _component.#metadata

	// Unified labels and annotations from module and component
	unifiedLabels: {
		for k, v in moduleMetadata.labels & componentMetadata.labels {
			"\(k)": "\(v)" // Convert all label values to strings
		}
	} | *{}
	unifiedAnnotations: {
		for k, v in moduleMetadata.annotations & componentMetadata.annotations {
			"\(k)": "\(v)" // Convert all annotation values to strings
		}
	} | *{}
}
