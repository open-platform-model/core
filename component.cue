package core

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

		// Namespace (typically unified from Module)
		namespace?: string

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

	// Note: Primitive elements are now resolved by the OPM CLI runtime
	// The runtime analyzes #elements and recursively resolves all primitive elements

	// Add schema of all elements for validation purposes
	// This will ensure that all fields from all elements are included and validated
	// when a component is defined
	for _, elem in #elements {
		(elem.#nameCamel): elem.schema
	}
	...
}
