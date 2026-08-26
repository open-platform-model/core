package core

#Component: {
	kind: "Component"

	metadata: {
		name!: #NameType

		// Per-component resource-name override. Defaults to the
		// instance-qualified name `<instance>-<component>` (enhancement 0019
		// D16), the name every rendered primary object already carries; an
		// explicit value wins via the disjunction-default cascade. #names reads
		// from here to compute the rendered resource name and its DNS variants
		// (enhancement 0001 D2).
		//
		// The override's ceiling is #ObjectNameType (0019 D20): a DNS subdomain,
		// dots admitted, 253 runes, because that is what the kinds most
		// components render accept for metadata.name. The default can never
		// carry a dot or exceed 127 runes, since both halves are #NameType
		// labels; only an explicit override can meet a dot-hostile primitive's
		// #nameConstraint, asserted by _nameFits below.
		//
		// The default branch is deliberately NOT unified with a type: on cue
		// v0.17.1 a failed validated default degrades to a bare `incomplete
		// value` that never names the offending string. The error() arm is
		// reported only when every other arm fails, replacing the nested
		// empty-disjunction output an explicit invalid name would otherwise
		// produce.
		resourceName: *"\(#instance.name)-\(name)" | #ObjectNameType | error("resourceName \"\(resourceName)\" is not a DNS subdomain (lowercase alphanumerics, hyphens and dots, 1-253 runes)")

		// Component labels — descriptive metadata for this component, and the
		// labels that reach rendered output via #TransformerContext.
		//
		// NOT unified from the attached primitives, and nothing matches on
		// them. Both claims were here and both were false: no CUE in this
		// definition performed the union, and the kernel reads this field off
		// the component rather than folding it up from below. Matching now
		// has its own field — see matchLabels (enhancement 0010 D36).
		labels?: #LabelsAnnotationsType

		// Component annotations — descriptive metadata for this component.
		// Not unified from the attached primitives either, for the same
		// reason.
		annotations?: #LabelsAnnotationsType
	}

	// Resources applied for this component
	#resources: #ResourceMap

	// Traits applied to this component
	#traits?: #TraitMap

	// Blueprints applied to this component
	#blueprints?: #BlueprintMap

	// NO demand-side optionality marker for RESOURCES, and the absence is a
	// decision (D28): a component does not attach a resource it can do
	// without. Every declared resource is a demand the platform must satisfy,
	// and an unsupplied one fails the render. Traits differ because a trait
	// can be advisory — it modifies something that renders regardless.

	// This component's MATCHING identity: the wholesale unification of every
	// attached primitive's matchLabels. No filter, no key list, no prefix
	// rule — every key a primitive puts there exists to be matched on, so
	// there is nothing to select between. `metadata.labels` is NOT unified
	// upward (see there); the two fields never meet.
	//
	// A component contributes NOTHING here of its own — see the derivation
	// check below, which is what makes that structural rather than a
	// convention. Every key traces to a primitive, which is what puts the
	// matching label under the primitive's own additive-only promise instead
	// of under a wrapper nobody versions.
	//
	// The comprehension iterates the attachment MAPS and embeds each
	// primitive's matchLabels struct whole — it never iterates the labels
	// themselves. That distinction is the whole design: CUE refuses to
	// iterate a struct holding an unset required field, so a `for k, v`
	// over the labels would force every primitive to drop `!` from the key a
	// module author must answer. Embedded wholesale, the marker survives and
	// an unanswered key is reported as a missing required field.
	//
	// Measured in enhancement 0010 experiment 04 (D36).
	//
	// The union itself is hidden, because it is the PROVENANCE of the public
	// field rather than a second value a consumer reads: matchLabels IS this,
	// and the check underneath is what keeps it exactly this.
	_matchLabelsFromPrimitives: {
		for _, resource in #resources {
			if resource.matchLabels != _|_ {resource.matchLabels}
		}
		if #traits != _|_ {
			for _, trait in #traits {
				if trait.matchLabels != _|_ {trait.matchLabels}
			}
		}
		if #blueprints != _|_ {
			for _, blueprint in #blueprints {
				if blueprint.matchLabels != _|_ {blueprint.matchLabels}
			}
		}
	}
	matchLabels: _matchLabelsFromPrimitives

	// matchLabels is DERIVED, and this is the enforcement. Unification can
	// only ever ADD to matchLabels, so a size difference is exactly "this
	// component contributed a key of its own" — whether it invented one or
	// answered a required one inline.
	//
	// IF THIS FIRES: put the key on the primitive that owns it, or attach a
	// blueprint that answers it. A matching key written on a component — or on
	// a catalog FRAGMENT, which is the same type, and which is why this binds
	// every #Component rather than only fragments — sits outside the
	// additive-only promise its contract key gates.
	//
	// `close()` around the union does NOT do this. Measured against cue
	// v0.17.1: a closed comprehension still admits an authored key, so the
	// obvious spelling would read as enforcement while enforcing nothing.
	_matchLabelsAreDerived: len(matchLabels) == len(_matchLabelsFromPrimitives)
	_matchLabelsAreDerived: true

	// Instance context injected by the parent #Module via its #components
	// pattern constraint. Hidden definition slot — module authors never set
	// this directly. Introduced by enhancement 0001 (D3).
	//
	// Was: #release: #ReleaseIdentity (renamed in enhancement 0002)
	#instance: #InstanceIdentity

	// Every attached primitive's #nameConstraint, unified into one conjunction
	// (enhancement 0019 D21); top when none declares one. Collected
	// UNCONDITIONALLY — comprehensions over the three attachment maps, no
	// existence guard — because on cue v0.17.1 `x.#nameConstraint != _|_` is
	// false for a non-concrete value and a guarded spelling silently never
	// propagates (0019 experiment 09). Unifying top is the identity, so an
	// indifferent primitive costs nothing.
	//
	// COST: this is a second walk over the attachment maps beside
	// _matchLabelsFromPrimitives, paid per component at every evaluation.
	// Measured (0019 experiment 12, cue v0.17.1): 0.15-0.22 ms per component,
	// linear in component count, the walk itself rather than any primitive's
	// conditional; 0.5-2% of the per-component render cost experiment 07
	// measured. Small today, but it scales with components times attached
	// primitives, so a module with many components each attaching many
	// primitives pays it in full on every render. If render times grow with
	// module complexity, re-measure this walk before the transformers.
	_nameConstraints: _
	for _, resource in #resources {_nameConstraints: resource.#nameConstraint}
	if #traits != _|_ {
		for _, trait in #traits {_nameConstraints: trait.#nameConstraint}
	}
	if #blueprints != _|_ {
		for _, blueprint in #blueprints {_nameConstraints: blueprint.#nameConstraint}
	}

	// The assertion: the RESOLVED resourceName satisfies every attached
	// constraint. Refuses naming the string, the violated bound and the
	// constraint type's definition site. Two spellings that read as
	// equivalent are wrong, both measured on cue v0.17.1 (0019 experiment 11):
	//
	//   - Unifying _nameConstraints into metadata.resourceName, or writing
	//     `metadata.resourceName & _nameConstraints` here WITHOUT the
	//     interpolation: the constraint distributes into the disjunction's
	//     default arm, a default that fails it drops out, and the value is a
	//     bare non-concrete constraint. Unified into the field that surfaces
	//     as an illegible `non-concrete value` error; on this hidden field it
	//     surfaces as NOTHING — every default-arm refusal is silently admitted.
	//     The interpolation forces the default to a string first, and
	//     `string & C` is either that string or an error naming it.
	//   - Wrapping this in `if (... & C) == _|_ { _x: error(...) }` to add a
	//     remedy sentence: `(incomplete & C) == _|_` is TRUE while
	//     #instance.name is unresolved, so the guard fires on this bare
	//     definition and every consumer refuses.
	//
	// So the diagnostic cannot name the attached primitive or a remedy; the
	// type site in the trace (#NameType, #ServiceNameType) is the pointer.
	_nameFits: "\(metadata.resourceName)" & _nameConstraints

	// Single source of truth for this component's computed names. `resourceName`
	// reads straight from metadata (cascade lives there); DNS variants derive
	// deterministically from resourceName + #instance.namespace + #instance.clusterDomain.
	// Introduced by enhancement 0001 (D2). #Module.#ctx.components projects this
	// block automatically; authors writing self-references inside a component's
	// `spec` body MUST go through `#ctx.components.<self-id>.dns.fqdn` because
	// `#names` is not in lexical scope under the spec definition block.
	#names: {
		resourceName: metadata.resourceName
		dns: {
			short: resourceName
			local: "\(resourceName).\(#instance.namespace)"
			fqdn:  "\(resourceName).\(#instance.namespace).svc.\(#instance.clusterDomain)"
		}
	}

	_allFields: {
		for _, resource in #resources {
			if resource.spec != _|_ {resource.spec}
		}
		if #traits != _|_ {
			for _, trait in #traits {
				if trait.spec != _|_ {trait.spec}
			}
		}
		if #blueprints != _|_ {
			for _, blueprint in #blueprints {
				if blueprint.spec != _|_ {blueprint.spec}
			}
		}
	}

	// Fields exposed by this component (merged from all resources, traits, and blueprints)
	// Automatically turned into a spec.
	// Must be made concrete by the user.
	// Have to do it this way because if we allowed the spec flattened in the root of the component
	// we would have to open the #Module definition which would make it impossible to properly validate.
	spec: close({
		_allFields
	})
}

#ComponentMap: [string]: #Component
