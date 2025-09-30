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

	#registry: #ElementRegistry

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

	// Optimized: flatten and sort supported elements from all transformers
	#supportedElements: #ElementStringArray & list.FlattenN([
		for _, transformer in transformers {
			transformer.#supportedElements
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
#Transformer: {
	#kind: string // e.g. "Deployment"

	#apiVersion: string // e.g. "k8s.io/api/apps/v1"

	#fullyQualifiedName: "\(#apiVersion).\(#kind)" // e.g. "k8s.io/api/apps/v1.Deployment"

	// Element registry - must be populated by provider implementation
	_registry: #ElementMap
	if _registry == _|_ {
		error("Transformer must have an element registry")
	}

	// Required OPM primitive elements for this transformer to work
	required: #ElementStringArray // e.g. ["core.opm.dev/v1alpha1.StatelessWorkload", "core.opm.dev/v1alpha1.StatefulWorkload"]

	// if len(required) == 0 {
	// 	error("Transformer must have at least one required element")
	// }

	// Optional OPM modifier elements that can enhance the resource
	optional: #ElementStringArray | *[] // e.g. ["core.opm.dev/v1alpha1.SidecarContainers", "core.opm.dev/v1alpha1.Replicas", "core.opm.dev/v1alpha1.UpdateStrategy", "core.opm.dev/v1alpha1.Expose", "core.opm.dev/v1alpha1.HealthCheck"]

	// All element fully qualified names (required + optional)
	#allTransformerElements: #ElementStringArray & list.Concat([required, optional])

	// Optimized: Use map lookup instead of list.Contains for O(1) access
	#supportedElements: #ElementStringArray & [
		for element in #allTransformerElements
		if _registry[element] != _|_ {
			element
		},
	]

	// Auto-generated defaults from optional element schemas
	defaults: {
		// Optimized: Direct map lookup instead of Contains check
		for elementFQN in optional
		if _registry[elementFQN] != _|_
		if _registry[elementFQN].kind == "modifier" {
			let element = _registry[elementFQN]

			// Only include modifier elements as defaults
			// Composite elements are made up of other elements and should not be top-level defaults
			// Primitive elements do not have defaults
			(element.#nameCamel): element.schema
		}

		// Allow transformer-specific additional defaults
		...
	}

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
