package core

/////////////////////////////////////////////////////////////////
//// Element Definition
/////////////////////////////////////////////////////////////////
#Element: {
	#name!:              string
	#apiVersion:         string | *"core.opm.dev/v1alpha1"
	#fullyQualifiedName: "\(#apiVersion).\(#name)"

	// Human-readable description of the element
	description?: string

	// Optional metadata labels for categorization and filtering
	labels?: #LabelsAnnotationsType

	// The type of this element
	type!: "trait" | "resource" | "policy"

	// kind of element
	kind!: "primitive" | "composite" | "modifier" | "custom"

	// Where can element be applied
	// Can be one or more of "component", "scope"
	target!: ["component"] | ["scope"] | ["component", "scope"]

	// MUST be an OpenAPIv3 compatible schema
	// TODO: Add validation to only allow one named struct per trait
	#schema!: _
	...
}

#ElementBase: {
	#elements: [elementName=string]: #Element & {#name!: elementName}
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
	composes: [...#Element]
}

// Modifier element - modifies other elements
// Modifies by mutating the output of a component or scope
// Cannot stand alone
#Modifier: #Element & {
	kind: "modifier"

	// Which elements this can modify
	modifies: [...#Element]
}

// Custom element - special handling outside of OPM spec
// e.g., raw Kubernetes manifests, Helm charts, etc.
#Custom: #Element & {
	kind: "custom"
}

/////////////////////////////////////////////////////////////////
//// Trait & Resource Bases
/////////////////////////////////////////////////////////////////
#PrimitiveTrait: #Primitive & {
	type: "trait"
	kind: "primitive"
}

#CompositeTrait: #Composite & {
	type: "trait"
	kind: "composite"
}

#PrimitiveResource: #Primitive & {
	type: "resource"
	kind: "primitive"
}

#CompositeResource: #Composite & {
	type: "resource"
	kind: "composite"
}
