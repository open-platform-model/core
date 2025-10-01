package core

import (
	"list"
	"strings"
)

/////////////////////////////////////////////////////////////////
//// Element Definition
/////////////////////////////////////////////////////////////////
#Element: {
	name!:               string & strings.MinRunes(1) & strings.MaxRunes(254)
	#nameCamel:          strings.ToCamel(name)
	#apiVersion:         string | *"core.opm.dev/v1alpha1"
	#fullyQualifiedName: "\(#apiVersion).\(name)"

	// What kind of element this is
	kind!: #ElementKinds // "primitive", "modifier", "composite", "custom"

	// Where can element be applied
	target!: ["component"] | ["scope"] | ["component", "scope"]

	// MUST be an OpenAPIv3 compatible schema
	// TODO: Add validation to only allow one named struct per trait
	schema!: _

	// Workload type (e.g., stateless, stateful, task, etc.) this element is associated with
	// Only one workload type can be specified per component
	// If null, it means the element is not associated with any specific workload type
	workloadType?: #WorkloadTypes

	// Human-readable description of the element
	description?: string

	// Optional metadata labels for categorization and filtering
	labels?: #LabelsAnnotationsType
	...
}

// Element kinds
// A basic building block. Like a lego block
// MUST be implemented by the provider for the target platform
#ElementKindPrimitive: "primitive"

// A modifier element that alters or enhances other primitive elements
#ElementKindModifier: "modifier"

// A composite element made up of multiple composite, primitive, and modifier elements
#ElementKindComposite: "composite"

// A custom element with special handling, works as a last resort
// MUST be implemented by the provider for the target platform
// e.g., raw Kubernetes manifests or custom operators that do not fit into the primitive/modifier/composite model
#ElementKindCustom: "custom"

#ElementKinds:      #ElementKindPrimitive | #ElementKindModifier | #ElementKindComposite | #ElementKindCustom

// Workload types
// No specific workload type
#WorkloadTypeNone: null

// e.g. Deployment, etc.
#WorkloadTypeStateless: "stateless"

// e.g. StatefulSet, Database, etc.
#WorkloadTypeStateful: "stateful"

// e.g. DaemonSet, etc.
#WorkloadTypeDaemon: "daemonSet"

// e.g. Job, etc.
#WorkloadTypeTask: "task"

// e.g. CronJob, etc.
#WorkloadTypeScheduledTask: "scheduled-task"

// e.g. Serverless function, etc.
#WorkloadTypeFunction: "function"

// All workload types
#WorkloadTypes: *#WorkloadTypeNone | #WorkloadTypeStateless | #WorkloadTypeStateful | #WorkloadTypeDaemon | #WorkloadTypeTask | #WorkloadTypeScheduledTask | #WorkloadTypeFunction

// Element map and list types
#Elements: #Primitive | #Modifier | #Composite | #Custom
// Map of elements
#ElementMap: [string]: #Elements
// Array of elements
#ElementArray: [...#Elements]
// Array of element names (fully qualified)
// TODO: Add validation for #fullyQualifiedName uniqueness
#ElementStringArray: [...string] 

#ElementBase: {
	#elements: #ElementMap

	// Allow additional fields for extensibility
	...
}

// Primitive element - basic building block
// Must be implemented by the provider for the target platform
#Primitive: #Element & {
	kind: "primitive"
}

// Composite trait - composed of multiple primitives
#Composite: #Element & {
	kind: "composite"

	// Which primitives/elements this composes
	composes!: #ElementArray

	// Recursively extract all primitive elements from this composite
	#primitiveElements: list.FlattenN([
		for element in composes {
			if element.kind == "primitive" {[element.#fullyQualifiedName]}
			if element.kind == "composite" {element.#primitiveElements}
			if element.kind != "primitive" && element.kind != "composite" {[]}
		},
	], -1)

	// Ensure workloadType is set if any composed element has it set
	workloadType!: #WorkloadTypes
}

// Modifier element - modifies other elements
// Modifies by mutating the output of a component or scope
// Cannot stand alone
#Modifier: #Element & {
	kind: "modifier"

	// Which elements this can modify
	modifies!: #ElementArray
}

// Custom element - special handling outside of OPM spec
// e.g., raw Kubernetes manifests, Helm charts, etc.
#Custom: #Element & {
	kind: "custom"
}
