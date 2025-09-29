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

	// User-configurable values (like Helm values)
	// ALL fields MUST be optional to allow override
	// MUST be OpenAPIv3 compliant
	values: {
		// Example structure (all optional with defaults):
		// replicas?:     uint | *3
		// image?: {
		//     repository?: string | *"nginx"
		//     tag?:        string | *"1.0.0"
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
	#allPrimitiveElements: #ElementStringArray & list.FlattenN([
		for _, comp in #allComponents {comp.#primitiveElements},
	], 1)

	// Platform can modify defaults but not structure
	// TODO: Walk through moduleDefinition.values and replace with values from #Module.values
	values?: moduleDefinition.values & {
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

	// Resolved values after merging moduleDefinition.values and module.values
	values: module.moduleDefinition.values & module.values

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
		if (re & string) == re // Only include concrete strings
		if !list.Contains(supportedElements, re) {
			re
		}
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
