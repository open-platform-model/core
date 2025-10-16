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
	#apiVersion:         string | *"core.opm.dev/v0"
	#fullyQualifiedName: "\(#apiVersion).\(name)"

	// What kind of element this is
	kind!: #ElementKinds // "primitive", "modifier", "composite", "custom"

	// Where can element be applied
	target!: ["component"] | ["scope"] | ["component", "scope"]

	// MUST be an OpenAPIv3 compatible schema
	// TODO: Add validation to only allow one named struct per trait
	schema!: _

	// Human-readable description of the element
	description?: string

	// Optional metadata labels for categorization and filtering
	labels?: #LabelsAnnotationsType

	// Optional metadata annotations for element behavior hints (not used for categorization)
	// Providers can use annotations for decision-making (e.g., workload type selection)
	// Example: {"core.opm.dev/workload-type": "stateless"}
	annotations?: #LabelsAnnotationsType
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

#ElementKinds: #ElementKindPrimitive | #ElementKindModifier | #ElementKindComposite | #ElementKindCustom

// Workload type annotation constants
// Annotation key for workload type
#AnnotationWorkloadType: "core.opm.dev/workload-type"

// Workload type values (used in annotations)
// e.g. Deployment, etc.
#WorkloadTypeStateless: "stateless"

// e.g. StatefulSet, Database, etc.
#WorkloadTypeStateful: "stateful"

// e.g. DaemonSet, etc.
#WorkloadTypeDaemon: "daemon"

// e.g. Job, etc.
#WorkloadTypeTask: "task"

// e.g. CronJob, etc.
#WorkloadTypeScheduledTask: "scheduled-task"

// e.g. Serverless function, etc.
#WorkloadTypeFunction: "function"

// Element map and list types
#Elements: #Primitive | #Modifier | #Composite | #Custom

// Map of elements
#ElementMap: [string]: #Elements

// Array of elements
#ElementArray: [...#Elements]

// Array of element names (fully qualified)
// TODO: Add validation for #fullyQualifiedName uniqueness
#ElementStringArray: [...string]

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
}

// Modifier element - modifies other elements
// Modifies by mutating the output of a component or scope
// Cannot stand alone
#Modifier: #Element & {
	kind: "modifier"

	// Which primitive elements this modifies
	modifies!: [...#Primitive]
}

// Custom element - special handling outside of OPM spec
// e.g., raw Kubernetes manifests, Helm charts, etc.
#Custom: #Element & {
	kind: "custom"
}
