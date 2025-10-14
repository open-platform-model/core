package core

import (
	"list"
)

/////////////////////////////////////////////////////////////////
//// Module
/////////////////////////////////////////////////////////////////
#ModuleBase: {
	#apiVersion: "core.opm.dev/v1"
	#metadata: {
		name!:    #NameType
		version!: #VersionType

		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
		...
	}
	#status: {...}
	...
}

#ModuleDefinition: close(#ModuleBase & {
	#apiVersion: "core.opm.dev/v1"
	#kind:       "ModuleDefinition"
	#metadata: {
		name!:             #NameType
		defaultNamespace?: string | *"default"
		version!:          #VersionType
		description?:      string

		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	components: [Id=string]: #Component & {#metadata: #id: Id}

	// Developer-defined module scopes
	scopes?: [Id=string]: #Scope & {#metadata: #id: Id}

	// Schema/constraints for configurable values
	// Developers define the configuration contract - NO defaults, NO templating
	// Platform teams will add defaults and refine constraints in Module
	// MUST be OpenAPIv3 compliant (no CUE templating - for/if statements)
	values: {
		// Example patterns (constraints only):
		// replicas: uint                             // Type constraint
		// domain!: string                            // Required field
		// environment: "dev" | "staging" | "prod"    // Enum constraint
		// port: >0 & <65536                          // Range constraint
		// config: {
		//     timeout: int
		//     retries: uint
		// }
		...
	}

	#status: {
		componentCount: int | *0
		scopeCount:     int | *0
		componentCount: {if components != _|_ {len(components)}}
		scopeCount: {if scopes != _|_ {len(scopes)}}
	}
})

// Module is a clustered resource that references a ModuleDefinition and adds platform-specific configuration'
// Platform can add components and scopes but not remove
// Platform can modify defaults in values but not structure
// It is a cluster-scoped resource
#Module: close(#ModuleBase & {
	#apiVersion: "core.opm.dev/v1"
	#kind:       "Module"
	#metadata: {
		name:     #NameType
		version?: #VersionType

		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// Platform context for this module instance
	// Future plans for dynamic data.
	// Queried from the platform at runtime
	// e.g. current user, environment, region, cluster info, etc.
	#context: {...}

	moduleDefinition: #ModuleDefinition

	// Platform can add components but not remove
	components?: [Id=string]: #Component & {#metadata: #id: Id}
	#allComponents: {
		for id, comp in moduleDefinition.components {
			"\(id)": comp
		}
		if components != _|_ {
			for id, comp in components {
				"\(id)": comp
			}
		}
	}

	// Platform can add scopes but not remove
	scopes?: [Id=string]: #Scope & {#metadata: #id: Id}
	#allScopes: {
		if moduleDefinition.scopes != _|_ {
			for id, scope in moduleDefinition.scopes {
				"\(id)": scope
			}
		}
		if scopes != _|_ {
			for id, scope in scopes {
				"\(id)": scope
			}
		}
	}

	// Collect all primitive elements used by this module
	// Optimized: Use list.Concat instead of FlattenN for single-level flattening
	#allPrimitiveElements: #ElementStringArray & list.Concat([for _, comp in #allComponents {comp.#primitiveElements}])

	// CUE CONSTRAINT REFINEMENT STRATEGY:
	// Platform refines Definition constraints using CUE's unification
	// Platform can:
	//   - Add defaults: replicas: uint | *3
	//   - Refine constraints: domain: string & =~".*\\.myplatform\\.com$"
	//   - Add new fields: region: string | *"us-west"
	//   - Template values: Use for/if to populate from Definition (makes concrete)
	//
	// Note: Module.values does NOT need to be OpenAPIv3 compliant
	//       (can use CUE templating with for/if statements)

	// Platform team refines constraints and adds defaults
	values: moduleDefinition.values & {
		// Examples:
		// replicas: uint | *3                              // Add default to Definition constraint
		// domain: string & =~".*\\.myplatform\\.com$"     // Refine with regex pattern
		// environment: ("dev" | "staging" | "prod") | *"dev"  // Add default to enum
		// region: string | *"us-west"                      // New platform-specific field
		//
		// Templating example (makes values concrete):
		// for name, comp in moduleDefinition.components {
		//     "\(name)Image": string | *"default-\(name):latest"
		// }
		...
	}

	#status: moduleDefinition.#status & {
		totalComponentCount:    len(#allComponents)
		platformComponentCount: int | *0
		platformComponentCount: {if components != _|_ {len(components)}}
		platformScopeCount: int | *0
		platformScopeCount: {if scopes != _|_ {len(scopes)}}
		// platformScopes: [for id, scope in scopes if scope.#metadata.immutable {id}]
	}
})

// Module Release - a specific deployment of a Module
// Tracks the state of a Module deployment
// Includes a reference to the Module and the resolved values
// Includes status of the deployment
#ModuleRelease: close(#ModuleBase & {
	#apiVersion: "core.opm.dev/v1"
	#kind:       "ModuleRelease"
	#metadata: {
		name!:    #NameType
		version?: #VersionType
	}

	module: #Module

	provider: #Provider

	// User provides final concrete values
	// Unifies with Module's refined constraints
	// Single-level inheritance: only sees Module's constraints, not Definition's
	values: module.values & {
		...
	}

	#status: {}
})

// Module dependency resolution helper
#ModuleDependencyResolver: {
	module:   #Module
	provider: #Provider

	// Get all elements that need to be resolved
	requiredElements: #ElementStringArray & module.#allPrimitiveElements

	// Check which elements are supported by the provider
	supportedElements: #ElementStringArray & provider.#supportedElements

	// Find unsupported elements
	unsupportedElements: [
		for re in requiredElements
		if (re & string) == re
		if !list.Contains(supportedElements, re) {
			re
		},
	]

	// Resolution status
	resolved: len(unsupportedElements) == 0

	// Resolution report
	report: {
		totalElements:    len(requiredElements)
		supported:        len(supportedElements)
		unsupported:      len(unsupportedElements)
		resolutionStatus: resolved

		if len(unsupportedElements) > 0 {
			missingElements: unsupportedElements
			error:           "Module requires elements not supported by provider"
		}

		supportedElementsList: supportedElements
	}
}
