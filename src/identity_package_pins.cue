package core

import (
	"strings"
)

// Schema-level pins for the identity package and the catalog-member gate
// (enhancement 0011 D21/D22, resting on 0010 D40, D42, D43, D44, D45).
//
// Same mechanism as identity_pins.cue, and the same rules apply: every value
// here is a HIDDEN top-level field, so `cue vet` evaluates it and fails on a
// conflict while an importing package never does, and none of them adds a row
// to src/INDEX.md.
//
// MUST-FAIL cases are commented out with the exact error uncommenting yields.
// A commented case is not self-verifying, so each was run once, in place, at
// the commit that introduced it; the recorded error is what `task vet` printed
// — with one documented exception at the bottom, a missing required field,
// which no `cue vet` invocation reports and whose recorded error is `cue
// export`'s. That exception names the command it was measured with.
//
// THESE PINS ARE LOAD-BEARING FOR TWO OTHER CHANGES. Enhancement 0010 D43 and
// D45 deleted `core`'s version-major assertion from #Catalog and #Module on the
// strength of the one #IdentityPackage makes, so _failIdentityMajorSkew below
// is the only place that relation is checked anywhere in the system — see the
// note on that case for why the downstream backstop D43/D45 assumed was never
// built in the first place.
//
// NOTE ON THE FILENAME: this file must NOT be named with a leading underscore.
// CUE skips files whose name begins with "_", so an
// "_identity_package_pins.cue" would be silently unloaded and every pin below
// would vet clean by never running.

// ─── #IdentityPackage: two fields authored, the rest derived ────────────────

// A catalog's identity package. Every field below ModulePath/Version is pinned
// to the value the derivation must produce.
_pinIdentityCatalog: #IdentityPackage & {
	ModulePath:   "opmodel.dev/catalogs/opm@v1"
	Version:      "1.2.0"
	RegistryPath: "opmodel.dev/catalogs/opm"
	Major:        "v1"
	VersionMajor: "v1"

	kindPrefix: {
		resources:    "opmodel.dev/catalogs/opm/resources"
		traits:       "opmodel.dev/catalogs/opm/traits"
		blueprints:   "opmodel.dev/catalogs/opm/blueprints"
		transformers: "opmodel.dev/catalogs/opm/transformers"
	}
}

// A MODULE's identity package, at a different major. The same definition serves
// both artifact kinds (enhancement 0010 D38, 0011 D12) — which is why it ships
// in `core` rather than in a catalog: a module need not depend on any catalog.
_pinIdentityModule: #IdentityPackage & {
	ModulePath:   "opmodel.dev/modules/postgres@v2"
	Version:      "2.4.1"
	RegistryPath: "opmodel.dev/modules/postgres"
	Major:        "v2"
	VersionMajor: "v2"
}

// A prerelease build. The major is read off the FIRST dot-separated component,
// so a "-alpha.4" suffix must not disturb it — every catalog currently shipping
// is on a prerelease, so this is the common case rather than an edge one.
_pinIdentityPrerelease: #IdentityPackage & {
	ModulePath:   "opmodel.dev/catalogs/opm@v1"
	Version:      "1.0.0-alpha.4"
	VersionMajor: "v1"
}

// A double-digit major, pinning that the derivation reads the component rather
// than a single character.
_pinIdentityDoubleDigitMajor: #IdentityPackage & {
	ModulePath:   "opmodel.dev/modules/postgres@v10"
	Version:      "10.0.0"
	Major:        "v10"
	VersionMajor: "v10"
}

// kindPrefix carries NO major (enhancement 0010 D1) — a catalog member declares
// a #PackagePathType. Stated as a property rather than left implicit in the
// literals above, so it survives someone editing the example: an "@" in any of
// the four is what a re-appended major would look like.
_pinKindPrefixCarriesNoMajor: [
	strings.Contains(_pinIdentityCatalog.kindPrefix.resources, "@"),
	strings.Contains(_pinIdentityCatalog.kindPrefix.traits, "@"),
	strings.Contains(_pinIdentityCatalog.kindPrefix.blueprints, "@"),
	strings.Contains(_pinIdentityCatalog.kindPrefix.transformers, "@"),
]
_pinKindPrefixCarriesNoMajor: [false, false, false, false]

// ─── #CatalogMemberFQNGate: one conformant member per kind ──────────────────

// A resource, filed under its own apiVersion (enhancement 0010 D49). The key
// is built from the member's OWN apiVersion, not from the catalog's build
// (enhancement 0010 D4) — and note the KEY carries no filing segment.
_pinGateResource: #CatalogMemberFQNGate & {
	identity:               _pinIdentityCatalog
	kind:                   "resources"
	name:                   "config-maps"
	declaredModulePath:     "opmodel.dev/catalogs/opm/resources/v1beta1"
	declaredAPIVersion:     "v1beta1"
	declaredCatalogVersion: "1.2.0"
	declaredFQN:            "opmodel.dev/catalogs/opm/resources/config-maps@v1beta1"
}

// A GA raw-family member of the same kind, filing under a DIFFERENT segment of
// the same prefix — per-member apiVersion is what made the filing segment
// derived content rather than grouping (enhancement 0010 D48, D49).
_pinGateResourceGA: #CatalogMemberFQNGate & {
	identity:               _pinIdentityCatalog
	kind:                   "resources"
	name:                   "k8s-deployment"
	declaredModulePath:     "opmodel.dev/catalogs/opm/resources/v1"
	declaredAPIVersion:     "v1"
	declaredCatalogVersion: "1.2.0"
	declaredFQN:            "opmodel.dev/catalogs/opm/resources/k8s-deployment@v1"
}

// A trait. Same catalog, same build, a different kind segment — which is what
// keeps two members sharing a name apart (enhancement 0010 D21).
_pinGateTrait: #CatalogMemberFQNGate & {
	identity:               _pinIdentityCatalog
	kind:                   "traits"
	name:                   "scaling"
	declaredModulePath:     "opmodel.dev/catalogs/opm/traits/v1beta1"
	declaredAPIVersion:     "v1beta1"
	declaredCatalogVersion: "1.2.0"
	declaredFQN:            "opmodel.dev/catalogs/opm/traits/scaling@v1beta1"
}

// A blueprint, at the versioned path enhancement 0010 D49 requires. Note what
// is absent: an ARBITRARY grouping segment like the "/workload" catalog_opm
// once shipped (D42's must-fail case below) — the only admitted segment is the
// member's own apiVersion.
_pinGateBlueprint: #CatalogMemberFQNGate & {
	identity:               _pinIdentityCatalog
	kind:                   "blueprints"
	name:                   "stateless-workload"
	declaredModulePath:     "opmodel.dev/catalogs/opm/blueprints/v1beta1"
	declaredAPIVersion:     "v1beta1"
	declaredCatalogVersion: "1.2.0"
	declaredFQN:            "opmodel.dev/catalogs/opm/blueprints/stateless-workload@v1beta1"
}

// The filing segment never enters the key (enhancement 0010 D49): filing is
// versioned, the key space stays flat.
_pinKeyOmitsFilingSegment: [
	strings.Contains(_pinGateResource.declaredFQN, "/v1beta1/"),
	strings.Contains(_pinGateResourceGA.declaredFQN, "/v1/"),
]
_pinKeyOmitsFilingSegment: [false, false]

// The ADAPTER, and DIRECTION ONE of the conditional optional: declaredAPIVersion
// is ABSENT and the case vets clean. Its key is interpolated from the BUILD
// (enhancement 0010 D4), which _keyVersion selects before the absent optional is
// ever reached — so the field costs a transformer nothing.
_pinGateTransformer: #CatalogMemberFQNGate & {
	identity:               _pinIdentityCatalog
	kind:                   "transformers"
	name:                   "configmap-transformer"
	declaredModulePath:     "opmodel.dev/catalogs/opm/transformers"
	declaredCatalogVersion: "1.2.0"
	declaredFQN:            "opmodel.dev/catalogs/opm/transformers/configmap-transformer@1.2.0"
}

// DIRECTION TWO: a primitive SUPPLYING the field keys on it rather than on the
// build. Stated against the two versions side by side, because a gate that had
// silently keyed everything on identity.Version would satisfy the transformer
// case above on its own.
_pinPrimitiveKeysOnAPIVersion: strings.HasSuffix(_pinGateResource.declaredFQN, "@v1beta1")
_pinPrimitiveKeysOnAPIVersion: true

_pinTransformerKeysOnBuild: strings.HasSuffix(_pinGateTransformer.declaredFQN, "@1.2.0")
_pinTransformerKeysOnBuild: true

// DIRECTION THREE is the MUST-FAIL case at the bottom of this file: a primitive
// OMITTING the field. It is the one case here `task vet` does not catch — see
// the note there.

// The two keys are structurally distinct forms, not two spellings of one form.
// #FQNType is a disjunction of exactly these two, and the gate must not have
// collapsed them.
_pinContractAndImplKeysDiffer: _pinGateResource.declaredFQN != _pinGateTransformer.declaredFQN
_pinContractAndImplKeysDiffer: true

// ─── MUST FAIL ──────────────────────────────────────────────────────────────
//
// Each was uncommented once and run; the recorded error is `task vet`'s output.

// THE MOST LOAD-BEARING CASE IN THIS FILE — a declared version whose major
// disagrees with the path's. Enhancement 0010 D43 and D45 deleted the
// equivalent assertion from #Catalog and #Module on the strength of this one,
// so if it stops firing, NOTHING in the system checks the relation.
//
// D43/D45 recorded a downstream backstop for that exposure — the platform's
// subscription-selection major check. It was NEVER BUILT in `core`, rather
// than built and then removed: an earlier revision of this note blamed the
// scalar-subscription collapse and was wrong. Measured 2026-08-08, no such
// assertion appears at any commit of src/, and the pre-collapse
// subscription filter carried only range/allow/deny. Nothing in #Platform or
// #Subscription relates a subscription's `version` to the "@vN" its #registry
// key carries, and nothing ever did; the platform-side check is owned by
// `library`'s subscription-collapse work, not yet started. The residue is a
// materialize-time registry resolution failure naming a tag that does not
// resolve, which is a symptom rather than a diagnosis. Treat this case as
// having no safety net beneath it.
//
// The error names the DERIVED field rather than either authored one, which is
// what makes it readable — "VersionMajor" is where the two values meet:
//   _failIdentityMajorSkew.VersionMajor: conflicting values "v2" and "v3"
//
//  _failIdentityMajorSkew: #IdentityPackage & {
//   ModulePath: "opmodel.dev/modules/postgres@v2"
//   Version:    "3.0.0"
//  }

// An ARBITRARY grouping segment — catalog_opm's blueprint path as it once
// shipped, "/workload" where the member's apiVersion belongs. This is the case
// enhancement 0010 D42 exists for, and D49's amendment keeps it failing: the
// only segment the filing derivation produces is the member's own apiVersion,
// so "/workload" conflicts with "/v1beta1". Re-measured 2026-08-10 under the
// D49 gate.
//
// It fails on BOTH fields, because the gate builds the path and the key from
// the same identity. The declaredFQN one arrives WRAPPED as "2 errors in empty
// disjunction" — #FQNType is a disjunction of the contract and implementation
// forms, so CUE reports the failure of each arm. That wrapper is precisely the
// diagnostic a hand-rolled string comparison in Go would have discarded, and it
// is the measured reason enhancement 0011 D21/D22 chose unification:
//   _failGateGroupedBlueprint.declaredFQN: 2 errors in empty disjunction:
//   _failGateGroupedBlueprint.declaredFQN: conflicting values
//     ".../blueprints/stateless-workload@v1beta1" and
//     ".../blueprints/workload/stateless-workload@v1beta1"
//   _failGateGroupedBlueprint.declaredModulePath: conflicting values
//     "opmodel.dev/catalogs/opm/blueprints/v1beta1" and
//     "opmodel.dev/catalogs/opm/blueprints/workload"
//   _failGateGroupedBlueprint.declaredFQN: invalid value
//     ".../blueprints/workload/stateless-workload@v1beta1"
//     (out of bound =~"…@\\d+\\.\\d+\\.\\d+(-…)?(\\+…)?$")
//
//  _failGateGroupedBlueprint: #CatalogMemberFQNGate & {
//   identity:               _pinIdentityCatalog
//   kind:                   "blueprints"
//   name:                   "stateless-workload"
//   declaredModulePath:     "opmodel.dev/catalogs/opm/blueprints/workload"
//   declaredAPIVersion:     "v1beta1"
//   declaredCatalogVersion: "1.2.0"
//   declaredFQN:            "opmodel.dev/catalogs/opm/blueprints/workload/stateless-workload@v1beta1"
//  }

// The OTHER half of the D49 filing pin — a contract member filing FLAT at its
// kind prefix, the shape that was conformant before D49 and is refused after
// it. A transformer filing flat stays conformant (_pinGateTransformer above);
// only the three contract kinds carry the derived segment. Measured
// 2026-08-10:
//   _failGateFlatContractMember.declaredModulePath: conflicting values
//     "opmodel.dev/catalogs/opm/resources/v1beta1" and
//     "opmodel.dev/catalogs/opm/resources"
//
//  _failGateFlatContractMember: #CatalogMemberFQNGate & {
//   identity:               _pinIdentityCatalog
//   kind:                   "resources"
//   name:                   "config-maps"
//   declaredModulePath:     "opmodel.dev/catalogs/opm/resources"
//   declaredAPIVersion:     "v1beta1"
//   declaredCatalogVersion: "1.2.0"
//   declaredFQN:            "opmodel.dev/catalogs/opm/resources/config-maps@v1beta1"
//  }

// A stale provenance value — the catalog moved to 1.2.0 and a member still
// names the build before it:
//   _failGateStaleCatalogVersion.declaredCatalogVersion: conflicting values
//     "1.2.0" and "1.1.0"
//
//  _failGateStaleCatalogVersion: #CatalogMemberFQNGate & {
//   identity:               _pinIdentityCatalog
//   kind:                   "resources"
//   name:                   "secrets"
//   declaredModulePath:     "opmodel.dev/catalogs/opm/resources/v1beta1"
//   declaredAPIVersion:     "v1beta1"
//   declaredCatalogVersion: "1.1.0"
//   declaredFQN:            "opmodel.dev/catalogs/opm/resources/secrets@v1beta1"
//  }

// A stale KEY on a transformer — the failure enhancement 0010 D21 accepted and
// delegated here, and the one that costs the most. With `core`'s fqn derivation
// removed, a catalog on 1.2.0 shipping a key naming 1.1.0 passes its own
// `cue vet -c` at exit 0 (measured; see identity_pins.cue's
// _pinTransformerBuildSkewAccepted, which is that case left deliberately
// clean). Under D4 that key is what a platform executes against permanently.
// This gate is the only thing that catches it:
//   _failGateStaleTransformerFQN.declaredFQN: 2 errors in empty disjunction:
//   _failGateStaleTransformerFQN.declaredFQN: conflicting values
//     ".../transformers/configmap-transformer@1.2.0" and
//     ".../transformers/configmap-transformer@1.1.0"
//   _failGateStaleTransformerFQN.declaredFQN: invalid value
//     ".../transformers/configmap-transformer@1.1.0"
//     (out of bound =~"…@v[0-9]+((alpha|beta)[0-9]+)?$")
//
//  _failGateStaleTransformerFQN: #CatalogMemberFQNGate & {
//   identity:               _pinIdentityCatalog
//   kind:                   "transformers"
//   name:                   "configmap-transformer"
//   declaredModulePath:     "opmodel.dev/catalogs/opm/transformers"
//   declaredCatalogVersion: "1.2.0"
//   declaredFQN:            "opmodel.dev/catalogs/opm/transformers/configmap-transformer@1.1.0"
//  }

// A member declaring ANOTHER catalog's path — enhancement 0010 D17's rule, and
// what a member copied wholesale between catalogs looks like. The case files
// at the foreign catalog's VERSIONED path so it isolates the foreign-path
// failure rather than compounding it with a missing filing segment.
// Re-measured 2026-08-10 under the D49 gate:
//   _failGateForeignPath.declaredFQN: 2 errors in empty disjunction:
//   _failGateForeignPath.declaredFQN: conflicting values
//     "opmodel.dev/catalogs/opm/resources/config-maps@v1beta1" and
//     "example.com/catalogs/other/resources/config-maps@v1beta1"
//   _failGateForeignPath.declaredModulePath: conflicting values
//     "opmodel.dev/catalogs/opm/resources/v1beta1" and
//     "example.com/catalogs/other/resources/v1beta1"
//   _failGateForeignPath.declaredFQN: invalid value
//     "example.com/catalogs/other/resources/config-maps@v1beta1"
//     (out of bound =~"…@\\d+\\.\\d+\\.\\d+(-…)?(\\+…)?$")
//
//  _failGateForeignPath: #CatalogMemberFQNGate & {
//   identity:               _pinIdentityCatalog
//   kind:                   "resources"
//   name:                   "config-maps"
//   declaredModulePath:     "example.com/catalogs/other/resources/v1beta1"
//   declaredAPIVersion:     "v1beta1"
//   declaredCatalogVersion: "1.2.0"
//   declaredFQN:            "example.com/catalogs/other/resources/config-maps@v1beta1"
//  }

// An unknown kind. The enum is closed, so every arm is reported — and note that
// `kindPrefix` is what makes the refusal total rather than cosmetic: there is no
// prefix to index, so declaredFQN fails alongside it:
//   _failGateUnknownKind.declaredFQN: 6 errors in empty disjunction:
//   _failGateUnknownKind.kind: 4 errors in empty disjunction:
//   _failGateUnknownKind.kind: conflicting values "blueprints" and "components"
//   _failGateUnknownKind.kind: conflicting values "resources" and "components"
//   _failGateUnknownKind.kind: conflicting values "traits" and "components"
//   _failGateUnknownKind.kind: conflicting values "transformers" and "components"
//   _failGateUnknownKind.declaredFQN: invalid value
//     "opmodel.dev/catalogs/opm/components/config-maps@v1beta1"
//     (out of bound =~"…@\\d+\\.\\d+\\.\\d+(-…)?(\\+…)?$")
//
//  _failGateUnknownKind: #CatalogMemberFQNGate & {
//   identity:               _pinIdentityCatalog
//   kind:                   "components"
//   name:                   "config-maps"
//   declaredModulePath:     "opmodel.dev/catalogs/opm/components/v1beta1"
//   declaredAPIVersion:     "v1beta1"
//   declaredCatalogVersion: "1.2.0"
//   declaredFQN:            "opmodel.dev/catalogs/opm/components/config-maps@v1beta1"
//  }

// DIRECTION THREE of the conditional optional — a PRIMITIVE omitting
// declaredAPIVersion — and the one MUST-FAIL case in this file that `task vet`
// does not catch. Measured 2026-08-07 and re-measured 2026-08-10 under the D49
// gate, cue v0.17.1: `cue vet ./...` AND `cue vet -c ./...` both exit 0 on the
// case below. A missing required field is an incomplete value, not a wrong
// one, so only concrete evaluation reports it:
//
//   $ cue export -e '_failGateMissingAPIVersion' ./...
//   _failGateMissingAPIVersion.declaredAPIVersion: field is required but not present
//   _failGateMissingAPIVersion.declaredFQN: 2 errors in empty disjunction:
//   _failGateMissingAPIVersion.declaredModulePath: required field missing: declaredAPIVersion
//   _failGateMissingAPIVersion._keyVersion: required field missing: declaredAPIVersion
//
// That is the correct surfacing — the publishing tool evaluates concretely and
// reads the error naming the field — but it means the conditional `!` is NOT
// gated by this repo's own vet run. Do not add a pin here that appears to check
// it; there is no vet-visible form of this case. The same exception, for the
// same reason, is recorded at the bottom of identity_pins.cue.
//
// Note the TWO derived-field lines: under D49 both declaredModulePath (the
// filing segment) and _keyVersion (the key) name the missing field — the two
// places the apiVersion reaches, each reporting its absence. That is the
// conditional working as designed — the transformer arm was not selected, so
// evaluation reached the optional and found nothing. It is also why
// _pinGateTransformer above vets clean: there the arm IS selected, and the
// absent optional is never reached.
//
//  _failGateMissingAPIVersion: #CatalogMemberFQNGate & {
//   identity:               _pinIdentityCatalog
//   kind:                   "resources"
//   name:                   "config-maps"
//   declaredModulePath:     "opmodel.dev/catalogs/opm/resources/v1beta1"
//   declaredCatalogVersion: "1.2.0"
//   declaredFQN:            "opmodel.dev/catalogs/opm/resources/config-maps@v1beta1"
//  }
