package core

// Schema-level pins for catalog selection, component matching and contract
// fulfilment (enhancement 0010 D36, D37, D32, D28).
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
	appliesTo: [_pinMatchContainer]
	spec: expose: port: int
}

// The blueprint that ANSWERS the container's required key, and adds a second
// matching key in a namespace `core` does not own — the state the design is
// for, where the vocabulary belongs to the catalog.
_pinMatchStateful: #Blueprint & {
	metadata: {
		name:           "stateful-workload"
		modulePath:     "opmodel.dev/catalogs/opm/blueprints/workload"
		apiVersion:     "v1beta1"
		catalogVersion: "1.0.0"
		fqn:            "opmodel.dev/catalogs/opm/blueprints/workload/stateful-workload@v1beta1"
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
	#traits: "opmodel.dev/catalogs/opm/traits/expose@v1beta1":                             _pinMatchExpose
	#blueprints: "opmodel.dev/catalogs/opm/blueprints/workload/stateful-workload@v1beta1": _pinMatchStateful
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

// ─── Fulfilment ─────────────────────────────────────────────────────────────

// The default. A primitive that never mentions the field is catalog-fulfilled,
// so nothing opts in by accident.
_pinFulfilmentDefault: "\(_pinMatchContainer.fulfilment)"
_pinFulfilmentDefault: "catalog"

// The declaration this exists for: catalog_opm declares `backup` and ships
// nothing that renders it. Today that is indistinguishable from an oversight.
_pinProviderFulfilledTrait: #Trait & {
	metadata: {
		name:           "backup"
		modulePath:     "opmodel.dev/catalogs/opm/traits"
		apiVersion:     "v1beta1"
		catalogVersion: "1.0.0"
		fqn:            "opmodel.dev/catalogs/opm/traits/backup@v1beta1"
	}
	fulfilment: "provider"
	appliesTo: [_pinMatchContainer]
	spec: backup: schedule: string
}
_pinProviderFulfilment: "\(_pinProviderFulfilledTrait.fulfilment)"
_pinProviderFulfilment: "provider"

// ─── Demand-side optionality ────────────────────────────────────────────────

// A component that can do without its backup trait. The marker names the same
// contract key the attachment is keyed by; the value has one legal spelling.
_pinOptionalTraitComponent: #Component & {
	metadata: name:                                                                        "jellyfin"
	#resources: container:                                                                 _pinMatchContainer
	#traits: "opmodel.dev/catalogs/opm/traits/backup@v1beta1":                             _pinProviderFulfilledTrait
	#optionalTraits: "opmodel.dev/catalogs/opm/traits/backup@v1beta1":                     true
	#blueprints: "opmodel.dev/catalogs/opm/blueprints/workload/stateful-workload@v1beta1": _pinMatchStateful
	#instance: _pinInstanceFixture
	spec: {
		container: image:           "jellyfin:1"
		backup: schedule:           "@daily"
		statefulWorkload: replicas: 1
	}
}
_pinOptionalTraitMarked: "\(_pinOptionalTraitComponent.#optionalTraits["opmodel.dev/catalogs/opm/traits/backup@v1beta1"])"
_pinOptionalTraitMarked: "true"

// Absence is the only spelling of "required": an unmarked trait has no entry,
// rather than an entry reading false.
_pinUnmarkedTraitAbsent: _pinMatchComponent.#optionalTraits == _|_
_pinUnmarkedTraitAbsent: true

// ─── Subscription: one build, named ─────────────────────────────────────────

_pinPlatform: #Platform & {
	metadata: name: "prod"
	type: "kubernetes"
	#registry: {
		// A release.
		"opmodel.dev/catalogs/opm@v1": version: "1.2.0"

		// A PRERELEASE, selected with no flag and no maturity inference — it
		// is selected by being written down. Both mainline catalogs publish
		// 1.0.0-alpha.* today, so this is the fleet's normal case.
		"opmodel.dev/catalogs/kubernetes@v1": version: "1.0.0-alpha.2"

		// enable is unchanged and still defaults to true.
		"opmodel.dev/catalogs/legacy@v1": {
			version: "0.9.0"
			enable:  false
		}
	}
}

_pinSubscriptionRelease:    "\(_pinPlatform.#registry["opmodel.dev/catalogs/opm@v1"].version)"
_pinSubscriptionRelease:    "1.2.0"
_pinSubscriptionPrerelease: "\(_pinPlatform.#registry["opmodel.dev/catalogs/kubernetes@v1"].version)"
_pinSubscriptionPrerelease: "1.0.0-alpha.2"
_pinSubscriptionEnabled:    "\(_pinPlatform.#registry["opmodel.dev/catalogs/opm@v1"].enable)"
_pinSubscriptionEnabled:    "true"

// Two builds of one catalog is TWO PLATFORMS, and the map key is what makes
// the alternative inexpressible rather than merely discouraged: a second
// subscription under the same path unifies with the first, so declaring
// "1.2.0" and "1.3.0" for one catalog is a conflict, not a second channel.
_pinOneBuildPerPath: "\((_pinPlatform.#registry & {
	"opmodel.dev/catalogs/opm@v1": version: "1.2.0"
})["opmodel.dev/catalogs/opm@v1"].version)"
_pinOneBuildPerPath: "1.2.0"

// ─── MUST-FAIL cases ────────────────────────────────────────────────────────

// A subscription carrying the deleted filter. Reported as closedness rather
// than as a bad value: #Subscription is a definition, so the field does not
// exist to be wrong:
//   _failSubscriptionFilter.#registry."opmodel.dev/catalogs/opm@v1".filter:
//     field not allowed
//
//  _failSubscriptionFilter: #Platform & {
//   metadata: name: "prod"
//   type: "kubernetes"
//   #registry: "opmodel.dev/catalogs/opm@v1": {
//    version: "1.2.0"
//    filter: range: ">=1.0.0 <2.0.0"
//   }
//  }

// Two builds of ONE catalog. Not two channels — a conflict, because the map
// key is the catalog path and CUE collapses two declarations under one key:
//   _failTwoBuildsOnePath."opmodel.dev/catalogs/opm@v1".version:
//     conflicting values "1.2.0" and "1.3.0"
//
//  _failTwoBuildsOnePath: _pinPlatform.#registry & {
//   "opmodel.dev/catalogs/opm@v1": version: "1.3.0"
//  }

// A subscription with no version — the shape every live platform has today,
// and the one this change refuses. A MISSING REQUIRED FIELD, which
// identity_pins.cue documents at length is not vet-visible: measured
// 2026-08-07 against cue v0.17.1, `cue vet ./...` and `cue vet -c ./...` both
// exit 0, and `cue eval` prints the field back as an unsatisfied constraint
// (`version!: =~"^\d+\.\d+\.\d+…"`) rather than as an error.
//
// This case needs one thing more than that precedent, worth recording because
// it looks like a second bug otherwise: #registry is a HIDDEN field, so even
// concrete evaluation of the platform SKIPS it —
// `cue export -e '_failSubscriptionNoVersion' ./...` prints the value and
// exits 0. The field has to be named:
//
//   $ cue export -e '_failSubscriptionNoVersion.#registry' ./...
//   _failSubscriptionNoVersion.#registry."opmodel.dev/catalogs/opm@v1".version:
//     field is required but not present
//
// Which is what a kernel does — Materialize reads #registry — so the error
// reaches the caller that matters. Do not add a pin here that appears to
// check it; there is no vet-visible form.
//
//  _failSubscriptionNoVersion: #Platform & {
//   metadata: name: "prod"
//   type: "kubernetes"
//   #registry: "opmodel.dev/catalogs/opm@v1": enable: true
//  }

// Two primitives disagreeing on ONE matching key. This is the error the
// design wants to be possible: a real modelling conflict, named at the key,
// rather than an artifact of unrelated labels sharing a namespace. Vet-visible
// because the container's required disjunction is narrowed to nothing — the
// error is reported once per surviving disjunct, and both name the key:
//   _failMatchLabelConflict.matchLabels."opm.opmodel.dev/workload-type":
//     2 errors in empty disjunction:
//   _failMatchLabelConflict.matchLabels."opm.opmodel.dev/workload-type":
//     conflicting values "daemon" and "stateful"
//   _failMatchLabelConflict.matchLabels."opm.opmodel.dev/workload-type":
//     conflicting values "stateless" and "stateful"
//
//  _failDaemonBlueprint: #Blueprint & {
//   metadata: {
//    name:           "daemon-workload"
//    modulePath:     "opmodel.dev/catalogs/opm/blueprints/workload"
//    apiVersion:     "v1beta1"
//    catalogVersion: "1.0.0"
//    fqn:            "opmodel.dev/catalogs/opm/blueprints/workload/daemon-workload@v1beta1"
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
//   #blueprints: "opmodel.dev/catalogs/opm/blueprints/workload/stateful-workload@v1beta1": _pinMatchStateful
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
//    modulePath:     "opmodel.dev/catalogs/opm/blueprints/workload"
//    apiVersion:     "v1beta1"
//    catalogVersion: "1.0.0"
//    fqn:            "opmodel.dev/catalogs/opm/blueprints/workload/stateless-workload@v1beta1"
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
