package core

// Schema-level pins for component matching and contract fulfilment
// (enhancement 0010 D36, D32, D28). The catalog-selection pins that lived
// here (0010 D37, subscription-shaped) went with #Subscription's removal
// (0019 D5); the import-model delta is exercised by
// enhancements/0019/schemas/examples.cue and re-exercised by the library's
// fixtures when its 0019 wave re-pins.
//
// Companion to identity_pins.cue and written to the same rules: every value
// here is a HIDDEN top-level field, so `cue vet` evaluates them and fails on a
// conflict while an importing package never does, and none of them adds a row
// to src/INDEX.md. MUST-FAIL cases are commented out with the exact error
// uncommenting yields; each was run once, in place, at the commit that
// introduced it, and the recorded text is what the tool printed. Where the
// tool is `cue export` rather than `cue vet` the case says so — a missing
// required field is not vet-visible, which identity_pins.cue documents at
// length and this file inherits.
//
// As there, the filename must NOT begin with an underscore: CUE skips such
// files, and every pin below would then vet clean by never running.
//
// ONE RULE ABOUT THE PIN SHAPE, learned the hard way on this file. A pin MUST
// force evaluation — len(), key indexing, or string interpolation. The
// intuitive `_pin: <expr>` followed by `_pin: <literal>` asserts only that the
// literal is a LEGAL value of the expression, which is always true when the
// expression is an unset required field or a defaulted disjunction. Such a pin
// cannot fail. Measured 2026-08-07: with #Component.matchLabels replaced by
// `{}` — this change's centrepiece deleted — the unification-shaped pin below
// reported its expected values unchanged and `cue vet` exited 0.

// ─── Fixtures: three primitives split across the two label fields ───────────
//
// Values copied in shape from catalog_opm as of 2026-08-01. The three
// categorisation values are the ones that matter: they are what a union of
// metadata.labels collides on, and they must go on coexisting here.

// The container. Declares the workload-type key REQUIRED — the module author
// must pick — which is the marker no filtered union could preserve.
_pinMatchContainer: #Resource & {
	metadata: {
		name:           "container"
		modulePath:     "opmodel.dev/catalogs/opm/resources"
		apiVersion:     "v1beta1"
		catalogVersion: "1.0.0"
		fqn:            "opmodel.dev/catalogs/opm/resources/container@v1beta1"
		labels: "resource.opmodel.dev/category": "workload"
	}
	matchLabels: "opm.opmodel.dev/workload-type"!: "stateless" | "stateful" | "daemon"
	spec: container: image: string
}

// A second resource in a DIFFERENT category, carrying no matching identity.
_pinMatchVolumes: #Resource & {
	metadata: {
		name:           "volumes"
		modulePath:     "opmodel.dev/catalogs/opm/resources"
		apiVersion:     "v1beta1"
		catalogVersion: "1.0.0"
		fqn:            "opmodel.dev/catalogs/opm/resources/volumes@v1beta1"
		labels: "resource.opmodel.dev/category": "storage"
	}
	spec: volumes: [string]: path: string
}

// A trait in a third category. Three categories on one component is what
// `cue vet` refused when matching rode on metadata.labels.
_pinMatchExpose: #Trait & {
	metadata: {
		name:           "expose"
		modulePath:     "opmodel.dev/catalogs/opm/traits"
		apiVersion:     "v1beta1"
		catalogVersion: "1.0.0"
		fqn:            "opmodel.dev/catalogs/opm/traits/expose@v1beta1"
		labels: "trait.opmodel.dev/category": "network"
	}
	optional: bool | *true
	appliesTo: [_pinMatchContainer]
	spec: expose: port: int
}

// The blueprint that ANSWERS the container's required key, and adds a second
// matching key in a namespace `core` does not own — the state the design is
// for, where the vocabulary belongs to the catalog.
_pinMatchStateful: #Blueprint & {
	metadata: {
		name:           "stateful-workload"
		modulePath:     "opmodel.dev/catalogs/opm/blueprints"
		apiVersion:     "v1beta1"
		catalogVersion: "1.0.0"
		fqn:            "opmodel.dev/catalogs/opm/blueprints/stateful-workload@v1beta1"
		labels: "blueprint.opmodel.dev/category": "workload"
	}
	matchLabels: {
		"opm.opmodel.dev/workload-type": "stateful"
		"opm.opmodel.dev/tier":          "data"
	}
	composedResources: [_pinMatchContainer, _pinMatchVolumes]
	spec: statefulWorkload: replicas: int
}

_pinInstanceFixture: #InstanceIdentity & {
	name:      "jellyfin"
	namespace: "media"
	uuid:      "3f2e1d0c-4b5a-6978-8a9b-0c1d2e3f4a5b"
}

// ─── Matching: disjoint labels combine, categories coexist ──────────────────

// One component over all four fixtures — the shape of modules/jellyfin.
_pinMatchComponent: #Component & {
	metadata: name: "jellyfin"
	#resources: {
		container: _pinMatchContainer
		volumes:   _pinMatchVolumes
	}
	#traits: "opmodel.dev/catalogs/opm/traits/expose@v1beta1":                    _pinMatchExpose
	#blueprints: "opmodel.dev/catalogs/opm/blueprints/stateful-workload@v1beta1": _pinMatchStateful
	#instance: _pinInstanceFixture
	spec: {
		container: image: "jellyfin:1"
		volumes: media: path: "/media"
		expose: port:               8096
		statefulWorkload: replicas: 1
	}
}

// The union is wholesale: disjoint keys from a resource and a blueprint
// combine, and the blueprint's answer satisfies the resource's required key.
//
// Read by INDEXING rather than by unifying a literal struct in. `matchLabels &
// {…}` would pass on a component whose matchLabels is empty, because plain
// struct unification ADDS the keys it is handed; indexing a key that is not
// there is `undefined field`, and the count catches a key that should not be.
_pinMatchUnifiedCount: len(_pinMatchComponent.matchLabels)
_pinMatchUnifiedCount: 2
_pinMatchUnified: {
	workloadType: _pinMatchComponent.matchLabels["opm.opmodel.dev/workload-type"]
	tier:         _pinMatchComponent.matchLabels["opm.opmodel.dev/tier"]
}
_pinMatchUnified: {workloadType: "stateful", tier: "data"}

// Three DIFFERENT categorisation values on one component, and no conflict —
// the case that broke every design that unified metadata.labels. Asserted by
// reading each primitive's own label back, since nothing folds them upward.
_pinCategoriesCoexist: [
	_pinMatchComponent.#resources.container.metadata.labels["resource.opmodel.dev/category"],
	_pinMatchComponent.#resources.volumes.metadata.labels["resource.opmodel.dev/category"],
	_pinMatchComponent.#traits["opmodel.dev/catalogs/opm/traits/expose@v1beta1"].metadata.labels["trait.opmodel.dev/category"],
]
_pinCategoriesCoexist: ["workload", "storage", "network"]

// ...and the component's OWN metadata.labels stays untouched by all of it.
// Pinned as a disunification check: the field is absent, not merely empty.
_pinComponentLabelsUnfolded: _pinMatchComponent.metadata.labels == _|_
_pinComponentLabelsUnfolded: true

// ─── Matching identity is not rendered ──────────────────────────────────────

// The context a transformer receives for the component above. componentLabels
// reads #componentMetadata.labels and nothing else, so a matching key can only
// arrive here by being copied — which is what makes the absence checkable.
_pinRenderContext: #TransformerContext & {
	#moduleInstanceMetadata: {
		name:      "jellyfin"
		namespace: "media"
		fqn:       "opmodel.dev/modules/jellyfin:jellyfin:media"
		version:   "1.0.0"
		uuid:      "3f2e1d0c-4b5a-6978-8a9b-0c1d2e3f4a5b"
	}
	#componentMetadata: {
		name: "jellyfin"
		labels: "app.opmodel.dev/team": "media"
	}
	#runtimeName: "opm-cli"
}

// Every matching key the component carries, filtered out of the rendered
// label set. Empty is the assertion: matchLabels reaches no rendered object.
_pinMatchLabelsUnrendered: [
	for k, _ in _pinRenderContext.labels
	if _pinMatchComponent.matchLabels[k] != _|_ {k},
]
_pinMatchLabelsUnrendered: []

// The whole rendered label set, pinned exactly.
//
// THIS PIN IS MASKED ON ITS OWN and the count beneath it is what makes the
// pair effective: #TransformerContext.labels is an OPEN struct, so unifying it
// with five literal keys adds them regardless of what the fold computed. Do
// not delete _pinRenderedLabelsCount as redundant — it is the half that fails.
_pinRenderedLabels: _pinRenderContext.labels & {
	"app.kubernetes.io/name":           "jellyfin"
	"app.kubernetes.io/instance":       "jellyfin"
	"app.kubernetes.io/managed-by":     "opm-cli"
	"module-instance.opmodel.dev/name": "jellyfin"
	"app.opmodel.dev/team":             "media"
}
_pinRenderedLabelsCount: len(_pinRenderContext.labels)
_pinRenderedLabelsCount: 5

// ─── The context is a projection of the other two #transform inputs ─────────
//
// 0019 D12: at the #transform site the context's two metadata blocks compute
// from #moduleInstance and #component; the runtime fills #runtimeName alone.
// Fixture values mirror enhancements/0019/schemas/examples.cue § D12, so the
// landed projection and the enhancement's assertions stay comparable.

// A small instance-shaped value. The projection reads its sources
// structurally (the #moduleInstance slot stays `_`, 0019 D3), so the fixture
// supplies exactly the fields the projection reads. Labels present,
// annotations deliberately ABSENT — the absent-optional pin below rests on
// that, as does the component fixture carrying no labels.
_pinCtxInstance: {
	kind: "ModuleInstance"
	metadata: {
		name:      "shop"
		namespace: "apps"
		fqn:       "opmodel.dev/modules/shop:shop:apps"
		uuid:      "0f8fad5b-d9cb-469f-a165-70867728950e"
		labels: "team.opmodel.dev/owner": "platform"
	}
	#moduleMetadata: version: "1.2.0"
}

_pinCtxComponent: metadata: name: "web"

_pinCtxTransformer: #ComponentTransformer & {
	metadata: {
		name:           "context-projection"
		modulePath:     "opmodel.dev/catalogs/opm/transformers"
		catalogVersion: "1.0.0"
		fqn:            "opmodel.dev/catalogs/opm/transformers/context-projection@1.0.0"
		description:    "Pin fixture for the #transform.#context projection"
	}
	#transform: {
		#moduleInstance: _pinCtxInstance
		#component:      _pinCtxComponent

		// The runtime's whole remaining obligation.
		#context: #runtimeName: "opm-cli"
	}
}

_pinCtx: _pinCtxTransformer.#transform.#context

// Projected from #moduleInstance, with no runtime fill in between.
// Interpolation forces evaluation (the ONE RULE above).
_pinCtxInstanceFields: "\(_pinCtx.#moduleInstanceMetadata.name)|\(_pinCtx.#moduleInstanceMetadata.namespace)|\(_pinCtx.#moduleInstanceMetadata.fqn)|\(_pinCtx.#moduleInstanceMetadata.uuid)|\(_pinCtx.#moduleInstanceMetadata.version)"
_pinCtxInstanceFields: "shop|apps|opmodel.dev/modules/shop:shop:apps|0f8fad5b-d9cb-469f-a165-70867728950e|1.2.0"
_pinCtxInstanceLabel:  _pinCtx.#moduleInstanceMetadata.labels["team.opmodel.dev/owner"]
_pinCtxInstanceLabel:  "platform"

// Projected from #component: metadata.name, the component's own identity.
// The #components-map key is not in scope here and is NEVER the source — a
// runtime that filled the key diverges (see the must-fail case below).
_pinCtxComponentName: "\(_pinCtx.#componentMetadata.name)"
_pinCtxComponentName: "web"

// The label folds were already projections of the two metadata blocks, so
// they follow with no further wiring. Read by indexing, not unification.
_pinCtxControllerLabels: {
	managedBy: _pinCtx.controllerLabels["app.kubernetes.io/managed-by"]
	name:      _pinCtx.controllerLabels["app.kubernetes.io/name"]
	instance:  _pinCtx.controllerLabels["app.kubernetes.io/instance"]
}
_pinCtxControllerLabels: {managedBy: "opm-cli", name: "web", instance: "web"}

// The whole rendered label set, by count — labels is an OPEN struct, so a
// literal-unification pin is masked (see _pinRenderedLabelsCount above):
// moduleLabels contributes team.opmodel.dev/owner; componentLabels
// app.kubernetes.io/name + module-instance.opmodel.dev/name; controllerLabels
// managed-by + instance (name shared) = 5 distinct keys.
_pinCtxRenderedLabelsCount: len(_pinCtx.labels)
_pinCtxRenderedLabelsCount: 5

// Absent optional sources project as ABSENT — not as errors, not as empty
// structs. The instance fixture carries no annotations and the component
// fixture no labels; both stay missing on the context. Pinned as
// disunification checks, the shape _pinComponentLabelsUnfolded established.
_pinCtxInstanceAnnotationsAbsent: _pinCtx.#moduleInstanceMetadata.annotations == _|_
_pinCtxInstanceAnnotationsAbsent: true
_pinCtxComponentLabelsAbsent:     _pinCtx.#componentMetadata.labels == _|_
_pinCtxComponentLabelsAbsent:     true

// ─── Fulfilment ─────────────────────────────────────────────────────────────

// The default. A primitive that never mentions the field is catalog-fulfilled,
// so nothing opts in by accident.
_pinFulfilmentDefault: "\(_pinMatchContainer.fulfilment)"
_pinFulfilmentDefault: "catalog"

// The declaration this exists for: a catalog declares `backup` (hypothetical;
// no catalog ships it today) and nothing renders it. Today that is
// indistinguishable from an oversight.
_pinProviderFulfilledTrait: #Trait & {
	metadata: {
		name:           "backup"
		modulePath:     "opmodel.dev/catalogs/opm/traits"
		apiVersion:     "v1beta1"
		catalogVersion: "1.0.0"
		fqn:            "opmodel.dev/catalogs/opm/traits/backup@v1beta1"
	}
	fulfilment: "provider"
	optional:   bool | *false
	appliesTo: [_pinMatchContainer]
	spec: backup: schedule: string
}
_pinProviderFulfilment: "\(_pinProviderFulfilledTrait.fulfilment)"
_pinProviderFulfilment: "provider"

// ─── Demand-side optionality ────────────────────────────────────────────────

// The catalog's posture, stated as a DEFAULT so it recommends rather than
// rules. `backup` is load-bearing, `expose` is advisory.
_pinTraitPostureRequired: "\(_pinProviderFulfilledTrait.optional)"
_pinTraitPostureRequired: "false"
_pinTraitPostureAdvisory: "\(_pinMatchExpose.optional)"
_pinTraitPostureAdvisory: "true"

// THE PROPERTY THE WHOLE SHAPE EXISTS FOR: a module overrides the catalog at
// the attachment site, in BOTH directions, and neither is a conflict. This is
// what a concrete value on the trait would have made impossible.
_pinOptionalTraitComponent: #Component & {
	metadata: name:        "jellyfin"
	#resources: container: _pinMatchContainer
	#traits: {
		// the catalog says required; this component can do without it
		"opmodel.dev/catalogs/opm/traits/backup@v1beta1": _pinProviderFulfilledTrait & {optional: true}
		// the catalog says advisory; this component insists on it
		"opmodel.dev/catalogs/opm/traits/expose@v1beta1": _pinMatchExpose & {optional: false}
	}
	#blueprints: "opmodel.dev/catalogs/opm/blueprints/stateful-workload@v1beta1": _pinMatchStateful
	#instance: _pinInstanceFixture
	spec: {
		container: image:           "jellyfin:1"
		backup: schedule:           "@daily"
		expose: port:               8096
		statefulWorkload: replicas: 1
	}
}
_pinTraitOptOutAtAttachment: "\(_pinOptionalTraitComponent.#traits["opmodel.dev/catalogs/opm/traits/backup@v1beta1"].optional)"
_pinTraitOptOutAtAttachment: "true"
_pinTraitOptInAtAttachment:  "\(_pinOptionalTraitComponent.#traits["opmodel.dev/catalogs/opm/traits/expose@v1beta1"].optional)"
_pinTraitOptInAtAttachment:  "false"

// ...and the catalog's own value is untouched by either override — the
// attachment narrows a copy, not the shipped definition.
_pinTraitPostureUnmoved: "\(_pinProviderFulfilledTrait.optional)"
_pinTraitPostureUnmoved: "false"

// ─── The publish gate ───────────────────────────────────────────────────────
//
// Both fixtures state a posture as a default, so both pass.
//
// THESE PINS ARE HIDDEN, WHICH COSTS RULE 1 ITS TEETH HERE, and the trade is
// deliberate. The gate must be unified into a NON-hidden value to be checked
// by `cue vet -c` — but a non-hidden top-level field in this package SHIPS to
// every consumer of the published module, and this file's whole premise is
// that an importing package evaluates none of it. So publish gets the
// non-hidden application (see #TraitOptionalGate's doc comment) and this file
// keeps the hidden one: rule 2 is still gated here, because it is visible
// under plain vet, and rule 1 is recorded as a MUST-FAIL case below with the
// command it was measured with.
_pinGateTraitPostureRequired: #TraitOptionalGate & {optional: _pinProviderFulfilledTrait.optional}
_pinGateTraitPostureAdvisory: #TraitOptionalGate & {optional: _pinMatchExpose.optional}

// ─── MUST-FAIL: the two rules the gate exists for ───────────────────────────

// RULE 2 — a catalog PINS `optional` to a concrete value. No module could ever
// override it, so the catalog would decide for everyone. Visible under plain
// `cue vet`, because both arms of the check are concrete booleans:
//   _failGatePinned._overridable: conflicting values false and true
//
//  _failPinnedOptional: #Trait & {
//   metadata: {
//    name:           "security-context"
//    modulePath:     "opmodel.dev/catalogs/opm/traits"
//    apiVersion:     "v1beta1"
//    catalogVersion: "1.0.0"
//    fqn:            "opmodel.dev/catalogs/opm/traits/security-context@v1beta1"
//   }
//   optional: false
//   appliesTo: [_pinMatchContainer]
//   spec: securityContext: runAsUser: int
//  }
//  _failGatePinned: #TraitOptionalGate & {optional: _failPinnedOptional.optional}

// RULE 1 — a catalog never states a posture at all. THE THIRD CASE IN THIS
// REPO THAT PLAIN `cue vet` DOES NOT REPORT, and the one that dictates how
// publish invokes the gate. Measured 2026-08-07 against cue v0.17.1:
//
//   $ cue vet ./...        # exits 0 — nothing reported
//   $ cue vet -c ./...
//   failGateUnstated.optional: incomplete value bool
//
// TWO CONDITIONS, both required. The `-c` flag, because an unstated posture is
// an INCOMPLETE value rather than a wrong one. And a NON-HIDDEN application —
// note the case below is `failGateUnstated`, not `_failGateUnstated` — because
// `cue vet -c` does not check hidden fields, so the same case parked in a
// `_`-prefixed slot exits 0 and gates nothing. That is why the positive gate
// pins above are hidden and this one is not, and why the gate's own doc
// comment states the requirement rather than leaving it to be rediscovered.
//
//  _failUnstatedOptional: #Trait & {
//   metadata: {
//    name:           "expose-unstated"
//    modulePath:     "opmodel.dev/catalogs/opm/traits"
//    apiVersion:     "v1beta1"
//    catalogVersion: "1.0.0"
//    fqn:            "opmodel.dev/catalogs/opm/traits/expose-unstated@v1beta1"
//   }
//   appliesTo: [_pinMatchContainer]
//   spec: exposeUnstated: port: int
//  }
//  failGateUnstated: #TraitOptionalGate & {optional: _failUnstatedOptional.optional}

// ─── MUST-FAIL cases ────────────────────────────────────────────────────────

// Two primitives disagreeing on ONE matching key. This is the error the
// design wants to be possible: a real modelling conflict, named at the key,
// rather than an artifact of unrelated labels sharing a namespace. Vet-visible
// because the container's required disjunction is narrowed to nothing — the
// error is reported once per surviving disjunct, and both name the key:
//   _failMatchLabelConflict._matchLabelsFromPrimitives."opm.opmodel.dev/workload-type":
//     2 errors in empty disjunction:
//   _failMatchLabelConflict._matchLabelsFromPrimitives."opm.opmodel.dev/workload-type":
//     conflicting values "daemon" and "stateful"
//   _failMatchLabelConflict._matchLabelsFromPrimitives."opm.opmodel.dev/workload-type":
//     conflicting values "stateless" and "stateful"
//
// Reported against the HIDDEN union rather than against matchLabels: the two
// blueprints meet there first, so the conflict is caught at its source. The
// public field never forms. (_failBareContainer below still reports against
// matchLabels, because a required field that is merely unanswered does form.)
//
//  _failDaemonBlueprint: #Blueprint & {
//   metadata: {
//    name:           "daemon-workload"
//    modulePath:     "opmodel.dev/catalogs/opm/blueprints"
//    apiVersion:     "v1beta1"
//    catalogVersion: "1.0.0"
//    fqn:            "opmodel.dev/catalogs/opm/blueprints/daemon-workload@v1beta1"
//   }
//   matchLabels: "opm.opmodel.dev/workload-type": "daemon"
//   composedResources: [_pinMatchContainer]
//   spec: daemonWorkload: hostNetwork: bool
//  }
//
//  _failMatchLabelConflict: #Component & {
//   metadata: name: "clash"
//   #resources: container: _pinMatchContainer
//   #blueprints: {
//    stateful: _pinMatchStateful
//    daemon:   _failDaemonBlueprint
//   }
//   #instance: _pinInstanceFixture
//  }

// A component that INVENTS a matching key of its own. matchLabels is derived —
// it is exactly the unification of the attached primitives' — so a key that
// traces to no primitive is refused. This is the rule that makes a component
// fragment a pure wrapper structural rather than conventional, and it binds
// every #Component because CUE cannot tell a catalog fragment from a module
// author's component: both are #Component values.
//
// Reported through the derivation check rather than at the key, because the
// key itself is legal — what is illegal is where it came from:
//   _failAuthoredMatchLabel._matchLabelsAreDerived:
//     conflicting values false and true
//
// `close()` around the union does NOT produce this refusal (measured, cue
// v0.17.1) — it admits the key silently, which is why the check is a size
// comparison rather than the obvious spelling.
//
//  _failAuthoredMatchLabel: #Component & {
//   metadata: name: "invented"
//   #resources: container: _pinMatchContainer
//   #blueprints: "opmodel.dev/catalogs/opm/blueprints/stateful-workload@v1beta1": _pinMatchStateful
//   matchLabels: "fragment.opmodel.dev/invented": "yes"
//   #instance: _pinInstanceFixture
//   spec: {
//    container: image:           "jellyfin:1"
//    statefulWorkload: replicas: 1
//   }
//  }

// The same refusal from the other side: a component ANSWERING a required
// matching key inline instead of attaching a blueprint that answers it. The
// key is one a primitive declared, so nothing about the value is wrong — it
// still fails, because a component contributes no matching identity at all:
//   _failInlineAnsweredMatchLabel._matchLabelsAreDerived:
//     conflicting values false and true
//
// This is the accepted cost of the rule binding every #Component. It was
// measured against the fleet before being taken: `modules/**` carries ZERO
// hand-set matching labels — every module composes a workload blueprint and
// inherits — so the hatch this closes is one nobody uses. A module that needs
// to answer the key attaches the blueprint that answers it.
//
//  _failInlineAnsweredMatchLabel: #Component & {
//   metadata: name: "answered"
//   #resources: container: _pinMatchContainer
//   matchLabels: "opm.opmodel.dev/workload-type": "daemon"
//   #instance: _pinInstanceFixture
//   spec: container: image: "jellyfin:1"
//  }

// A REQUIRED matching key that no attached primitive answers. The property no
// filtered union could preserve: every iterating design had to drop the `!`,
// which turned "the author must pick a workload type" into an incomplete value
// that rendered. Not vet-visible — measured 2026-08-07 against cue v0.17.1,
// `cue vet ./...` and `cue vet -c ./...` both exit 0 — but unlike the
// subscription case above, matchLabels is a REGULAR field, so ordinary
// concrete evaluation of the component reaches it:
//
//   $ cue export -e '_failBareContainer' ./...
//   _failBareContainer.matchLabels."opm.opmodel.dev/workload-type":
//     field is required but not present
//
// A missing REQUIRED FIELD is the whole point of the recorded error: an
// incomplete value would render.
//
//  _failBareContainer: #Component & {
//   metadata: name: "bare"
//   #resources: container: _pinMatchContainer
//   #instance: _pinInstanceFixture
//   spec: container: image: "jellyfin:1"
//  }

// fulfilment on a #Blueprint. The exclusion is STRUCTURAL — a transformer
// declares requiredResources and requiredTraits and has no blueprint
// equivalent, so nothing can demand a blueprint — and `field not allowed` is
// what proves it, rather than a field nothing reads:
//   _failBlueprintFulfilment.fulfilment: field not allowed
//
//  _failBlueprintFulfilment: #Blueprint & {
//   metadata: {
//    name:           "stateless-workload"
//    modulePath:     "opmodel.dev/catalogs/opm/blueprints"
//    apiVersion:     "v1beta1"
//    catalogVersion: "1.0.0"
//    fqn:            "opmodel.dev/catalogs/opm/blueprints/stateless-workload@v1beta1"
//   }
//   fulfilment: "provider"
//   composedResources: [_pinMatchContainer]
//   spec: statelessWorkload: replicas: int
//  }

// A third fulfilment mode. The enum is closed, so a value outside it is a
// validation failure rather than something the kernel ignores — which is what
// a boolean `providedExternally` could not have given without a later
// breaking rename:
//   _failThirdFulfilment.fulfilment: 2 errors in empty disjunction:
//   _failThirdFulfilment.fulfilment: conflicting values "catalog" and "external"
//   _failThirdFulfilment.fulfilment: conflicting values "provider" and "external"
//
//  _failThirdFulfilment: #Trait & {
//   metadata: {
//    name:           "backup"
//    modulePath:     "opmodel.dev/catalogs/opm/traits"
//    apiVersion:     "v1beta1"
//    catalogVersion: "1.0.0"
//    fqn:            "opmodel.dev/catalogs/opm/traits/backup@v1beta1"
//   }
//   fulfilment: "external"
//   appliesTo: [_pinMatchContainer]
//   spec: backup: schedule: string
//  }

// ─── MUST-FAIL: a divergent runtime fill loses to the projection ────────────

// The transitional contract (SPEC.md § 4.1): a staged runtime MAY keep filling
// the projected fields with IDENTICAL values (unification agrees, a no-op —
// #runtimeName above is exactly such a fill), and a DIVERGENT fill is a
// conflict at the field, never a silent win. This case is the key-fill drift
// measured on modules/k8up ("manager-cluster-role" vs "k8up-manager"): a
// runtime sourcing the component name from the #components-map key instead of
// metadata.name. Run once in place, cue v0.17.1, plain `cue vet`:
//   _failCtxDivergentFill.#transform.#context.#componentMetadata.name:
//     conflicting values "web" and "frontend"
// The instance-side twin was measured in the same run shape:
//   _failCtxDivergentFill.#transform.#context.#moduleInstanceMetadata.name:
//     conflicting values "shop" and "renamed"
//
//  _failCtxDivergentFill: _pinCtxTransformer & {
//   #transform: #context: #componentMetadata: name: "frontend"
//  }

// ─── MUST-FAIL: a render without a runtime name refuses ─────────────────────

// Both inputs filled, no #runtimeName: the one context field the projection
// cannot compute. A MISSING REQUIRED FIELD, so per this file's header it is
// not vet-visible (`cue vet ./...` and `cue vet -c ./...` both exit 0,
// measured 2026-09-01, cue v0.17.1) and #context is HIDDEN, so the field must
// be named. Note the projection itself evaluates — both metadata blocks
// compute; only #runtimeName and the managed-by fold that reads it fail:
//
//   $ cue export -e '_failCtxNoRuntimeName.#transform.#context' ./...
//   _failCtxNoRuntimeName.#transform.#context.#runtimeName:
//     field is required but not present
//   _failCtxNoRuntimeName.#transform.#context.controllerLabels."app.kubernetes.io/managed-by":
//     required field missing: #runtimeName
//   _failCtxNoRuntimeName.#transform.#context.controllerLabels."app.kubernetes.io/managed-by":
//     invalid interpolation: required field missing: #runtimeName
//
// Which is what a kernel does — render reads the context concretely — so the
// error reaches the caller that matters. Do not add a pin that appears to
// check it; there is no vet-visible form.
//
//  _failCtxNoRuntimeName: #ComponentTransformer & {
//   metadata: {
//    name:           "context-projection-no-runtime"
//    modulePath:     "opmodel.dev/catalogs/opm/transformers"
//    catalogVersion: "1.0.0"
//    fqn:            "opmodel.dev/catalogs/opm/transformers/context-projection-no-runtime@1.0.0"
//    description:    "Must-fail fixture: both inputs filled, no #runtimeName"
//   }
//   #transform: {
//    #moduleInstance: _pinCtxInstance
//    #component:      _pinCtxComponent
//   }
//  }
