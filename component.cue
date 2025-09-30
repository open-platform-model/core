package core

import (
	"list"
)

/////////////////////////////////////////////////////////////////
//// Component
/////////////////////////////////////////////////////////////////
#Component: {
	#kind:       "Component"
	#apiVersion: "core.opm.dev/v1alpha1"
	#metadata: {
		#id!: string

		name!: string | *#id

		// Workload type is automatically derived from included elements
		// If multiple workload types are included, this will result in a validation error
		// If workloadType is set to "", it means the component is not a workload (e.g., a configuration component)
		workloadType: #WorkloadTypes
		for _, elem in #elements {
			if elem.workloadType != _|_ {
				workloadType: elem.workloadType
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

	// TODO add validation to ensure only traits/resources are added based on componentType
	...
}
