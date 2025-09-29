// REFERENCE CODE - Not currently used but saved for future consideration
// This file contains the traitImplementations concept that was removed for simplification
// but may be revisited in the future for more complex provider scenarios

package core

// The traitImplementations concept allowed providers to define multiple
// implementation strategies for the same trait, with resolution chains
// and fallback mechanisms.

// Example of what traitImplementations might look like:
#TraitImplementation: {
	// The trait being implemented
	trait: string // e.g., "core.opm.dev/v1alpha1.Workload"

	// Multiple implementation strategies in order of preference
	strategies: [...#ImplementationStrategy]
}

#ImplementationStrategy: {
	// Name of this strategy
	name: string

	// Conditions when this strategy applies
	when?: {
		// Match based on element properties
		elementMatches?: {
			[string]: _
		}
		// Match based on component metadata
		metadataMatches?: {
			[string]: _
		}
	}

	// The transformer to use
	transformer: string // Reference to transformer in registry

	// Optional fallback if this strategy fails
	fallback?: string // Reference to another strategy
}

// Example usage in a provider:
#ExampleProvider: {
	// Current simplified approach - direct mapping
	transformers: {
		"k8s.io/api/apps/v1.Deployment":  #DeploymentTransformer
		"k8s.io/api/apps/v1.StatefulSet": #StatefulSetTransformer
	}

	// Future traitImplementations approach - more flexible
	traitImplementations: {
		"core.opm.dev/v1alpha1.Workload": {
			strategies: [
				{
					name: "stateful"
					when: {
						elementMatches: {
							"core.opm.dev/v1alpha1.Storage": _
						}
					}
					transformer: "k8s.io/api/apps/v1.StatefulSet"
				},
				{
					name:        "stateless"
					transformer: "k8s.io/api/apps/v1.Deployment"
				},
			]
		}
	}
}

// Benefits of traitImplementations:
// 1. Multiple ways to implement the same trait
// 2. Conditional logic for choosing implementation
// 3. Fallback chains for resilience
// 4. More complex provider capabilities

// Drawbacks (why it was removed):
// 1. Added complexity for simple use cases
// 2. Harder to understand and debug
// 3. Most providers only need 1:1 mappings
// 4. Can be added later when needed
