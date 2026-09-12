package core

// Schema-level pins for the catalog contract maps (enhancement 0015 D1):
// #Catalog.#resources, #traits and #blueprints, the members a catalog
// DEFINES as distinct from the #transformers it IMPLEMENTS. The enhancement
// ships no examples.cue, so the delta is exercised here.
//
// Companion to identity_pins.cue and platform_and_match_pins.cue and written
// to the same rules: every value here is a HIDDEN top-level field, so `cue
// vet` evaluates them and fails on a conflict while an importing package
// never does, and none of them adds a row to src/INDEX.md. Every pin FORCES
// evaluation (key indexing, len(), or string interpolation): a `_pin: <expr>`
// followed by `_pin: <literal>` on an unset or defaulted expression asserts
// nothing, as platform_and_match_pins.cue records. MUST-FAIL cases are
// commented out with the exact error uncommenting yields; each was run once,
// in place, at the commit that introduced it, and the recorded text is what
// `cue vet` printed.
//
// As there, the filename must NOT begin with an underscore: CUE skips such
// files, and every pin below would then vet clean by never running.

// ─── Fixtures: one member per map, copied in shape from catalog_opm ─────────
//
// Each member authors only what the stamp cannot supply — name, apiVersion,
// fqn and the kind's own required fields — so the two stamped values below
// are the catalog's doing and nothing else's. `core` has no dependencies, so
// the shapes are copied rather than imported.

_pinContractResource: #Resource & {
	metadata: {
		name:       "container"
		apiVersion: "v1beta1"
		fqn:        "opmodel.dev/catalogs/opm/resources/container@v1beta1"
	}
	spec: container: image: string
}

_pinContractTrait: #Trait & {
	metadata: {
		name:       "scaling"
		apiVersion: "v1beta1"
		fqn:        "opmodel.dev/catalogs/opm/traits/scaling@v1beta1"
	}
	optional: bool | *true
	spec: scaling: replicas: int
	appliesTo: [_pinContractResource]
}

_pinContractBlueprint: #Blueprint & {
	metadata: {
		name:       "stateless-workload"
		apiVersion: "v1alpha1"
		fqn:        "opmodel.dev/catalogs/opm/blueprints/stateless-workload@v1alpha1"
	}
	composedResources: [_pinContractResource]
	spec: statelessWorkload: replicas: int
}

// The case the maps exist for (0015 D1, 0010 D37): a provider-fulfilled
// trait, which its declaring catalog lists and ships no adapter for.
_pinContractProviderTrait: #Trait & {
	metadata: {
		name:       "backup"
		apiVersion: "v1alpha1"
		fqn:        "opmodel.dev/catalogs/opm/traits/backup@v1alpha1"
	}
	fulfilment: "provider"
	optional:   bool | *false
	spec: backup: schedule: string
	appliesTo: [_pinContractResource]
}

// ─── The stamps: modulePath carries the member's own apiVersion segment ─────

// A catalog listing one member of each kind, in the authoring idiom
// #transformers already uses: `(value.metadata.fqn): value`.
_pinContractCatalog: #Catalog & {
	metadata: {
		modulePath: "opmodel.dev/catalogs/opm@v4"
		version:    "4.1.0"
	}
	#resources: (_pinContractResource.metadata.fqn):   _pinContractResource
	#traits: (_pinContractTrait.metadata.fqn):         _pinContractTrait
	#blueprints: (_pinContractBlueprint.metadata.fqn): _pinContractBlueprint
	#transformers: {}
}

// Read back by key. The stamped modulePath is the MAJOR-FREE registry path,
// the map's kind segment, and the member's own apiVersion (0010 D49) — the
// value #CatalogMemberFQNGate derives at publish; catalogVersion is the
// catalog's build. One interpolation over all six values forces evaluation.
_pinContractStamps: "\(_pinContractCatalog.#resources["opmodel.dev/catalogs/opm/resources/container@v1beta1"].metadata.modulePath) \(_pinContractCatalog.#resources["opmodel.dev/catalogs/opm/resources/container@v1beta1"].metadata.catalogVersion) | \(_pinContractCatalog.#traits["opmodel.dev/catalogs/opm/traits/scaling@v1beta1"].metadata.modulePath) \(_pinContractCatalog.#traits["opmodel.dev/catalogs/opm/traits/scaling@v1beta1"].metadata.catalogVersion) | \(_pinContractCatalog.#blueprints["opmodel.dev/catalogs/opm/blueprints/stateless-workload@v1alpha1"].metadata.modulePath) \(_pinContractCatalog.#blueprints["opmodel.dev/catalogs/opm/blueprints/stateless-workload@v1alpha1"].metadata.catalogVersion)"
_pinContractStamps: "opmodel.dev/catalogs/opm/resources/v1beta1 4.1.0 | opmodel.dev/catalogs/opm/traits/v1beta1 4.1.0 | opmodel.dev/catalogs/opm/blueprints/v1alpha1 4.1.0"

// ─── Key and fqn are not compared by core ───────────────────────────────────

// A well-formed contract key that differs from the member's authored fqn.
// `core` enforces the key's FORM only; the agreement between key, fqn and the
// identity package is #CatalogMemberFQNGate's at publish (0010 D21), as it
// already is for #transformers. The member validates, receives the stamps,
// and its fqn is untouched by the key it sits under.
_pinContractKeyNotCompared: #Catalog & {
	metadata: {
		modulePath: "opmodel.dev/catalogs/opm@v4"
		version:    "4.1.0"
	}
	#transformers: {}
	#traits: "opmodel.dev/catalogs/opm/traits/autoscale@v1beta1": _pinContractTrait
}

_pinContractKeyNotComparedRead: "\(_pinContractKeyNotCompared.#traits["opmodel.dev/catalogs/opm/traits/autoscale@v1beta1"].metadata.fqn)|\(_pinContractKeyNotCompared.#traits["opmodel.dev/catalogs/opm/traits/autoscale@v1beta1"].metadata.modulePath)"
_pinContractKeyNotComparedRead: "opmodel.dev/catalogs/opm/traits/scaling@v1beta1|opmodel.dev/catalogs/opm/traits/v1beta1"

// ─── Publishing a contract requires no adapter ──────────────────────────────

// A catalog whose #transformers is EMPTY and whose one member is
// provider-fulfilled: before the contract maps this catalog published
// nothing at all. The trait is readable by key and its fulfilment is what
// 0015 D11's `provides` fold reads.
_pinContractProviderOnlyCatalog: #Catalog & {
	metadata: {
		modulePath: "opmodel.dev/catalogs/backup@v1"
		version:    "1.0.0"
	}
	#transformers: {}
	#traits: (_pinContractProviderTrait.metadata.fqn): _pinContractProviderTrait
}

_pinContractProviderVisible: "\(_pinContractProviderOnlyCatalog.#traits["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"].fulfilment)@\(_pinContractProviderOnlyCatalog.#traits["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"].metadata.modulePath)|\(len(_pinContractProviderOnlyCatalog.#transformers))"
_pinContractProviderVisible: "provider@opmodel.dev/catalogs/backup/traits/v1alpha1|0"

// ─── A catalog listing nothing stays valid ──────────────────────────────────

// The shape of every catalog published before the maps existed: metadata
// and #transformers only. All three maps evaluate to an empty struct.
_pinContractEmptyCatalog: #Catalog & {
	metadata: {
		modulePath: "opmodel.dev/catalogs/opm@v3"
		version:    "3.9.0"
	}
	#transformers: {}
}

_pinContractEmptyMaps: "\(len(_pinContractEmptyCatalog.#resources))\(len(_pinContractEmptyCatalog.#traits))\(len(_pinContractEmptyCatalog.#blueprints))"
_pinContractEmptyMaps: "000"

// ─── MUST FAIL ──────────────────────────────────────────────────────────────
//
// Each was uncommented once and run; the recorded error is `task vet`'s output.
// The first two also print a cascade line (`spec.<name>: field not allowed`):
// the metadata conflict poisons `#definitionName`, so the computed `spec` label
// cannot resolve. The first line is the refusal; the cascade is noise.

// Filing drift: a member declaring apiVersion "v1alpha1" but authored under
// the "v1beta1" segment. The stamp is the value #CatalogMemberFQNGate derives,
// so the refusal names both paths:
//   _failContractFilingDrift.#traits."opmodel.dev/catalogs/opm/traits/backup@v1alpha1".metadata.modulePath: conflicting values
//     "opmodel.dev/catalogs/opm/traits/v1alpha1" and "opmodel.dev/catalogs/opm/traits/v1beta1"
//   _failContractFilingDrift.#traits."opmodel.dev/catalogs/opm/traits/backup@v1alpha1".spec.backup: field not allowed
//
//  _failContractFilingDrift: #Catalog & {
//   metadata: {
//    modulePath: "opmodel.dev/catalogs/opm@v4"
//    version:    "4.1.0"
//   }
//   #traits: "opmodel.dev/catalogs/opm/traits/backup@v1alpha1": _pinContractProviderTrait & {
//    metadata: modulePath: "opmodel.dev/catalogs/opm/traits/v1beta1"
//   }
//  }
//  _failContractFilingDriftRead: _failContractFilingDrift.#traits["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"].metadata.modulePath

// A stale build: a member naming a catalogVersion other than the catalog's
// own. Provenance is stamped, not authored per leaf (0010 D25):
//   _failContractStaleBuild.#traits."opmodel.dev/catalogs/opm/traits/scaling@v1beta1".metadata.catalogVersion: conflicting values
//     "4.1.0" and "3.9.0"
//   _failContractStaleBuild.#traits."opmodel.dev/catalogs/opm/traits/scaling@v1beta1".spec.scaling: field not allowed
//
//  _failContractStaleBuild: #Catalog & {
//   metadata: {
//    modulePath: "opmodel.dev/catalogs/opm@v4"
//    version:    "4.1.0"
//   }
//   #traits: "opmodel.dev/catalogs/opm/traits/scaling@v1beta1": _pinContractTrait & {
//    metadata: catalogVersion: "3.9.0"
//   }
//  }
//  _failContractStaleBuildRead: _failContractStaleBuild.#traits["opmodel.dev/catalogs/opm/traits/scaling@v1beta1"].metadata.catalogVersion

// A #Resource listed under #traits. The map's value type is the kind, and
// `kind` is a literal on each primitive, so the refusal is on `kind`:
//   _failContractWrongKind.#traits."opmodel.dev/catalogs/opm/resources/container@v1beta1".kind: conflicting values
//     "Resource" and "Trait"
//
//  _failContractWrongKind: #Catalog & {
//   metadata: {
//    modulePath: "opmodel.dev/catalogs/opm@v4"
//    version:    "4.1.0"
//   }
//   #traits: (_pinContractResource.metadata.fqn): _pinContractResource
//  }
//  _failContractWrongKindRead: _failContractWrongKind.#traits["opmodel.dev/catalogs/opm/resources/container@v1beta1"].kind

// A build-form key under a contract map. The maps are keyed #ContractFQNType,
// so the key is refused outright rather than admitted as a member nothing
// demands (primitive-keying):
//   _failContractBuildKey.#traits."opmodel.dev/catalogs/opm/transformers/backup@4.1.0": field not allowed
//
//  _failContractBuildKey: #Catalog & {
//   metadata: {
//    modulePath: "opmodel.dev/catalogs/opm@v4"
//    version:    "4.1.0"
//   }
//   #traits: "opmodel.dev/catalogs/opm/transformers/backup@4.1.0": _pinContractProviderTrait
//  }
