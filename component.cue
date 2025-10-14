package core

import (
	"list"
)

/////////////////////////////////////////////////////////////////
//// Component
/////////////////////////////////////////////////////////////////

// Workload type annotation key (imported from element.cue)
#AnnotationWorkloadType: "core.opm.dev/workload-type"

#Component: {
	#kind:       "Component"
	#apiVersion: "core.opm.dev/v0alpha1"
	#metadata: {
		#id!: string

		name!: string | *#id

		// Workload type is automatically derived from element annotations
		// If multiple workload types are included, this will result in a validation error
		// If workloadType is "", it means the component is not a workload (e.g., a configuration component)
		workloadType: string | *""
		for _, elem in #elements {
			if elem.annotations != _|_ && elem.annotations[#AnnotationWorkloadType] != _|_ {
				workloadType: elem.annotations[#AnnotationWorkloadType]
			}
		}

		// Component specific labels and annotations
		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
		...
	}

	#elements: #ElementMap

	// Helper: Extract ALL primitive elements (recursively traverses composite elements)
	#primitiveElements: list.FlattenN([
		for _, element in #elements {
			if element.kind == "primitive" {[element.#fullyQualifiedName]}
			if element.kind == "composite" {element.#primitiveElements}
			if element.kind != "primitive" && element.kind != "composite" {[]}
		},
	], -1)

	// Validation: Ensure only one workload type per component
	#workloadTypes: [
		for _, elem in #elements
		if elem.annotations != _|_ && elem.annotations[#AnnotationWorkloadType] != _|_ {
			elem.annotations[#AnnotationWorkloadType]
		},
	]

	// If multiple workload types exist, they must all be identical
	if len(#workloadTypes) > 1 {
		for wt in #workloadTypes {
			wt == #workloadTypes[0]
		}
	}

	// Add schema of all elements for validation purposes
	// This will ensure that all fields from all elements are included and validated
	// when a component is defined
	for _, elem in #elements {
		(elem.#nameCamel): elem.schema
	}

	// TODO add validation to ensure only traits/resources are added based on componentType
	...
}
