package core

import (
	"list"
	"strings"
)

// Schema-level pins for the contract inventory (enhancement 0015 D1, D2,
// D18): #ContractInventory and the #Platform.#contracts fold that derives it
// from the enabled entries' contract maps and the required demands of
// #composedTransformers. The enhancement ships no examples.cue for this
// slice, so the delta is exercised here.
//
// Companion to catalog_pins.cue and platform_and_match_pins.cue and written
// to the same rules: every value here is a HIDDEN top-level field, so `cue
// vet` evaluates them and fails on a conflict while an importing package
// never does, and none of them adds a row to src/INDEX.md. Every pin FORCES
// evaluation (string interpolation, len(), or key indexing): a `_pin: <expr>`
// followed by `_pin: <literal>` on an unset or defaulted expression asserts
// nothing, as platform_and_match_pins.cue records. Lists are pinned through
// strings.Join over a sorted copy, so the pin states the exact members and
// does not ride on registry iteration order.
//
// MUST-FAIL cases: none. The inventory reports and never refuses (D18), so
// there is no platform value this file could show being rejected; the
// over-subscribed platform below is pinned EVALUATING, which is the property.
//
// As there, the filename must NOT begin with an underscore: CUE skips such
// files, and every pin below would then vet clean by never running.

// ─── Fixtures: three stand-in catalogs ──────────────────────────────────────
//
// Shapes copied from catalog_opm and the provider design (0015 02-design.md);
// `core` has no dependencies, so nothing is imported. Each member authors
// only what the catalog stamp cannot supply. The base catalog lists one
// member per map plus the provider-fulfilled `backup` trait and ships one
// adapter; the k8up-shaped catalog ships two adapters over `backup` (its
// Schedule and PreBackupPod) and lists one contract of its own; the
// velero-shaped catalog ships one adapter requiring `backup` alone.

_pinInventoryContainer: #Resource & {
	metadata: {
		name:       "container"
		apiVersion: "v1beta1"
		fqn:        "opmodel.dev/catalogs/opm/resources/container@v1beta1"
	}
	spec: container: image: string
}

// Catalog-fulfilled (the default) and required by nothing: never
// unfulfilled, because only a provider-fulfilled contract can be.
_pinInventoryScaling: #Trait & {
	metadata: {
		name:       "scaling"
		apiVersion: "v1beta1"
		fqn:        "opmodel.dev/catalogs/opm/traits/scaling@v1beta1"
	}
	optional: bool | *true
	spec: scaling: replicas: int
	appliesTo: [_pinInventoryContainer]
}

// The contract the inventory exists for: provider-fulfilled, listed by the
// base catalog, implemented by whichever provider catalog the platform adds.
_pinInventoryBackup: #Trait & {
	metadata: {
		name:       "backup"
		apiVersion: "v1alpha1"
		fqn:        "opmodel.dev/catalogs/opm/traits/backup@v1alpha1"
	}
	fulfilment: "provider"
	optional:   bool | *false
	spec: backup: schedule: string
	appliesTo: [_pinInventoryContainer]
}

_pinInventoryStateless: #Blueprint & {
	metadata: {
		name:       "stateless-workload"
		apiVersion: "v1alpha1"
		fqn:        "opmodel.dev/catalogs/opm/blueprints/stateless-workload@v1alpha1"
	}
	composedResources: [_pinInventoryContainer]
	spec: statelessWorkload: replicas: int
}

// A contract the k8up-shaped catalog defines for itself, so a disabled
// provider entry has something to NOT contribute to `defined`.
_pinInventoryRetention: #Trait & {
	metadata: {
		name:       "retention"
		apiVersion: "v1alpha1"
		fqn:        "opmodel.dev/catalogs/k8up/traits/retention@v1alpha1"
	}
	optional: bool | *true
	spec: retention: keepDaily: int
	appliesTo: [_pinInventoryContainer]
}

// The base catalog's one adapter: requiredResources only, no requiredTraits
// map at all. This is the presence-guard case (see _pinInventoryGuarded).
_pinInventoryDeployment: #ComponentTransformer & {
	metadata: {
		name:        "deployment"
		fqn:         "opmodel.dev/catalogs/opm/transformers/deployment@1.0.0"
		description: "Pin fixture: the base catalog's own adapter"
	}
	requiredResources: (_pinInventoryContainer.metadata.fqn): _pinInventoryContainer
}

// k8up's two adapters over one contract. Both require `backup`; the first
// also requires the container, the second requires `backup` alone.
_pinInventoryK8upSchedule: #ComponentTransformer & {
	metadata: {
		name:        "schedule"
		fqn:         "opmodel.dev/catalogs/k8up/transformers/schedule@2.0.0"
		description: "Pin fixture: k8up's Schedule adapter"
	}
	requiredResources: (_pinInventoryContainer.metadata.fqn): _pinInventoryContainer
	requiredTraits: (_pinInventoryBackup.metadata.fqn):       _pinInventoryBackup
}

_pinInventoryK8upPreBackupPod: #ComponentTransformer & {
	metadata: {
		name:        "pre-backup-pod"
		fqn:         "opmodel.dev/catalogs/k8up/transformers/pre-backup-pod@2.0.0"
		description: "Pin fixture: k8up's PreBackupPod adapter"
	}
	requiredTraits: (_pinInventoryBackup.metadata.fqn): _pinInventoryBackup
}

// velero's adapter: requiredTraits only, no requiredResources map at all,
// the mirror of the deployment fixture for the other presence guard.
_pinInventoryVeleroBackup: #ComponentTransformer & {
	metadata: {
		name:        "backup"
		fqn:         "opmodel.dev/catalogs/velero/transformers/backup@1.4.0"
		description: "Pin fixture: velero's Backup adapter"
	}
	requiredTraits: (_pinInventoryBackup.metadata.fqn): _pinInventoryBackup
}

_pinInventoryBaseCatalog: #Catalog & {
	metadata: {
		modulePath: "opmodel.dev/catalogs/opm@v1"
		version:    "1.0.0"
	}
	#resources: (_pinInventoryContainer.metadata.fqn): _pinInventoryContainer
	#traits: {
		(_pinInventoryScaling.metadata.fqn): _pinInventoryScaling
		(_pinInventoryBackup.metadata.fqn):  _pinInventoryBackup
	}
	#blueprints: (_pinInventoryStateless.metadata.fqn):    _pinInventoryStateless
	#transformers: (_pinInventoryDeployment.metadata.fqn): _pinInventoryDeployment
}

_pinInventoryK8upCatalog: #Catalog & {
	metadata: {
		modulePath: "opmodel.dev/catalogs/k8up@v2"
		version:    "2.0.0"
	}
	#traits: (_pinInventoryRetention.metadata.fqn): _pinInventoryRetention
	#transformers: {
		(_pinInventoryK8upSchedule.metadata.fqn):     _pinInventoryK8upSchedule
		(_pinInventoryK8upPreBackupPod.metadata.fqn): _pinInventoryK8upPreBackupPod
	}
}

_pinInventoryVeleroCatalog: #Catalog & {
	metadata: {
		modulePath: "opmodel.dev/catalogs/velero@v1"
		version:    "1.4.0"
	}
	#transformers: (_pinInventoryVeleroBackup.metadata.fqn): _pinInventoryVeleroBackup
}

// ─── The five platforms ─────────────────────────────────────────────────────

_pinInventoryEmpty: #Platform & {
	metadata: name: "empty"
	type: "kubernetes"
}

_pinInventoryBaseOnly: #Platform & {
	metadata: name: "base-only"
	type: "kubernetes"
	#registry: (_pinInventoryBaseCatalog.metadata.modulePath): #catalog: _pinInventoryBaseCatalog
}

_pinInventoryOneProvider: #Platform & {
	metadata: name: "one-provider"
	type: "kubernetes"
	#registry: {
		(_pinInventoryBaseCatalog.metadata.modulePath): #catalog: _pinInventoryBaseCatalog
		(_pinInventoryK8upCatalog.metadata.modulePath): #catalog: _pinInventoryK8upCatalog
	}
}

_pinInventoryTwoProviders: #Platform & {
	metadata: name: "two-providers"
	type: "kubernetes"
	#registry: {
		(_pinInventoryBaseCatalog.metadata.modulePath): #catalog:   _pinInventoryBaseCatalog
		(_pinInventoryK8upCatalog.metadata.modulePath): #catalog:   _pinInventoryK8upCatalog
		(_pinInventoryVeleroCatalog.metadata.modulePath): #catalog: _pinInventoryVeleroCatalog
	}
}

_pinInventoryDisabledProvider: #Platform & {
	metadata: name: "disabled-provider"
	type: "kubernetes"
	#registry: {
		(_pinInventoryBaseCatalog.metadata.modulePath): #catalog: _pinInventoryBaseCatalog
		(_pinInventoryK8upCatalog.metadata.modulePath): {
			enable:   false
			#catalog: _pinInventoryK8upCatalog
		}
	}
}

// One readout per platform. Lists join over a sorted copy; an empty list
// joins to "". Interpolation forces every value (the ONE RULE).
_pinInventoryReadout: {
	#in: #ContractInventory
	out: "defined=\(len(#in.defined)) unfulfilled=[\(strings.Join(list.Sort(#in.unfulfilled, list.Ascending), ","))] overSubscribed=[\(strings.Join(list.Sort(#in.overSubscribed, list.Ascending), ","))] fulfilled=\(#in.fulfilled) routable=\(#in.routable)"
}

// ─── Empty registry: every map and list empty, both booleans true ───────────

_pinInventoryEmptyReadout: (_pinInventoryReadout & {#in: _pinInventoryEmpty.#contracts}).out
_pinInventoryEmptyReadout: "defined=0 unfulfilled=[] overSubscribed=[] fulfilled=true routable=true"
_pinInventoryEmptyMaps:    "\(len(_pinInventoryEmpty.#contracts.definedBy))\(len(_pinInventoryEmpty.#contracts.requiredBy))"
_pinInventoryEmptyMaps:    "00"

// ─── Base only: `backup` is defined, required by nothing, unfulfilled ───────
//
// Four members defined (one per map plus backup); `scaling` is also required
// by nothing but is catalog-fulfilled, so it is not unfulfilled; the
// blueprint never appears in either report. fulfilled=false is a REPORT: the
// platform value evaluates and every other field reads.

_pinInventoryBaseOnlyReadout: (_pinInventoryReadout & {#in: _pinInventoryBaseOnly.#contracts}).out
_pinInventoryBaseOnlyReadout: "defined=4 unfulfilled=[opmodel.dev/catalogs/opm/traits/backup@v1alpha1] overSubscribed=[] fulfilled=false routable=true"

// definedBy carries the REGISTRY KEY (the catalog's module path, major
// included), not the member's stamped package path.
_pinInventoryBaseOnlyDefinedBy: "\(_pinInventoryBaseOnly.#contracts.definedBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"])|\(_pinInventoryBaseOnly.#contracts.definedBy["opmodel.dev/catalogs/opm/blueprints/stateless-workload@v1alpha1"])"
_pinInventoryBaseOnlyDefinedBy: "opmodel.dev/catalogs/opm@v1|opmodel.dev/catalogs/opm@v1"

// `defined` carries the member as the catalog lists it: the stamp is
// readable, and so is the primitive's own fulfilment.
_pinInventoryBaseOnlyDefined: "\(_pinInventoryBaseOnly.#contracts.defined["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"].fulfilment)@\(_pinInventoryBaseOnly.#contracts.defined["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"].metadata.modulePath)"
_pinInventoryBaseOnlyDefined: "provider@opmodel.dev/catalogs/opm/traits/v1alpha1"

// requiredBy: the container is required by the one adapter; the
// catalog-fulfilled trait and the provider-fulfilled trait by nothing (an
// empty list, not an absent key).
_pinInventoryBaseOnlyRequiredBy: "\(strings.Join(_pinInventoryBaseOnly.#contracts.requiredBy["opmodel.dev/catalogs/opm/resources/container@v1beta1"], ","))|\(len(_pinInventoryBaseOnly.#contracts.requiredBy["opmodel.dev/catalogs/opm/traits/scaling@v1beta1"]))|\(len(_pinInventoryBaseOnly.#contracts.requiredBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"]))"
_pinInventoryBaseOnlyRequiredBy: "opmodel.dev/catalogs/opm/transformers/deployment@1.0.0|0|0"

// ─── One provider: k8up's two adapters count as ONE catalog ─────────────────
//
// Five members (k8up lists `retention`); `backup` is required by both k8up
// adapters, and because over-subscription counts catalogs through the
// stamped modulePath, two adapters of one catalog are one provider.

_pinInventoryOneProviderReadout: (_pinInventoryReadout & {#in: _pinInventoryOneProvider.#contracts}).out
_pinInventoryOneProviderReadout: "defined=5 unfulfilled=[] overSubscribed=[] fulfilled=true routable=true"

_pinInventoryOneProviderRequiredBy: strings.Join(list.Sort(_pinInventoryOneProvider.#contracts.requiredBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"], list.Ascending), ",")
_pinInventoryOneProviderRequiredBy: "opmodel.dev/catalogs/k8up/transformers/pre-backup-pod@2.0.0,opmodel.dev/catalogs/k8up/transformers/schedule@2.0.0"

// A contract required by transformers from two catalogs lists both.
_pinInventoryOneProviderContainer: strings.Join(list.Sort(_pinInventoryOneProvider.#contracts.requiredBy["opmodel.dev/catalogs/opm/resources/container@v1beta1"], list.Ascending), ",")
_pinInventoryOneProviderContainer: "opmodel.dev/catalogs/k8up/transformers/schedule@2.0.0,opmodel.dev/catalogs/opm/transformers/deployment@1.0.0"

_pinInventoryOneProviderDefinedBy: "\(_pinInventoryOneProvider.#contracts.definedBy["opmodel.dev/catalogs/k8up/traits/retention@v1alpha1"])"
_pinInventoryOneProviderDefinedBy: "opmodel.dev/catalogs/k8up@v2"

// ─── Two providers: over-subscribed, and the value STILL EVALUATES ──────────
//
// This is D18's whole point pinned: `routable: false` is a value a caller
// reads, not a bottom. #composedTransformers is intact beside it, and the
// report names the contract.

_pinInventoryTwoProvidersReadout: (_pinInventoryReadout & {#in: _pinInventoryTwoProviders.#contracts}).out
_pinInventoryTwoProvidersReadout: "defined=5 unfulfilled=[] overSubscribed=[opmodel.dev/catalogs/opm/traits/backup@v1alpha1] fulfilled=true routable=false"

_pinInventoryTwoProvidersRequiredBy: strings.Join(list.Sort(_pinInventoryTwoProviders.#contracts.requiredBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"], list.Ascending), ",")
_pinInventoryTwoProvidersRequiredBy: "opmodel.dev/catalogs/k8up/transformers/pre-backup-pod@2.0.0,opmodel.dev/catalogs/k8up/transformers/schedule@2.0.0,opmodel.dev/catalogs/velero/transformers/backup@1.4.0"

_pinInventoryTwoProvidersIntact: "\(len(_pinInventoryTwoProviders.#composedTransformers))|\(_pinInventoryTwoProviders.#contracts.definedBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"])"
_pinInventoryTwoProvidersIntact: "4|opmodel.dev/catalogs/opm@v1"

// ─── Disabled provider: reads exactly as base only ──────────────────────────
//
// The k8up entry is present in the file and contributes nothing: not its
// `retention` contract to `defined` or `definedBy`, not its adapters to any
// requiredBy list. `backup` is back to unfulfilled.

_pinInventoryDisabledProviderReadout: (_pinInventoryReadout & {#in: _pinInventoryDisabledProvider.#contracts}).out
_pinInventoryDisabledProviderReadout: "defined=4 unfulfilled=[opmodel.dev/catalogs/opm/traits/backup@v1alpha1] overSubscribed=[] fulfilled=false routable=true"

_pinInventoryDisabledProviderAbsent: "\(_pinInventoryDisabledProvider.#contracts.definedBy["opmodel.dev/catalogs/k8up/traits/retention@v1alpha1"] == _|_)|\(len(_pinInventoryDisabledProvider.#contracts.requiredBy["opmodel.dev/catalogs/opm/resources/container@v1beta1"]))|\(len(_pinInventoryDisabledProvider.#contracts.requiredBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"]))"
_pinInventoryDisabledProviderAbsent: "true|1|0"

// ─── The presence guards ────────────────────────────────────────────────────
//
// The deployment fixture declares requiredResources and NO requiredTraits;
// the velero and pre-backup-pod fixtures declare requiredTraits and NO
// requiredResources. Each is counted under its present map and demands
// nothing of the absent kind, and the platform evaluates.
//
// THE UNGUARDED CASE IS NOT PLAIN-VET-VISIBLE, which dictates the pin's
// shape. Measured 2026-09-13, cue v0.17.1, with the requiredTraits guard
// removed from platform.cue: `cue vet ./...` and `cue vet -c ./...` both
// exit 0 (the error is incomplete-class and the pins are hidden), while
//
//   $ cue export -e '_pinInventoryBaseOnly.#contracts.requiredBy' ./
//   _pinInventoryBaseOnly.#contracts.requiredBy."opmodel.dev/catalogs/opm/resources/container@v1beta1":
//     cannot reference optional field: requiredTraits
//
// and the interpolated readout pins above collapse to their literals. The
// `!= _|_` form is false for that incomplete value and true for the list,
// so THIS pin is the one that fails under plain vet when either guard goes
// (conflicting values false and true). Both platforms are read: base-only
// carries the fixture without requiredTraits, two-providers carries the two
// without requiredResources.
_pinInventoryGuardsHold: (_pinInventoryBaseOnly.#contracts.requiredBy["opmodel.dev/catalogs/opm/resources/container@v1beta1"] != _|_) && (_pinInventoryTwoProviders.#contracts.requiredBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"] != _|_)
_pinInventoryGuardsHold: true

// ...and with both guards in place the counts are the ones the fixtures
// imply: one adapter on the container in base-only, three on backup in
// two-providers.
_pinInventoryGuarded: "\(len(_pinInventoryBaseOnly.#contracts.requiredBy["opmodel.dev/catalogs/opm/resources/container@v1beta1"]))|\(len(_pinInventoryTwoProviders.#contracts.requiredBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"]))"
_pinInventoryGuarded: "1|3"

// ─── The definition evaluates with no registry at all ───────────────────────

_pinInventoryBare: (_pinInventoryReadout & {#in: #Platform.#contracts}).out
_pinInventoryBare: "defined=0 unfulfilled=[] overSubscribed=[] fulfilled=true routable=true"
