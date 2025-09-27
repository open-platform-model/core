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

		type!:         #ComponentType
		workloadType?: string
		if type == "workload" {
			workloadType!: #WorkloadTypes
		}
		if type == "resource" {
			if workloadType != _|_ {error("Resource components cannot have workloadType")}
		}

		// Component specific labels and annotations
		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
		...
	}

	#elements: [elementName=string]: #Element & {#name!: elementName}

	// Helper: Extract ALL primitive elements (recursively traverses composite elements)
	#primitiveElements: [...string]
	#primitiveElements: {
		// Collect all primitive elements
		let allElements = [
			for _, e in #elements if e != _|_ {
				// Primitive traits contribute themselves
				if e.kind == "primitive" {
					e.#fullyQualifiedName
				}
			},
		]

		// Deduplicate and sort
		let set = {for cap in allElements {(cap): _}}
		list.SortStrings([for k, _ in set {k}])
	}

	// TODO add validation to ensure only traits/resources are added based on componentType
	...
}

#ComponentType: "resource" | "workload"

#WorkloadTypes: "stateless" | "stateful" | "daemon" | "task" | "scheduled-task"
