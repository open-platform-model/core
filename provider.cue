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
	#apiVersion: "core.opm.dev/v0"
	#metadata: {
		name:        string // The name of the provider
		description: string // A brief description of the provider
		version:     string // The version of the provider
		minVersion:  string // The minimum version of the provider

		// Labels for provider categorization and compatibility
		// Example: {"core.opm.dev/format": "kubernetes"}
		labels?: #LabelsAnnotationsType
	}

	// Transformer registry - maps platform resources to transformers
	// Example:
	// transformers: {
	// 	"k8s.io/api/apps/v1.Deployment": #DeploymentTransformer
	// 	"k8s.io/api/apps/v1.StatefulSet": #StatefulSetTransformer
	// }
	transformers: #TransformerMap

	// All elements declared by transformers (required + optional)
	// NOTE: This does NOT validate existence - validation happens at catalog level
	#declaredElements: #ElementStringArray & list.FlattenN([
		for _, transformer in transformers {
			list.Concat([transformer.required, transformer.optional])
		},
	], 1)
}

// Map of transformers by fully qualified name
#TransformerMap: [string]: #Transformer

// TransformerSelector interface (for future platform workflow)
// In developer workflow: Users manually create #transformersToComponents with expressions
// In platform workflow: Selector can auto-generate #transformersToComponents from provider
//
// The selector would generate transformer-to-component mappings by:
// 1. Analyzing component primitives and labels
// 2. Matching against available transformers from provider
// 3. Producing #transformersToComponents structure
//
// Example selector logic (future):
//   for each component:
//     for each transformer in provider.transformers:
//       if transformer.required ⊆ component.#primitiveElements:
//         if transformer.#metadata.labels ⊆ component.#metadata.labels:
//           add component to transformer's components list
#TransformerSelector: {
	select: {
		// Input: Module definition with components
		moduleDefinition: #ModuleDefinition

		// Input: Provider with transformers
		provider: #Provider

		// Output: Generated #transformersToComponents structure
		// Maps each transformer to its matching components
		output: [string]: {
			transformer: #Transformer
			components: [...string]
		}
	}
}

// Transformer interface - generic for all providers
// Transformers declare element requirements and transform logic
// Element validation happens at catalog level, not transformer level
#Transformer: {
	#kind: string // e.g. "Deployment"

	#apiVersion: string // e.g. "k8s.io/api/apps/v1"

	#fullyQualifiedName: "\(#apiVersion).\(#kind)" // e.g. "k8s.io/api/apps/v1.Deployment"

	// Metadata for transformer categorization and selection
	#metadata: {
		// Labels for categorizing transformers
		// Can be referenced in #transformersToComponents expressions for DRY matching
		// Example: transformer.#metadata.labels["core.opm.dev/workload-type"]
		// Common labels: {"core.opm.dev/workload-type": "stateless"}
		labels?: #LabelsAnnotationsType
	}

	// Required OPM primitive elements for this transformer to work
	required: #ElementStringArray // e.g. ["elements.opm.dev/core/v0.Container"]

	// Optional OPM modifier elements that can enhance the resource
	optional: #ElementStringArray | *[] // e.g. ["elements.opm.dev/core/v0.Replicas", "elements.opm.dev/core/v0.HealthCheck"]

	// All element fully qualified names (required + optional)
	#allTransformerElements: #ElementStringArray & list.Concat([required, optional])

	// Transform function
	// IMPORTANT: output must be a list of resources, even if only one resource is generated
	// This allows for consistent handling and concatenation in the module orchestration layer
	transform: {
		#component: #Component
		#context:   #TransformerContext

		output: [...] // Must be a list of provider-specific resources
	}
}

// Provider context passed to transformers
// Simplified: Components now have metadata unified from Module in CUE
#TransformerContext: close({
	// Module name and version
	name:    string
	version: string | *"latest"
})
