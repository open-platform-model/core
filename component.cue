package core

import (
	"list"
)

/////////////////////////////////////////////////////////////////
//// Component
/////////////////////////////////////////////////////////////////

// Workload type label key (imported from element.cue)
#LabelWorkloadType: "core.opm.dev/workload-type"

#Component: {
	#kind:       "Component"
	#apiVersion: "core.opm.dev/v0"
	#metadata: {
		#id!: string

		name!: string | *#id

		// Component labels - automatically merged from element labels
		// Element labels are added first, then component-specific labels can override
		// If elements have conflicting labels, CUE unification will fail (automatic validation)
		labels?: #LabelsAnnotationsType
		labels: {
			// Merge all element labels
			for _, elem in #elements {
				if elem.labels != _|_ {
					for k, v in elem.labels {
						(k): v
					}
				}
			}
		}

		// Component annotations - automatically merged from element annotations
		// Element annotations are added first, then component-specific annotations can override
		annotations?: #LabelsAnnotationsType
		annotations: {
			// Merge all element annotations
			for _, elem in #elements {
				if elem.annotations != _|_ {
					for k, v in elem.annotations {
						(k): v
					}
				}
			}
		}
		...
	}

	#elements: #ElementMap

	// Helper: Extract ALL primitive elements (recursively traverses composite elements)
	// Collect primitives by kind, then flatten
	_primitivesByKind: [
		for _, element in #elements {
			if element.kind == "primitive" {
				[element.#fullyQualifiedName]
			}
			if element.kind == "composite" {
				element.#primitiveElements
			}
			if element.kind != "primitive" && element.kind != "composite" {
				[]
			}
		},
	]
	#primitiveElements: list.FlattenN(_primitivesByKind, 1)

	// Add schema of all elements for validation purposes
	// This will ensure that all fields from all elements are included and validated
	// when a component is defined
	for _, elem in #elements {
		(elem.#nameCamel): elem.schema
	}
	...
}
