package core

#Component: {
	kind: "Component"

	metadata: {
		name!: #NameType

		// Per-component resource-name override. Defaults to metadata.name; an
		// explicit value wins via the disjunction-default cascade. Introduced by
		// enhancement 0001 (D2): #names reads from here to compute the rendered
		// resource name and its DNS variants.
		resourceName: *name | #NameType

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

	// Trait demands this component can do without. A key here names a trait
	// this component attaches — the same #ContractFQNType the #traits map is
	// keyed by — and says the render MAY continue when no materialized
	// transformer handles it, with a warning naming the trait. Absence is the
	// only spelling of "required": there is no `false`, so a trait cannot be
	// marked required twice or un-marked by a later unification.
	//
	// Enhancement 0010 D28 fixes that there is exactly ONE opt-out, that it
	// lives on the DEMAND side, and that its absence means required. The
	// spelling is this change's: a marker SET beside the attachment map,
	// rather than a second attachment map or a field on #Trait.
	//
	//   - Not a field on #Trait: a trait definition is shipped by a catalog
	//     and shared across every component that attaches it, so optionality
	//     declared there is a SUPPLY-side statement about somebody else's
	//     component. `optionalTraits` on #ComponentTransformer is the supply
	//     side and already exists; this is its demand-side counterpart.
	//   - Not a second attachment map: catalogs ship component FRAGMENTS that
	//     attach traits into #traits, and a module author who wants one of
	//     them optional cannot move where the fragment put it. A marker set
	//     is writable beside a fragment; a rival map is not.
	//   - Not a list: two fragments unifying into one component would fail on
	//     list unification, while map keys merge. A set is also the shape
	//     that makes a duplicate marker a no-op rather than an error.
	//
	// The cost is that the FQN is written twice — once to attach, once to
	// mark. A mistyped key marks nothing, and the trait it meant to excuse
	// stays required, so the mistake surfaces as the render failure it was
	// trying to avoid rather than as a silent downgrade.
	//
	// Enforced by the kernel, which is what reports an unhandled trait; the
	// schema states the intent.
	#optionalTraits?: [#ContractFQNType]: true

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
