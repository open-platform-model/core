package core

import (
	"strings"
)

/////////////////////////////////////////////////////////////////
//// Element Definition
/////////////////////////////////////////////////////////////////
#Element: {
	#name!:              string & strings.MinRunes(1) & strings.MaxRunes(254)
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

	// Where can element be applied
	// Can be one or more of "component", "scope"
	target!: ["component"] | ["scope"] | ["component", "scope"]

	// MUST be an OpenAPIv3 compatible schema
	// TODO: Add validation to only allow one named struct per trait
	#schema!: _
	...
}

#ElementTypeTrait: "trait" // A trait that modifies a component's behavior
#ElementTypeResource: "resource" // A resource that is managed by the platform
#ElementTypePolicy: "policy" // A policy that governs the behavior of components
#ElementTypes: #ElementTypeTrait | #ElementTypeResource | #ElementTypePolicy

#ElementKindPrimitive: "primitive"   // A basic building block. Like a lego block
#ElementKindComposite: "composite"   // A composite element made up of multiple composite and/or primitive elements
#ElementKindModifier: "modifier"     // A modifier element that alters other elements
#ElementKindCustom: "custom"         // A custom element with special handling
#ElementKinds: #ElementKindPrimitive | #ElementKindComposite | #ElementKindModifier | #ElementKindCustom

// Different element categories
#PrimitiveElements: #PrimitiveTrait | #PrimitiveResource
#CompositeElements: #CompositeTrait | #CompositeResource

// Element map and list types
#Elements: #PrimitiveElements | #CompositeElements
#ElementMap: [string]: #Elements
#ElementList: [...#Elements]

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
	composes: #ElementList

	// Recursively extract all primitive elements from this composite
	#primitiveElements: #ElementMap
	#primitiveElements: {
		// For each element in composes
		for i, element in composes {
			// If it's primitive, add it directly
			if element.kind == "primitive" {
				(element.#name): element
			}
			// If it's composite, merge its primitives
			if element.kind == "composite" {
				for primName, primElement in element.#primitiveElements {
					(primName): primElement
				}
			}
		}
	}
}

// Modifier element - modifies other elements
// Modifies by mutating the output of a component or scope
// Cannot stand alone
#Modifier: #Element & {
	kind: "modifier"

	// Which elements this can modify
	modifies: #ElementList
}

// Custom element - special handling outside of OPM spec
// e.g., raw Kubernetes manifests, Helm charts, etc.
#Custom: #Element & {
	kind: "custom"
}

/////////////////////////////////////////////////////////////////
//// Trait & Resource Bases
/////////////////////////////////////////////////////////////////
#PrimitiveTrait: close(#Primitive & {
	type: "trait"
})

#CompositeTrait: close(#Composite & {
	type: "trait"
})

#PrimitiveResource: close(#Primitive & {
	type: "resource"
})

#CompositeResource: close(#Composite & {
	type: "resource"
})
