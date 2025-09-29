package core

import (
	"list"
	"strings"
)

/////////////////////////////////////////////////////////////////
//// Element Definition
/////////////////////////////////////////////////////////////////
#Element: {
	#name!:              string & strings.MinRunes(1) & strings.MaxRunes(254)
	#nameCamel:          strings.ToCamel(#name)
	#apiVersion:         string | *"core.opm.dev/v1alpha1"
	#fullyQualifiedName: "\(#apiVersion).\(#name)"

	// Human-readable description of the element
	description?: string

	// Optional metadata labels for categorization and filtering
	labels?: #LabelsAnnotationsType

	// The type of this element
	type!: #ElementTypes

	// kind of element
	kind!: #ElementKinds

	// Workload type (e.g., stateless, stateful, task, etc.) this element is associated with
	// Only one workload type can be specified per component
	// If empty, it means the element can be applied to any workload type
	// For resources this is just ignored
	workloadType?: #WorkloadTypes

	// Where can element be applied
	// Can be one or more of "component", "scope"
	target!: ["component"] | ["scope"] | ["component", "scope"]

	// MUST be an OpenAPIv3 compatible schema
	// TODO: Add validation to only allow one named struct per trait
	#schema!: _
	...
}

// Element types
#ElementTypeTrait: "trait" // A trait that modifies a component's behavior

#ElementTypeResource: "resource" // A resource that is managed by the platform

#ElementTypePolicy: "policy" // A policy that governs the behavior of components
#ElementTypes:      #ElementTypeTrait | #ElementTypeResource | #ElementTypePolicy

// Element kinds
#ElementKindPrimitive: "primitive" // A basic building block. Like a lego block

#ElementKindModifier: "modifier" // A modifier element that alters other primitive elements

#ElementKindComposite: "composite" // A composite element made up of multiple composite, modifiers, and/or primitive elements

#ElementKindCustom: "custom" // A custom element with special handling
#ElementKinds:      #ElementKindPrimitive | #ElementKindModifier | #ElementKindComposite | #ElementKindCustom

// Workload types
#WorkloadTypeNone: "" // No specific workload type

#WorkloadTypeStateless: "stateless" // e.g. Deployment, etc.

#WorkloadTypeStateful: "stateful" // e.g. StatefulSet, Database, etc.

#WorkloadTypeDaemon: "daemonSet" // e.g. DaemonSet, etc.

#WorkloadTypeTask: "task" // e.g. Job, etc.

#WorkloadTypeScheduledTask: "scheduled-task" // e.g. CronJob, etc.

#WorkloadTypeFunction: "function" // e.g. Serverless function, etc.
#WorkloadTypes:        *#WorkloadTypeNone | #WorkloadTypeStateless | #WorkloadTypeStateful | #WorkloadTypeDaemon | #WorkloadTypeTask | #WorkloadTypeScheduledTask | #WorkloadTypeFunction

// Different element categories
#PrimitiveElements: #PrimitiveTrait | #PrimitiveResource
#ModifierElements:  #ModifierTrait | #ModifierResource
#CompositeElements: #CompositeTrait | #CompositeResource
#CustomElements:    #CustomTrait | #CustomResource

// Element map and list types
#Elements: #PrimitiveElements | #ModifierElements | #CompositeElements | #CustomElements
#ElementMap: [string]: #Elements
#ElementArray: [...#Elements]

#ElementStringArray: [...string] // TODO: Add validation for #fullyQualifiedName

#ElementBase: {
	#elements: #ElementMap

	// Allow additional fields for extensibility
	...
}

// Primitive element - basic building block
// Must be implemented by the platform
#Primitive: #Element & {
	kind: "primitive"
}

// Composite trait - composed of multiple primitives
#Composite: #Element & {
	kind: "composite"

	// Which primitives/elements this composes
	composes!: #ElementArray

	// Recursively extract all primitive elements from this composite
	#primitiveElements: #ElementStringArray & list.FlattenN([
		// For each element in composes
		for element in composes
		if element.kind == "primitive" || element.kind == "composite" {
			// If it's primitive, add it directly
			if element.kind == "primitive" {
				[element.#fullyQualifiedName]
			}

			// If it's composite, merge its primitives
			if element.kind == "composite" {
				element.#primitiveElements
			}
		},
	], 1)

	// Ensure workloadType is set if any composed element has it set
	workloadType!: #WorkloadTypes
}

// Modifier element - modifies other elements
// Modifies by mutating the output of a component or scope
// Cannot stand alone
#Modifier: #Element & {
	kind: "modifier"

	// Which elements this can modify
	modifies!: #ElementStringArray
}

// Custom element - special handling outside of OPM spec
// e.g., raw Kubernetes manifests, Helm charts, etc.
#Custom: #Element & {
	kind: "custom"
}

/////////////////////////////////////////////////////////////////
//// Trait & Resource Bases
/////////////////////////////////////////////////////////////////
#PrimitiveTrait: close(#Primitive & {type: "trait"})
#ModifierTrait: close(#Modifier & {type: "trait"})
#CompositeTrait: close(#Composite & {type: "trait"})
#CustomTrait: close(#Custom & {type: "trait"})

#PrimitiveResource: close(#Primitive & {type: "resource"})
#ModifierResource: close(#Modifier & {type: "resource"})
#CompositeResource: close(#Composite & {type: "resource"})
#CustomResource: close(#Custom & {type: "resource"})
