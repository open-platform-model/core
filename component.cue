package core

/////////////////////////////////////////////////////////////////
//// Component
/////////////////////////////////////////////////////////////////
#Component: {
	#kind:       "Component"
	#apiVersion: "core.opm.dev/v1alpha1"
	#metadata: {
		#id!: string

		name!: string | *#id

		// type!:         #ComponentTypes
		// if type == "workload" {
		// 	workloadType!: #WorkloadTypes
		// }
		// if type == "resource" {
		// 	if workloadType != _|_ {error("Resource components cannot have workloadType")}
		// }
		workloadType?: #WorkloadTypes

		// Component specific labels and annotations
		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
		...
	}

	#elements: #ElementMap

	// Helper: Extract ALL primitive elements (recursively traverses composite elements)
	#primitiveElements: #ElementMap
	#primitiveElements: {
		// Collect primitives from all elements
		for elementName, element in #elements {
			// If it's primitive, add it directly
			if element.kind == "primitive" {
				(elementName): element
			}
			// If it's composite, merge its primitives
			if element.kind == "composite" {
				for primName, primElement in element.#primitiveElements {
					(primName): primElement
				}
			}
		}
	}

	// TODO add validation to ensure only traits/resources are added based on componentType
	...
}

#ComponentTypeResource: "resource" // A pure resource (e.g. ConfigMap, Secret, Volume, etc.)
#ComponentTypeWorkload: "workload" // A workload that runs code (e.g. Deployment, StatefulSet, Function, VM, etc.)
#ComponentTypes: "resource" | "workload"

#WorkloadTypeStateless:      "stateless"      // e.g. Deployment, etc.
#WorkloadTypeStateful:       "stateful"       // e.g. StatefulSet, Database, etc.
#WorkloadTypeDaemon:         "daemon"         // e.g. DaemonSet, etc.
#WorkloadTypeTask:           "task"           // e.g. Job, etc.
#WorkloadTypeScheduledTask:  "scheduled-task" // e.g. CronJob, etc.
#WorkloadTypeFunction:       "function"       // e.g. Serverless function, etc.
#WorkloadTypes: #WorkloadTypeStateless | #WorkloadTypeStateful | #WorkloadTypeDaemon | #WorkloadTypeTask | #WorkloadTypeScheduledTask | #WorkloadTypeFunction
