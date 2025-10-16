package core

import (
	"list"
)

/////////////////////////////////////////////////////////////////
//// Element Registry
/////////////////////////////////////////////////////////////////

#ElementRegistry: #ElementMap

/////////////////////////////////////////////////////////////////
//// Platform Catalog
/////////////////////////////////////////////////////////////////

#ProviderMap: [string]: #Provider

// PlatformCatalog represents a platform's capability registry
// It tracks available elements, providers, and registered modules
#PlatformCatalog: {
	#kind:       "PlatformCatalog"
	#apiVersion: "core.opm.dev/v1"
	#metadata: {
		name!:        #NameType
		version!:     #VersionType
		description?: string

		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// Available element registry for this platform
	// All elements that can be used in modules on this platform
	#availableElements!: #ElementRegistry

	// Available providers for this platform
	// Maps provider name to provider definition
	// Providers are validated against availableElements when registered
	providers!: #ProviderMap

	// Compute supported elements for each provider based on catalog
	#providerCapabilities: {
		for providerName, provider in providers {
			(providerName): {
				declaredElements: provider.#declaredElements

				// Elements that exist in catalog
				supportedElements: [
					for element in provider.#declaredElements
					if #availableElements[element] != _|_ {
						element
					},
				]

				// Elements missing from catalog
				missingElements: [
					for element in provider.#declaredElements
					if #availableElements[element] == _|_ {
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

	// Modules registered in this catalog
	// Validation context is injected automatically
	modules?: [string]: #CatalogModule

	// Inject validation context into each module
	for moduleName, moduleEntry in modules {
		modules: (moduleName): #validation: {
			_catalogElements:           #availableElements
			_providerSupportedElements: #providerCapabilities[moduleEntry.targetProvider].supportedElements
		}
	}

	#status: {
		elementCount:  len(#availableElements)
		providerCount: len(providers)
		moduleCount:   int | *0
		moduleCount: {if modules != _|_ {len(modules)}}
	}
}

// CatalogModule represents a module entry in the platform catalog
// Includes validation against catalog capabilities
#CatalogModule: {
	module!: #Module

	// Target provider for this module
	targetProvider!: string

	// Validation results
	#validation: #ModuleValidationResult & {
		_module:                    module
		_catalogElements:           _ // Provided by catalog
		_targetProviderName:        targetProvider
		_providerSupportedElements: _ // Provided by catalog
	}

	// Module is admitted if validation passes
	admitted: #validation.valid

	// Admission metadata
	#admissionMetadata: {
		admittedAt?: string
		admittedBy?: string
		reason?:     string
	}

	if !admitted {
		#admissionMetadata: reason: #validation.#report.summary
	}
}

// ModuleValidationResult holds validation results for a module
#ModuleValidationResult: {
	_module:                    #Module
	_catalogElements:           #ElementRegistry
	_targetProviderName:        string
	_providerSupportedElements: #ElementStringArray // Provided by catalog

	// Required elements from module
	requiredElements: #ElementStringArray & _module.#allPrimitiveElements

	// Check against catalog's available elements
	missingInCatalog: [
		for elem in requiredElements
		if _catalogElements[elem] == _|_ {
			elem
		},
	]

	// Check against provider's supported elements
	unsupportedByProvider: [
		for elem in requiredElements
		if !list.Contains(_providerSupportedElements, elem) {
			elem
		},
	]

	// Validation passes if no missing or unsupported elements
	valid: len(missingInCatalog) == 0 && len(unsupportedByProvider) == 0

	// Detailed validation report
	#report: {
		...

		details: {
			totalElements:    len(requiredElements)
			missingCount:     len(missingInCatalog)
			unsupportedCount: len(unsupportedByProvider)

			// Valid if no missing or unsupported elements
			valid: len(missingInCatalog) == 0 && len(unsupportedByProvider) == 0

			if len(missingInCatalog) > 0 {
				missingElements: missingInCatalog
				missingMessage:  "Catalog is missing elements (see missingElements field for details)"
			}

			if len(unsupportedByProvider) > 0 {
				unsupportedElements: unsupportedByProvider
				unsupportedMessage:  "Provider '\(_targetProviderName)' does not support some elements (see unsupportedElements field for details)"
			}

			requiredElementsList: requiredElements
			availableInCatalog: [
				for elem in requiredElements
				if _catalogElements[elem] != _|_ {
					elem
				},
			]
			supportedByProvider: [
				for elem in requiredElements
				if list.Contains(_providerSupportedElements, elem) {
					elem
				},
			]
		}
	}
}

// ValidateModuleAdmission validates whether a module can be admitted to a catalog
// This is the main entry point for pre-admission validation
#ValidateModuleAdmission: {
	module!:   #Module
	catalog!:  #PlatformCatalog
	provider!: string // Provider name from catalog

	// Ensure provider exists in catalog
	_providerExists: provider & catalog.providers[provider].#metadata.name

	// Run module validation
	#validation: #ModuleValidationResult & {
		_module:                    module
		_catalogElements:           catalog.#availableElements
		_targetProviderName:        provider
		_providerSupportedElements: catalog.#providerCapabilities[provider].supportedElements
	}

	// Comprehensive admission report
	admissionReport: {
		moduleName:     module.#metadata.name
		moduleVersion:  module.#metadata.version
		targetProvider: provider

		validationStatus: #validation.valid

		// Admission decision
		admitted: #validation.valid

		validationReport: #validation.#report

		// Summary message
		if #validation.valid == true {
			status:  "admitted"
			message: "Module is ready for deployment"
		}
		if #validation.valid == false {
			status:  "rejected"
			message: "Module validation failed"
		}

		...
	}
}
