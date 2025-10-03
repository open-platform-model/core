package core

/////////////////////////////////////////////////////////////////
//// Provider Definition
/////////////////////////////////////////////////////////////////

import (
	"list"
)

// Provider interface
// Providers declare transformers and rendering logic
// Element validation happens at catalog level when provider is registered
#Provider: {
	#kind:       "Provider"
	#apiVersion: "core.opm.dev/v1alpha1"
	#metadata: {
		name:        string // The name of the provider
		description: string // A brief description of the provider
		version:     string // The version of the provider
		minVersion:  string // The minimum version of the provider
	}

	// Transformer registry - maps platform resources to transformers
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

	// All elements declared by transformers (required + optional)
	// NOTE: This does NOT validate existence - validation happens at catalog level
	#declaredElements: #ElementStringArray & list.FlattenN([
		for _, transformer in transformers {
			list.Concat([transformer.required, transformer.optional])
		},
	], 1)

	// Render function
	render: {
		module: #Module
		output: _ // Provider-specific output format. e.g., Kubernetes List object
		...
	}
}

#TransformerMap: [string]: #Transformer

// Transformer interface - generic for all providers
// Transformers declare element requirements and transform logic
// Element validation happens at catalog level, not transformer level
#Transformer: {
	#kind: string // e.g. "Deployment"

	#apiVersion: string // e.g. "k8s.io/api/apps/v1"

	#fullyQualifiedName: "\(#apiVersion).\(#kind)" // e.g. "k8s.io/api/apps/v1.Deployment"

	// Required OPM primitive elements for this transformer to work
	required: #ElementStringArray // e.g. ["elements.opm.dev/core/v1alpha1.Container"]

	// Optional OPM modifier elements that can enhance the resource
	optional: #ElementStringArray | *[] // e.g. ["elements.opm.dev/core/v1alpha1.Replicas", "elements.opm.dev/core/v1alpha1.HealthCheck"]

	// All element fully qualified names (required + optional)
	#allTransformerElements: #ElementStringArray & list.Concat([required, optional])

	// Transform function
	transform: {
		component: #Component
		context:   #ProviderContext
		output:    _ // Provider-specific output format
	}
}

// Provider context passed to transformers
// Contains hierarchical metadata for resource generation
#ProviderContext: {
	name:      string // Module name
	namespace: string // Module namespace

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

// Transformer selection logic
// Matches component primitives to available transformers
// For now, each primitive maps to exactly one transformer
#SelectTransformer: {
	component:             #Component
	availableTransformers: #TransformerMap

	// Grab primitive elements from component
	primitiveElements: #ElementStringArray & component.#primitiveElements

	// Optimized: Build reverse index first (primitive -> transformer)
	// This avoids O(n*m) nested loops
	_primitiveToTransformer: {
		for tName, transformer in availableTransformers {
			for req in transformer.required {
				(req): transformer.#fullyQualifiedName
			}
		}
	}

	// Direct mapping: each primitive gets exactly one transformer
	// Future versions may support multiple transformers per primitive with selection logic
	selectedTransformers: [
		for primitiveFQN in primitiveElements
		if _primitiveToTransformer[primitiveFQN] != _|_ {
			primitive:   primitiveFQN
			transformer: _primitiveToTransformer[primitiveFQN]
		},
	]
}
