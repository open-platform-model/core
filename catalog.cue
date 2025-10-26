package core

/////////////////////////////////////////////////////////////////
//// Element Registry
/////////////////////////////////////////////////////////////////

#ElementRegistry: #ElementMap

/////////////////////////////////////////////////////////////////
//// Catalog Module
/////////////////////////////////////////////////////////////////

// CatalogModule bundles a module definition with its rendering strategy
// This represents a complete, ready-to-deploy module configuration
#CatalogModule: {
	#kind:       "CatalogModule"
	#apiVersion: "core.opm.dev/v0"

	#metadata: {
		name!:        #NameType
		description?: string
		version!:     #VersionType

		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// The module definition (developer-created)
	moduleDefinition!: #ModuleDefinition

	// Renderer for this module
	renderer!: #Renderer

	// Provider for this module
	provider!: #Provider

	// Note: Both primitive element resolution and transformer-component matching
	// are handled by the OPM CLI runtime
	// The runtime will:
	// 1. Load the element registry
	// 2. Analyze components to resolve primitive elements
	// 3. Match transformers from provider to components based on:
	//    - Component primitives matching transformer required/optional
	//    - Component labels matching ALL transformer labels
	// 4. Execute matched transformers and renderer
}

/////////////////////////////////////////////////////////////////
//// Platform Catalog
/////////////////////////////////////////////////////////////////

#ProviderMap: [string]: #Provider

// PlatformCatalog represents a platform's capability registry
// It tracks available elements, providers, renderers, and registered modules
#PlatformCatalog: {
	#kind:       "PlatformCatalog"
	#apiVersion: "core.opm.dev/v0"
	#metadata: {
		name!:        #NameType
		version!:     #VersionType
		description?: string

		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// Available providers for this platform
	// Maps provider name to provider definition
	// Providers are validated against availableElements when registered
	providers!: #ProviderMap

	// Available renderers for this platform
	renderers!: #RendererMap

	// Catalog modules - complete module configurations ready to deploy
	// Each module bundles a definition with its rendering strategy (transformers + renderer)
	modules: [string]: #CatalogModule

	// Available element registry for this platform
	// All elements that can be used in modules on this platform
	elementRegistry!: #ElementRegistry

	// Compute supported elements for each provider based on catalog
	#providerCapabilities: {
		for providerName, provider in providers {
			(providerName): {
				declaredElements: provider.#declaredElements

				// Elements that exist in catalog
				supportedElements: [
					for element in provider.#declaredElements
					if elementRegistry[element] != _|_ {
						element
					},
				]

				// Elements missing from catalog
				missingElements: [
					for element in provider.#declaredElements
					if elementRegistry[element] == _|_ {
						element
					},
				]

				valid: len(missingElements) == 0

				if !valid {
					error: "Provider '\(providerName)' requires elements not in catalog: \(missingElements)"
				}
			}
		}
	}

	// Validation for catalog modules
	// Validates that modules have valid definitions and rendering configurations
	#moduleValidation: {
		for modName, catalogMod in modules {
			(modName): {
				// Validate module definition
				definitionValid: catalogMod.moduleDefinition.#metadata.name != _|_

				// Validate renderer is set
				rendererValid: catalogMod.renderer != _|_

				// Validate provider is configured
				providerValid: catalogMod.provider != _|_
			}
		}
	}

	// Provider/Renderer compatibility validation
	// Checks that providers and renderers have compatible format labels
	#providerRendererCompatibility: {
		for providerName, provider in providers {
			(providerName): {
				outputFormat: string | *"unknown"
				if provider.#metadata.labels != _|_ && provider.#metadata.labels["core.opm.dev/format"] != _|_ {
					outputFormat: provider.#metadata.labels["core.opm.dev/format"]
				}

				// List compatible renderers
				compatibleRenderers: [
					for rendererName, renderer in renderers {
						if renderer.#metadata.labels != _|_ && renderer.#metadata.labels["core.opm.dev/format"] != _|_ {
							if renderer.#metadata.labels["core.opm.dev/format"] == outputFormat {
								rendererName
							}
						}
					},
				]
			}
		}
	}

	#status: {
		elementCount:  len(elementRegistry)
		providerCount: len(providers)
		rendererCount: len(renderers)
		moduleCount:   int | *0
		moduleCount: {if modules != _|_ {len(modules)}}
	}
}
