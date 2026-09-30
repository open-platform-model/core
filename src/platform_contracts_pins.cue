package core

import (
	"list"
	"strings"
)

// Schema-level pins for the contract inventory (0015:D1, D2,
// D18): #ContractInventory and the #Platform.#contracts fold that derives it
// from the enabled entries' contract maps and the required demands of
// their transformers. The enhancement ships no examples.cue for this
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
// MUST-FAIL cases: none. The inventory reports and never refuses (0015:D18), so
// there is no platform value this file could show being rejected; the
// over-subscribed and colliding platforms below are pinned EVALUATING, which
// is the property.
//
// As there, the filename must NOT begin with an underscore: CUE skips such
// files, and every pin below would then vet clean by never running.

// ─── Fixtures: eight stand-in catalogs ──────────────────────────────────────
//
// Shapes copied from catalog_opm and the provider design (0015 02-design.md);
// `core` has no dependencies, so nothing is imported. Each member authors
// only what the catalog stamp cannot supply. The base catalog lists one
// member per map plus the provider-fulfilled `backup` trait and ships one
// adapter; the k8up-shaped catalog ships two adapters over `backup` (its
// Schedule and PreBackupPod) and lists one contract of its own; the
// velero-shaped catalog ships one adapter requiring `backup` alone. Two bare
// k8up catalogs, at majors v2 and v3, each ship one PreBackupPod adapter
// requiring `backup` alone and list nothing: the provider-count bug shapes
// (two majors of one provider; two providers with the definer disabled or
// absent). A restic-shaped catalog ships one adapter naming `backup` only as
// an optional demand: consumption that is not provision. The base catalog at
// majors v2 and v3 re-lists its keys (v2 adds a `volume` resource, v3 lists
// only the container and `backup`), each shipping its own deployment
// adapter: the collision shapes, two or three enabled definers of one key.

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

// The two bug-shape provider catalogs: k8up at two majors, each shipping ONE
// adapter that requires `backup` alone and listing no contract of its own.
// Requiring only the provider contract keeps both out of every
// catalog-fulfilled bucket, so `comparable` cannot confound the readout, and
// listing nothing keeps the two majors out of `collisions`, so the readout
// isolates the provider count.
_pinInventoryK8upV2BareCatalog: #Catalog & {
	metadata: {
		modulePath: "opmodel.dev/catalogs/k8up@v2"
		version:    "2.0.0"
	}
	#transformers: (_pinInventoryK8upPreBackupPod.metadata.fqn): _pinInventoryK8upPreBackupPod
}

_pinInventoryK8upV3PreBackupPod: #ComponentTransformer & {
	metadata: {
		name:        "pre-backup-pod"
		fqn:         "opmodel.dev/catalogs/k8up/transformers/pre-backup-pod@3.0.0"
		description: "Pin fixture: k8up v3's PreBackupPod adapter"
	}
	requiredTraits: (_pinInventoryBackup.metadata.fqn): _pinInventoryBackup
}

_pinInventoryK8upV3BareCatalog: #Catalog & {
	metadata: {
		modulePath: "opmodel.dev/catalogs/k8up@v3"
		version:    "3.0.0"
	}
	#transformers: (_pinInventoryK8upV3PreBackupPod.metadata.fqn): _pinInventoryK8upV3PreBackupPod
}

// An adapter that names `backup` ONLY under optionalTraits and requires
// nothing, so it sits in no catalog-fulfilled bucket and `comparable` cannot
// confound the readout.
_pinInventoryResticOptional: #ComponentTransformer & {
	metadata: {
		name:        "optional-backup"
		fqn:         "opmodel.dev/catalogs/restic/transformers/optional-backup@1.0.0"
		description: "Pin fixture: an adapter consuming backup optionally"
	}
	optionalTraits: (_pinInventoryBackup.metadata.fqn): _pinInventoryBackup
}

_pinInventoryResticCatalog: #Catalog & {
	metadata: {
		modulePath: "opmodel.dev/catalogs/restic@v1"
		version:    "1.0.0"
	}
	#transformers: (_pinInventoryResticOptional.metadata.fqn): _pinInventoryResticOptional
}

// A resource only the base catalog's second major lists: the one key a
// colliding platform still folds into `defined` and `definedBy`.
_pinInventoryVolume: #Resource & {
	metadata: {
		name:       "volume"
		apiVersion: "v1beta1"
		fqn:        "opmodel.dev/catalogs/opm/resources/volume@v1beta1"
	}
	spec: volume: size: string
}

// The base catalog's adapter at majors v2 and v3. Each requires the
// container alone, so its predicate equals deployment@1.0.0's.
_pinInventoryDeploymentV2: #ComponentTransformer & {
	metadata: {
		name:        "deployment"
		fqn:         "opmodel.dev/catalogs/opm/transformers/deployment@2.0.0"
		description: "Pin fixture: the base catalog's adapter at major v2"
	}
	requiredResources: (_pinInventoryContainer.metadata.fqn): _pinInventoryContainer
}

_pinInventoryDeploymentV3: #ComponentTransformer & {
	metadata: {
		name:        "deployment"
		fqn:         "opmodel.dev/catalogs/opm/transformers/deployment@3.0.0"
		description: "Pin fixture: the base catalog's adapter at major v3"
	}
	requiredResources: (_pinInventoryContainer.metadata.fqn): _pinInventoryContainer
}

// The base catalog at major v2: its four keys plus `volume`, shipping its
// own adapter. Beside major v1 every shared key is a collision.
_pinInventoryBaseV2Catalog: #Catalog & {
	metadata: {
		modulePath: "opmodel.dev/catalogs/opm@v2"
		version:    "2.0.0"
	}
	#resources: {
		(_pinInventoryContainer.metadata.fqn): _pinInventoryContainer
		(_pinInventoryVolume.metadata.fqn):    _pinInventoryVolume
	}
	#traits: {
		(_pinInventoryScaling.metadata.fqn): _pinInventoryScaling
		(_pinInventoryBackup.metadata.fqn):  _pinInventoryBackup
	}
	#blueprints: (_pinInventoryStateless.metadata.fqn):      _pinInventoryStateless
	#transformers: (_pinInventoryDeploymentV2.metadata.fqn): _pinInventoryDeploymentV2
}

// The base catalog at major v3, listing only the container and `backup`,
// so a three-major platform has keys at three definers and at two.
_pinInventoryBaseV3Catalog: #Catalog & {
	metadata: {
		modulePath: "opmodel.dev/catalogs/opm@v3"
		version:    "3.0.0"
	}
	#resources: (_pinInventoryContainer.metadata.fqn):       _pinInventoryContainer
	#traits: (_pinInventoryBackup.metadata.fqn):             _pinInventoryBackup
	#transformers: (_pinInventoryDeploymentV3.metadata.fqn): _pinInventoryDeploymentV3
}

// ─── The thirteen platforms ─────────────────────────────────────────────────

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

// Bug 1: two majors of one provider catalog, beside the defining catalog.
_pinInventoryTwoMajors: #Platform & {
	metadata: name: "two-majors"
	type: "kubernetes"
	#registry: {
		(_pinInventoryBaseCatalog.metadata.modulePath): #catalog:       _pinInventoryBaseCatalog
		(_pinInventoryK8upV2BareCatalog.metadata.modulePath): #catalog: _pinInventoryK8upV2BareCatalog
		(_pinInventoryK8upV3BareCatalog.metadata.modulePath): #catalog: _pinInventoryK8upV3BareCatalog
	}
}

// Bug 2: two providers while the defining catalog is present and disabled...
_pinInventoryDefinerDisabled: #Platform & {
	metadata: name: "definer-disabled"
	type: "kubernetes"
	#registry: {
		(_pinInventoryBaseCatalog.metadata.modulePath): {
			enable:   false
			#catalog: _pinInventoryBaseCatalog
		}
		(_pinInventoryK8upV2BareCatalog.metadata.modulePath): #catalog: _pinInventoryK8upV2BareCatalog
		(_pinInventoryVeleroCatalog.metadata.modulePath): #catalog:     _pinInventoryVeleroCatalog
	}
}

// ...and while it is absent from the registry altogether.
_pinInventoryDefinerAbsent: #Platform & {
	metadata: name: "definer-absent"
	type: "kubernetes"
	#registry: {
		(_pinInventoryK8upV2BareCatalog.metadata.modulePath): #catalog: _pinInventoryK8upV2BareCatalog
		(_pinInventoryVeleroCatalog.metadata.modulePath): #catalog:     _pinInventoryVeleroCatalog
	}
}

// The defining catalog beside an entry whose only adapter names `backup` as
// an optional demand.
_pinInventoryOptionalOnly: #Platform & {
	metadata: name: "optional-only"
	type: "kubernetes"
	#registry: {
		(_pinInventoryBaseCatalog.metadata.modulePath): #catalog:   _pinInventoryBaseCatalog
		(_pinInventoryResticCatalog.metadata.modulePath): #catalog: _pinInventoryResticCatalog
	}
}

// Two majors of the base catalog, both enabled, sharing four keys.
_pinInventoryCollide: #Platform & {
	metadata: name: "collide"
	type: "kubernetes"
	#registry: {
		(_pinInventoryBaseCatalog.metadata.modulePath): #catalog:   _pinInventoryBaseCatalog
		(_pinInventoryBaseV2Catalog.metadata.modulePath): #catalog: _pinInventoryBaseV2Catalog
	}
}

// The same two majors with the second disabled: nothing collides.
_pinInventoryCollideDisabled: #Platform & {
	metadata: name: "collide-disabled"
	type: "kubernetes"
	#registry: {
		(_pinInventoryBaseCatalog.metadata.modulePath): #catalog: _pinInventoryBaseCatalog
		(_pinInventoryBaseV2Catalog.metadata.modulePath): {
			enable:   false
			#catalog: _pinInventoryBaseV2Catalog
		}
	}
}

// The colliding majors plus two providers of `backup`: a collision and an
// over-subscription reported together.
_pinInventoryCollideOverSubscribed: #Platform & {
	metadata: name: "collide-over-subscribed"
	type: "kubernetes"
	#registry: {
		(_pinInventoryBaseCatalog.metadata.modulePath): #catalog:       _pinInventoryBaseCatalog
		(_pinInventoryBaseV2Catalog.metadata.modulePath): #catalog:     _pinInventoryBaseV2Catalog
		(_pinInventoryK8upV2BareCatalog.metadata.modulePath): #catalog: _pinInventoryK8upV2BareCatalog
		(_pinInventoryVeleroCatalog.metadata.modulePath): #catalog:     _pinInventoryVeleroCatalog
	}
}

// Three majors of the base catalog: two keys at three definers, two at two.
_pinInventoryCollideThreeMajors: #Platform & {
	metadata: name: "collide-three-majors"
	type: "kubernetes"
	#registry: {
		(_pinInventoryBaseCatalog.metadata.modulePath): #catalog:   _pinInventoryBaseCatalog
		(_pinInventoryBaseV2Catalog.metadata.modulePath): #catalog: _pinInventoryBaseV2Catalog
		(_pinInventoryBaseV3Catalog.metadata.modulePath): #catalog: _pinInventoryBaseV3Catalog
	}
}

// One readout per platform. Lists join over a sorted copy; an empty list
// joins to "". Interpolation forces every value (the ONE RULE).
_pinInventoryReadout: {
	#in: #ContractInventory
	out: "defined=\(len(#in.defined)) unfulfilled=[\(strings.Join(list.Sort(#in.unfulfilled, list.Ascending), ","))] overSubscribed=[\(strings.Join(list.Sort(#in.overSubscribed, list.Ascending), ","))] fulfilled=\(#in.fulfilled) routable=\(#in.routable) comparable=\(len(#in.comparable)) discriminated=\(#in.discriminated)"
}

// The collision report per platform. `collisions` is joined WITHOUT
// re-sorting, so the pin also holds the list's own order; each key is
// followed by its colliding entries, joined in their own order; `entries`
// holds that collidingEntries carries colliding keys only.
_pinInventoryCollisionReadout: {
	#in: #ContractInventory
	out: "collisions=[\(strings.Join(#in.collisions, ","))] collidingEntries=[\(strings.Join([for k in #in.collisions {"\(k)=\(strings.Join(#in.collidingEntries[k], "+"))"}], ";"))] entries=\(len(#in.collidingEntries)) routable=\(#in.routable)"
}

// ─── Empty registry: every map and list empty, both booleans true ───────────

_pinInventoryEmptyReadout: (_pinInventoryReadout & {#in: _pinInventoryEmpty.#contracts}).out
_pinInventoryEmptyReadout: "defined=0 unfulfilled=[] overSubscribed=[] fulfilled=true routable=true comparable=0 discriminated=true"
_pinInventoryEmptyMaps:    "\(len(_pinInventoryEmpty.#contracts.definedBy))\(len(_pinInventoryEmpty.#contracts.requiredBy))"
_pinInventoryEmptyMaps:    "00"

// No entry, no provider: providedBy is empty too.
_pinInventoryEmptyProvidedBy: "\(len(_pinInventoryEmpty.#contracts.providedBy))"
_pinInventoryEmptyProvidedBy: "0"

// No entry, no definer: nothing collides.
_pinInventoryEmptyCollisions: (_pinInventoryCollisionReadout & {#in: _pinInventoryEmpty.#contracts}).out
_pinInventoryEmptyCollisions: "collisions=[] collidingEntries=[] entries=0 routable=true"

// ─── Base only: `backup` is defined, required by nothing, unfulfilled ───────
//
// Four members defined (one per map plus backup); `scaling` is also required
// by nothing but is catalog-fulfilled, so it is not unfulfilled; the
// blueprint never appears in either report. fulfilled=false is a REPORT: the
// platform value evaluates and every other field reads.

_pinInventoryBaseOnlyReadout: (_pinInventoryReadout & {#in: _pinInventoryBaseOnly.#contracts}).out
_pinInventoryBaseOnlyReadout: "defined=4 unfulfilled=[opmodel.dev/catalogs/opm/traits/backup@v1alpha1] overSubscribed=[] fulfilled=false routable=true comparable=0 discriminated=true"

// definedBy carries the REGISTRY KEY (the catalog's module path, major
// included), not the member's stamped package path.
_pinInventoryBaseOnlyDefinedBy: "\(_pinInventoryBaseOnly.#contracts.definedBy["opmodel.dev/catalogs/opm/resources/container@v1beta1"])|\(_pinInventoryBaseOnly.#contracts.definedBy["opmodel.dev/catalogs/opm/traits/scaling@v1beta1"])|\(_pinInventoryBaseOnly.#contracts.definedBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"])|\(_pinInventoryBaseOnly.#contracts.definedBy["opmodel.dev/catalogs/opm/blueprints/stateless-workload@v1alpha1"])"
_pinInventoryBaseOnlyDefinedBy: "opmodel.dev/catalogs/opm@v1|opmodel.dev/catalogs/opm@v1|opmodel.dev/catalogs/opm@v1|opmodel.dev/catalogs/opm@v1"

// `defined` carries the member as the catalog lists it: the stamp is
// readable, and so is the primitive's own fulfilment.
_pinInventoryBaseOnlyDefined: "\(_pinInventoryBaseOnly.#contracts.defined["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"].fulfilment)@\(_pinInventoryBaseOnly.#contracts.defined["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"].metadata.modulePath)"
_pinInventoryBaseOnlyDefined: "provider@opmodel.dev/catalogs/opm/traits/v1alpha1"

// requiredBy: the container is required by the one adapter; the
// catalog-fulfilled trait and the provider-fulfilled trait by nothing (an
// empty list, not an absent key).
_pinInventoryBaseOnlyRequiredBy: "\(strings.Join(_pinInventoryBaseOnly.#contracts.requiredBy["opmodel.dev/catalogs/opm/resources/container@v1beta1"], ","))|\(len(_pinInventoryBaseOnly.#contracts.requiredBy["opmodel.dev/catalogs/opm/traits/scaling@v1beta1"]))|\(len(_pinInventoryBaseOnly.#contracts.requiredBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"]))"
_pinInventoryBaseOnlyRequiredBy: "opmodel.dev/catalogs/opm/transformers/deployment@1.0.0|0|0"

// `backup` is defined and provided by nobody: no providedBy key at all, which
// is exactly what makes it unfulfilled.
_pinInventoryBaseOnlyProvidedBy: "\(len(_pinInventoryBaseOnly.#contracts.providedBy))"
_pinInventoryBaseOnlyProvidedBy: "0"

// One major: every key has a single definer, so nothing collides.
_pinInventoryBaseOnlyCollisions: (_pinInventoryCollisionReadout & {#in: _pinInventoryBaseOnly.#contracts}).out
_pinInventoryBaseOnlyCollisions: "collisions=[] collidingEntries=[] entries=0 routable=true"

// ─── One provider: k8up's two adapters count as ONE registry entry ─────────
//
// Five members (k8up lists `retention`); `backup` is required by both k8up
// adapters, and because over-subscription counts registry entries, two
// adapters of one entry are one provider.

_pinInventoryOneProviderReadout: (_pinInventoryReadout & {#in: _pinInventoryOneProvider.#contracts}).out
_pinInventoryOneProviderReadout: "defined=5 unfulfilled=[] overSubscribed=[] fulfilled=true routable=true comparable=1 discriminated=false"

_pinInventoryOneProviderRequiredBy: strings.Join(list.Sort(_pinInventoryOneProvider.#contracts.requiredBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"], list.Ascending), ",")
_pinInventoryOneProviderRequiredBy: "opmodel.dev/catalogs/k8up/transformers/pre-backup-pod@2.0.0,opmodel.dev/catalogs/k8up/transformers/schedule@2.0.0"

// A contract required by transformers from two catalogs lists both.
_pinInventoryOneProviderContainer: strings.Join(list.Sort(_pinInventoryOneProvider.#contracts.requiredBy["opmodel.dev/catalogs/opm/resources/container@v1beta1"], list.Ascending), ",")
_pinInventoryOneProviderContainer: "opmodel.dev/catalogs/k8up/transformers/schedule@2.0.0,opmodel.dev/catalogs/opm/transformers/deployment@1.0.0"

_pinInventoryOneProviderDefinedBy: "\(_pinInventoryOneProvider.#contracts.definedBy["opmodel.dev/catalogs/k8up/traits/retention@v1alpha1"])"
_pinInventoryOneProviderDefinedBy: "opmodel.dev/catalogs/k8up@v2"

// providedBy names the registry key once, however many of its transformers
// require the contract. Joined without re-sorting, so the pin also holds
// the list's own order.
_pinInventoryOneProviderProvidedBy: "\(len(_pinInventoryOneProvider.#contracts.providedBy))|\(strings.Join(_pinInventoryOneProvider.#contracts.providedBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"], ","))"
_pinInventoryOneProviderProvidedBy: "1|opmodel.dev/catalogs/k8up@v2"

// ─── Two providers: over-subscribed, and the value STILL EVALUATES ──────────
//
// This is 0015:D18's whole point pinned: `routable: false` is a value a caller
// reads, not a bottom. #composedTransformers is intact beside it, and the
// report names the contract.

_pinInventoryTwoProvidersReadout: (_pinInventoryReadout & {#in: _pinInventoryTwoProviders.#contracts}).out
_pinInventoryTwoProvidersReadout: "defined=5 unfulfilled=[] overSubscribed=[opmodel.dev/catalogs/opm/traits/backup@v1alpha1] fulfilled=true routable=false comparable=1 discriminated=false"

_pinInventoryTwoProvidersRequiredBy: strings.Join(list.Sort(_pinInventoryTwoProviders.#contracts.requiredBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"], list.Ascending), ",")
_pinInventoryTwoProvidersRequiredBy: "opmodel.dev/catalogs/k8up/transformers/pre-backup-pod@2.0.0,opmodel.dev/catalogs/k8up/transformers/schedule@2.0.0,opmodel.dev/catalogs/velero/transformers/backup@1.4.0"

_pinInventoryTwoProvidersIntact: "\(len(_pinInventoryTwoProviders.#composedTransformers))|\(_pinInventoryTwoProviders.#contracts.definedBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"])"
_pinInventoryTwoProvidersIntact: "4|opmodel.dev/catalogs/opm@v1"

_pinInventoryTwoProvidersProvidedBy: "\(len(_pinInventoryTwoProviders.#contracts.providedBy))|\(strings.Join(_pinInventoryTwoProviders.#contracts.providedBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"], ","))"
_pinInventoryTwoProvidersProvidedBy: "1|opmodel.dev/catalogs/k8up@v2,opmodel.dev/catalogs/velero@v1"

// ─── Disabled provider: reads exactly as base only ──────────────────────────
//
// The k8up entry is present in the file and contributes nothing: not its
// `retention` contract to `defined` or `definedBy`, not its adapters to any
// requiredBy list. `backup` is back to unfulfilled.

_pinInventoryDisabledProviderReadout: (_pinInventoryReadout & {#in: _pinInventoryDisabledProvider.#contracts}).out
_pinInventoryDisabledProviderReadout: "defined=4 unfulfilled=[opmodel.dev/catalogs/opm/traits/backup@v1alpha1] overSubscribed=[] fulfilled=false routable=true comparable=0 discriminated=true"

_pinInventoryDisabledProviderAbsent: "\(_pinInventoryDisabledProvider.#contracts.definedBy["opmodel.dev/catalogs/k8up/traits/retention@v1alpha1"] == _|_)|\(len(_pinInventoryDisabledProvider.#contracts.requiredBy["opmodel.dev/catalogs/opm/resources/container@v1beta1"]))|\(len(_pinInventoryDisabledProvider.#contracts.requiredBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"]))"
_pinInventoryDisabledProviderAbsent: "true|1|0"

// A disabled entry provides nothing: its adapters' `backup` demand is not a key.
_pinInventoryDisabledProviderProvidedBy: "\(len(_pinInventoryDisabledProvider.#contracts.providedBy))"
_pinInventoryDisabledProviderProvidedBy: "0"

// ─── Two majors of one provider catalog: TWO providers ──────────────────────
//
// k8up@v2 and k8up@v3 each ship one adapter over `backup`. Their transformers'
// stamped metadata.modulePath is major-free, so a count keyed by it would see
// one catalog; the count is keyed by registry key, as the render build's is,
// so the platform is over-subscribed and not routable.

_pinInventoryTwoMajorsReadout: (_pinInventoryReadout & {#in: _pinInventoryTwoMajors.#contracts}).out
_pinInventoryTwoMajorsReadout: "defined=4 unfulfilled=[] overSubscribed=[opmodel.dev/catalogs/opm/traits/backup@v1alpha1] fulfilled=true routable=false comparable=0 discriminated=true"

_pinInventoryTwoMajorsProvidedBy: "\(len(_pinInventoryTwoMajors.#contracts.providedBy))|\(strings.Join(_pinInventoryTwoMajors.#contracts.providedBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"], ","))"
_pinInventoryTwoMajorsProvidedBy: "1|opmodel.dev/catalogs/k8up@v2,opmodel.dev/catalogs/k8up@v3"

// ─── Two providers, defining catalog disabled or absent ─────────────────────
//
// Nothing enabled defines `backup`, so `defined`, `definedBy` and `requiredBy`
// are empty; the two providers still count, because fulfilment is read off
// each transformer's own requirement and not off the defining member.

_pinInventoryDefinerDisabledReadout: (_pinInventoryReadout & {#in: _pinInventoryDefinerDisabled.#contracts}).out
_pinInventoryDefinerDisabledReadout: "defined=0 unfulfilled=[] overSubscribed=[opmodel.dev/catalogs/opm/traits/backup@v1alpha1] fulfilled=true routable=false comparable=0 discriminated=true"

_pinInventoryDefinerDisabledMaps: "\(len(_pinInventoryDefinerDisabled.#contracts.definedBy))\(len(_pinInventoryDefinerDisabled.#contracts.requiredBy))"
_pinInventoryDefinerDisabledMaps: "00"

_pinInventoryDefinerDisabledProvidedBy: "\(len(_pinInventoryDefinerDisabled.#contracts.providedBy))|\(strings.Join(_pinInventoryDefinerDisabled.#contracts.providedBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"], ","))"
_pinInventoryDefinerDisabledProvidedBy: "1|opmodel.dev/catalogs/k8up@v2,opmodel.dev/catalogs/velero@v1"

_pinInventoryDefinerAbsentReadout: (_pinInventoryReadout & {#in: _pinInventoryDefinerAbsent.#contracts}).out
_pinInventoryDefinerAbsentReadout: "defined=0 unfulfilled=[] overSubscribed=[opmodel.dev/catalogs/opm/traits/backup@v1alpha1] fulfilled=true routable=false comparable=0 discriminated=true"

_pinInventoryDefinerAbsentProvidedBy: "\(len(_pinInventoryDefinerAbsent.#contracts.providedBy))|\(strings.Join(_pinInventoryDefinerAbsent.#contracts.providedBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"], ","))"
_pinInventoryDefinerAbsentProvidedBy: "1|opmodel.dev/catalogs/k8up@v2,opmodel.dev/catalogs/velero@v1"

// ─── Optional demands do not count as provision ─────────────────────────────
//
// The restic entry's adapter names `backup` only under optionalTraits, so it
// is not a provider: providedBy has no `backup` key and the readout is base
// only's, `backup` unfulfilled and the platform still routable.

_pinInventoryOptionalOnlyReadout: (_pinInventoryReadout & {#in: _pinInventoryOptionalOnly.#contracts}).out
_pinInventoryOptionalOnlyReadout: "defined=4 unfulfilled=[opmodel.dev/catalogs/opm/traits/backup@v1alpha1] overSubscribed=[] fulfilled=false routable=true comparable=0 discriminated=true"

_pinInventoryOptionalOnlyProvidedBy: "\(len(_pinInventoryOptionalOnly.#contracts.providedBy))|\(_pinInventoryOptionalOnly.#contracts.providedBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"] == _|_)"
_pinInventoryOptionalOnlyProvidedBy: "0|true"

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

// ─── A declared reverse index is inert, not refused ─────────────────────────
//
// Closedness does not reject an undeclared definition field on #Platform
// (measured 2026-09-13, cue v0.17.1): the value evaluates and reads the field
// back. What the platform-registry requirement holds is that NOTHING reads
// it: the composed fold and the inventory of the one-provider platform are
// unchanged by its presence.
_pinInventoryWithMatchers: _pinInventoryOneProvider & {
	#matchers: "opmodel.dev/catalogs/opm/traits/backup@v1alpha1": ["nothing-reads-this"]
}
_pinInventoryWithMatchersInert:      "\(len(_pinInventoryWithMatchers.#matchers))|\(len(_pinInventoryWithMatchers.#composedTransformers))|\((_pinInventoryReadout & {#in: _pinInventoryWithMatchers.#contracts}).out)"
_pinInventoryWithMatchersInert:      "1|3|defined=5 unfulfilled=[] overSubscribed=[] fulfilled=true routable=true comparable=1 discriminated=false"
_pinInventoryWithMatchersRequiredBy: strings.Join(list.Sort(_pinInventoryWithMatchers.#contracts.requiredBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"], list.Ascending), ",")
_pinInventoryWithMatchersRequiredBy: _pinInventoryOneProviderRequiredBy

// ─── The definition evaluates with no registry at all ───────────────────────

_pinInventoryBare: (_pinInventoryReadout & {#in: #Platform.#contracts}).out
_pinInventoryBare: "defined=0 unfulfilled=[] overSubscribed=[] fulfilled=true routable=true comparable=0 discriminated=true"

_pinInventoryBareProvidedBy: "\(len(#Platform.#contracts.providedBy))"
_pinInventoryBareProvidedBy: "0"

_pinInventoryBareCollisions: (_pinInventoryCollisionReadout & {#in: #Platform.#contracts}).out
_pinInventoryBareCollisions: "collisions=[] collidingEntries=[] entries=0 routable=true"

// ─── Two majors sharing keys: collisions, and the value STILL EVALUATES ─────
//
// opm@v1 and opm@v2 both list the container, scaling, backup and the
// stateless blueprint. Folding a key two enabled entries list conflicted on
// metadata.catalogVersion in `defined` and on the registry key in
// `definedBy`, so the whole platform was bottom. Only single-definer keys
// fold now; the rest are reported, and the platform is not routable.

// Existing fields only: red before the fold, green after it.
_pinInventoryCollideIntact: "routable=\(_pinInventoryCollide.#contracts.routable) composed=\(len(_pinInventoryCollide.#composedTransformers))"
_pinInventoryCollideIntact: "routable=false composed=2"

// Only `volume`, which opm@v2 alone lists, is defined; nothing is
// over-subscribed, yet the platform is not routable.
_pinInventoryCollideReadout: (_pinInventoryReadout & {#in: _pinInventoryCollide.#contracts}).out
_pinInventoryCollideReadout: "defined=1 unfulfilled=[] overSubscribed=[] fulfilled=true routable=false comparable=0 discriminated=true"

// Every shared key, sorted, each naming both majors' registry keys.
_pinInventoryCollideCollisions: (_pinInventoryCollisionReadout & {#in: _pinInventoryCollide.#contracts}).out
_pinInventoryCollideCollisions: "collisions=[opmodel.dev/catalogs/opm/blueprints/stateless-workload@v1alpha1,opmodel.dev/catalogs/opm/resources/container@v1beta1,opmodel.dev/catalogs/opm/traits/backup@v1alpha1,opmodel.dev/catalogs/opm/traits/scaling@v1beta1] collidingEntries=[opmodel.dev/catalogs/opm/blueprints/stateless-workload@v1alpha1=opmodel.dev/catalogs/opm@v1+opmodel.dev/catalogs/opm@v2;opmodel.dev/catalogs/opm/resources/container@v1beta1=opmodel.dev/catalogs/opm@v1+opmodel.dev/catalogs/opm@v2;opmodel.dev/catalogs/opm/traits/backup@v1alpha1=opmodel.dev/catalogs/opm@v1+opmodel.dev/catalogs/opm@v2;opmodel.dev/catalogs/opm/traits/scaling@v1beta1=opmodel.dev/catalogs/opm@v1+opmodel.dev/catalogs/opm@v2] entries=4 routable=false"

// The key only the second major lists folds as before: defined by opm@v2,
// required by nothing.
_pinInventoryCollideDefinedBy: "\(len(_pinInventoryCollide.#contracts.definedBy))|\(_pinInventoryCollide.#contracts.definedBy["opmodel.dev/catalogs/opm/resources/volume@v1beta1"])|\(len(_pinInventoryCollide.#contracts.requiredBy["opmodel.dev/catalogs/opm/resources/volume@v1beta1"]))"
_pinInventoryCollideDefinedBy: "1|opmodel.dev/catalogs/opm@v2|0"

// LIMITATION PIN. This pins a known blind spot on purpose: a colliding key
// leaves `defined`, so it also leaves `requiredBy`, `unfulfilled` and
// `comparable`. `backup` is unfulfilled on base only (fulfilled=false
// above), and deployment@1.0.0 and deployment@2.0.0 share equal predicates
// over the container, yet this platform reads fulfilled=true and
// discriminated=true; only routable=false tells the truth. A future fix
// that keys the reports over colliding keys changes this pin DELIBERATELY.
_pinInventoryCollideLimitation: "\(_pinInventoryCollide.#contracts.requiredBy["opmodel.dev/catalogs/opm/resources/container@v1beta1"] == _|_)|\(_pinInventoryCollide.#contracts.requiredBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"] == _|_)|\(_pinInventoryCollide.#contracts.fulfilled)|\(_pinInventoryCollide.#contracts.discriminated)|\(_pinInventoryCollide.#contracts.routable)"
_pinInventoryCollideLimitation: "true|true|true|true|false"

// ─── A disabled second major: reads exactly as base only ────────────────────
//
// A disabled entry is never a definer, so nothing collides and its `volume`
// is not defined.

_pinInventoryCollideDisabledReadout: (_pinInventoryReadout & {#in: _pinInventoryCollideDisabled.#contracts}).out
_pinInventoryCollideDisabledReadout: _pinInventoryBaseOnlyReadout

_pinInventoryCollideDisabledCollisions: "\((_pinInventoryCollisionReadout & {#in: _pinInventoryCollideDisabled.#contracts}).out)|\(_pinInventoryCollideDisabled.#contracts.definedBy["opmodel.dev/catalogs/opm/resources/volume@v1beta1"] == _|_)"
_pinInventoryCollideDisabledCollisions: "collisions=[] collidingEntries=[] entries=0 routable=true|true"

// ─── A collision and an over-subscription, reported together ────────────────
//
// providedBy and overSubscribed are unaffected by collisions: `backup` is
// both a colliding key and over-subscribed by k8up@v2 and velero@v1.

_pinInventoryCollideOverSubscribedReadout: (_pinInventoryReadout & {#in: _pinInventoryCollideOverSubscribed.#contracts}).out
_pinInventoryCollideOverSubscribedReadout: "defined=1 unfulfilled=[] overSubscribed=[opmodel.dev/catalogs/opm/traits/backup@v1alpha1] fulfilled=true routable=false comparable=0 discriminated=true"

_pinInventoryCollideOverSubscribedCollisions: (_pinInventoryCollisionReadout & {#in: _pinInventoryCollideOverSubscribed.#contracts}).out
_pinInventoryCollideOverSubscribedCollisions: _pinInventoryCollideCollisions

_pinInventoryCollideOverSubscribedProvidedBy: "\(strings.Join(_pinInventoryCollideOverSubscribed.#contracts.providedBy["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"], ","))|\(len(_pinInventoryCollideOverSubscribed.#composedTransformers))"
_pinInventoryCollideOverSubscribedProvidedBy: "opmodel.dev/catalogs/k8up@v2,opmodel.dev/catalogs/velero@v1|4"

// ─── Three majors: each key names every major listing it ────────────────────

_pinInventoryCollideThreeMajorsCollisions: (_pinInventoryCollisionReadout & {#in: _pinInventoryCollideThreeMajors.#contracts}).out
_pinInventoryCollideThreeMajorsCollisions: "collisions=[opmodel.dev/catalogs/opm/blueprints/stateless-workload@v1alpha1,opmodel.dev/catalogs/opm/resources/container@v1beta1,opmodel.dev/catalogs/opm/traits/backup@v1alpha1,opmodel.dev/catalogs/opm/traits/scaling@v1beta1] collidingEntries=[opmodel.dev/catalogs/opm/blueprints/stateless-workload@v1alpha1=opmodel.dev/catalogs/opm@v1+opmodel.dev/catalogs/opm@v2;opmodel.dev/catalogs/opm/resources/container@v1beta1=opmodel.dev/catalogs/opm@v1+opmodel.dev/catalogs/opm@v2+opmodel.dev/catalogs/opm@v3;opmodel.dev/catalogs/opm/traits/backup@v1alpha1=opmodel.dev/catalogs/opm@v1+opmodel.dev/catalogs/opm@v2+opmodel.dev/catalogs/opm@v3;opmodel.dev/catalogs/opm/traits/scaling@v1beta1=opmodel.dev/catalogs/opm@v1+opmodel.dev/catalogs/opm@v2] entries=4 routable=false"

// `volume` is the only single-definer key, so defined and definedBy hold it
// alone.
_pinInventoryCollideThreeMajorsDefinedBy: "\(_pinInventoryCollideThreeMajors.#contracts.definedBy["opmodel.dev/catalogs/opm/resources/volume@v1beta1"])|\(len(_pinInventoryCollideThreeMajors.#contracts.defined))|\(len(_pinInventoryCollideThreeMajors.#contracts.definedBy))|\(len(_pinInventoryCollideThreeMajors.#composedTransformers))"
_pinInventoryCollideThreeMajorsDefinedBy: "opmodel.dev/catalogs/opm@v2|1|1|3"

// ─── Fixtures: the comparability report (0015:D5, OQ9) ──────────────────────
//
// A second, independent family, so the platforms above keep reading as the
// over-subscription story. One definition catalog lists the two
// catalog-fulfilled resources and the catalog-fulfilled trait; a second lists
// the provider-fulfilled `vault`. Every adapter gets its OWN catalog, because
// a platform admits a catalog whole: one transformer per catalog is what lets
// each platform below carry exactly the pair its scenario is about.

_pinCmpWidget: #Resource & {
	metadata: {
		name:       "widget"
		apiVersion: "v1beta1"
		fqn:        "opmodel.dev/catalogs/cmp-base/resources/widget@v1beta1"
	}
	spec: widget: size: int
}

_pinCmpGadget: #Resource & {
	metadata: {
		name:       "gadget"
		apiVersion: "v1beta1"
		fqn:        "opmodel.dev/catalogs/cmp-base/resources/gadget@v1beta1"
	}
	spec: gadget: size: int
}

_pinCmpTuning: #Trait & {
	metadata: {
		name:       "tuning"
		apiVersion: "v1beta1"
		fqn:        "opmodel.dev/catalogs/cmp-base/traits/tuning@v1beta1"
	}
	optional: bool | *true
	spec: tuning: level: int
	appliesTo: [_pinCmpWidget]
}

// The provider-fulfilled contract the report must NOT cover: a pair sharing
// only this one is `overSubscribed`'s business.
_pinCmpVault: #Trait & {
	metadata: {
		name:       "vault"
		apiVersion: "v1alpha1"
		fqn:        "opmodel.dev/catalogs/cmp-vault/traits/vault@v1alpha1"
	}
	fulfilment: "provider"
	optional:   bool | *false
	spec: vault: path: string
	appliesTo: [_pinCmpWidget]
}

_pinCmpBaseCatalog: #Catalog & {
	metadata: {
		modulePath: "opmodel.dev/catalogs/cmp-base@v1"
		version:    "1.0.0"
	}
	#resources: {
		(_pinCmpWidget.metadata.fqn): _pinCmpWidget
		(_pinCmpGadget.metadata.fqn): _pinCmpGadget
	}
	#traits: (_pinCmpTuning.metadata.fqn): _pinCmpTuning
}

_pinCmpVaultCatalog: #Catalog & {
	metadata: {
		modulePath: "opmodel.dev/catalogs/cmp-vault@v1"
		version:    "1.0.0"
	}
	#traits: (_pinCmpVault.metadata.fqn): _pinCmpVault
}

// One adapter, one catalog. `alpha` is the baseline predicate ({widget});
// every other adapter below is positioned against it.
_pinCmpOne: {
	#name: #NameType
	#demands: {...}
	out: #Catalog & {
		metadata: {
			modulePath: "opmodel.dev/catalogs/cmp-\(#name)@v1"
			version:    "1.0.0"
		}
		#transformers: "opmodel.dev/catalogs/cmp-\(#name)/transformers/\(#name)@1.0.0": #ComponentTransformer & {
			metadata: {
				name:        #name
				fqn:         "opmodel.dev/catalogs/cmp-\(#name)/transformers/\(#name)@1.0.0"
				description: "Pin fixture: comparability adapter \(#name)"
			}
			#demands
		}
	}
}

_pinCmpAlphaCatalog: (_pinCmpOne & {#name: "alpha", #demands: {
	requiredResources: (_pinCmpWidget.metadata.fqn): _pinCmpWidget
}}).out

// Identical predicate to alpha's, from a second catalog: the accidental
// two-catalogs-one-adapter case 0015:D5 exists for.
_pinCmpBetaCatalog: (_pinCmpOne & {#name: "beta", #demands: {
	requiredResources: (_pinCmpWidget.metadata.fqn): _pinCmpWidget
}}).out

// Strictly narrower than alpha: the same resource plus a required label.
_pinCmpGammaCatalog: (_pinCmpOne & {#name: "gamma", #demands: {
	requiredResources: (_pinCmpWidget.metadata.fqn): _pinCmpWidget
	requiredLabels: "opm.opmodel.dev/workload-type": "stateless"
}}).out

// Same label KEY as gamma, different VALUE: incomparable with it.
_pinCmpDeltaCatalog: (_pinCmpOne & {#name: "delta", #demands: {
	requiredResources: (_pinCmpWidget.metadata.fqn): _pinCmpWidget
	requiredLabels: "opm.opmodel.dev/workload-type": "stateful"
}}).out

// A distinct required TRAIT: incomparable with gamma, which is what labels
// alone would miss (SPEC.md § 3.4, "Why the predicate is every required
// demand, not only labels").
_pinCmpEpsilonCatalog: (_pinCmpOne & {#name: "epsilon", #demands: {
	requiredResources: (_pinCmpWidget.metadata.fqn): _pinCmpWidget
	requiredTraits: (_pinCmpTuning.metadata.fqn):    _pinCmpTuning
}}).out

// The same trait, declared OPTIONAL: predicate is the resource alone, so
// zeta reads exactly as alpha does (0010:D32).
_pinCmpZetaCatalog: (_pinCmpOne & {#name: "zeta", #demands: {
	requiredResources: (_pinCmpWidget.metadata.fqn): _pinCmpWidget
	optionalTraits: (_pinCmpTuning.metadata.fqn):    _pinCmpTuning
}}).out

// Two adapters requiring the provider-fulfilled trait and nothing else.
_pinCmpEtaCatalog: (_pinCmpOne & {#name: "eta", #demands: {
	requiredTraits: (_pinCmpVault.metadata.fqn): _pinCmpVault
}}).out

_pinCmpThetaCatalog: (_pinCmpOne & {#name: "theta", #demands: {
	requiredTraits: (_pinCmpVault.metadata.fqn): _pinCmpVault
}}).out

// One catalog carrying two adapters over the provider-fulfilled trait: the
// k8up shape, in the family where nothing else shares a bucket with them.
_pinCmpDualCatalog: #Catalog & {
	metadata: {
		modulePath: "opmodel.dev/catalogs/cmp-dual@v1"
		version:    "1.0.0"
	}
	#transformers: {
		"opmodel.dev/catalogs/cmp-dual/transformers/lambda@1.0.0": #ComponentTransformer & {
			metadata: {
				name:        "lambda"
				fqn:         "opmodel.dev/catalogs/cmp-dual/transformers/lambda@1.0.0"
				description: "Pin fixture: one provider catalog's first adapter"
			}
			requiredTraits: (_pinCmpVault.metadata.fqn): _pinCmpVault
		}
		"opmodel.dev/catalogs/cmp-dual/transformers/mu@1.0.0": #ComponentTransformer & {
			metadata: {
				name:        "mu"
				fqn:         "opmodel.dev/catalogs/cmp-dual/transformers/mu@1.0.0"
				description: "Pin fixture: one provider catalog's second adapter"
			}
			requiredTraits: (_pinCmpVault.metadata.fqn): _pinCmpVault
		}
	}
}

// Two adapters with identical predicates over TWO catalog-fulfilled
// resources: the pair is found in both buckets and must collapse to one row.
_pinCmpIotaCatalog: (_pinCmpOne & {#name: "iota", #demands: {
	requiredResources: {
		(_pinCmpWidget.metadata.fqn): _pinCmpWidget
		(_pinCmpGadget.metadata.fqn): _pinCmpGadget
	}
}}).out

_pinCmpKappaCatalog: (_pinCmpOne & {#name: "kappa", #demands: {
	requiredResources: {
		(_pinCmpWidget.metadata.fqn): _pinCmpWidget
		(_pinCmpGadget.metadata.fqn): _pinCmpGadget
	}
}}).out

// ─── The comparability platforms ────────────────────────────────────────────

_pinCmpPlatform: {
	#name: #NameType
	#catalogs: [...#Catalog]
	out: #Platform & {
		metadata: name: #name
		type: "kubernetes"
		#registry: {
			for c in #catalogs {(c.metadata.modulePath): #catalog: c}
		}
	}
}

_pinCmpIdentical: (_pinCmpPlatform & {#name: "cmp-identical", #catalogs: [
	_pinCmpBaseCatalog, _pinCmpAlphaCatalog, _pinCmpBetaCatalog,
]}).out

_pinCmpNarrower: (_pinCmpPlatform & {#name: "cmp-narrower", #catalogs: [
	_pinCmpBaseCatalog, _pinCmpAlphaCatalog, _pinCmpGammaCatalog,
]}).out

_pinCmpLabelValues: (_pinCmpPlatform & {#name: "cmp-label-values", #catalogs: [
	_pinCmpBaseCatalog, _pinCmpGammaCatalog, _pinCmpDeltaCatalog,
]}).out

_pinCmpDistinctTrait: (_pinCmpPlatform & {#name: "cmp-distinct-trait", #catalogs: [
	_pinCmpBaseCatalog, _pinCmpEpsilonCatalog, _pinCmpGammaCatalog,
]}).out

_pinCmpOptional: (_pinCmpPlatform & {#name: "cmp-optional", #catalogs: [
	_pinCmpBaseCatalog, _pinCmpZetaCatalog, _pinCmpGammaCatalog,
]}).out

_pinCmpTwoContracts: (_pinCmpPlatform & {#name: "cmp-two-contracts", #catalogs: [
	_pinCmpBaseCatalog, _pinCmpIotaCatalog, _pinCmpKappaCatalog,
]}).out

_pinCmpProviderOnly: (_pinCmpPlatform & {#name: "cmp-provider-only", #catalogs: [
	_pinCmpBaseCatalog, _pinCmpVaultCatalog, _pinCmpEtaCatalog, _pinCmpThetaCatalog,
]}).out

_pinCmpOneProviderCatalog: (_pinCmpPlatform & {#name: "cmp-one-provider-catalog", #catalogs: [
	_pinCmpBaseCatalog, _pinCmpVaultCatalog, _pinCmpDualCatalog,
]}).out

// beta is present in the file and disabled: its predicate is identical to
// alpha's and it must still never be paired.
_pinCmpDisabled: _pinCmpIdentical & {
	#registry: (_pinCmpBetaCatalog.metadata.modulePath): enable: false
}

// `comparable` rendered as one sorted, fully forced string per platform:
// "<broader>><narrower>@[<sorted contracts>]", rows joined by a space. An
// empty report joins to "".
_pinCmpRows: {
	#in: #ContractInventory
	out: strings.Join(list.Sort([for r in #in.comparable {
		"\(r.broader)>\(r.narrower)@[\(strings.Join(list.Sort(r.contracts, list.Ascending), ","))]"
	}], list.Ascending), " ")
}

// ─── Identical predicates across two catalogs: ONE row ──────────────────────

_pinCmpIdenticalRows: (_pinCmpRows & {#in: _pinCmpIdentical.#contracts}).out
_pinCmpIdenticalRows: "opmodel.dev/catalogs/cmp-alpha/transformers/alpha@1.0.0>opmodel.dev/catalogs/cmp-beta/transformers/beta@1.0.0@[opmodel.dev/catalogs/cmp-base/resources/widget@v1beta1]"

// 0015:D18 on the new report: an undiscriminated platform STILL EVALUATES.
// The composed fold is intact and both transformer FQNs read back off the row.
_pinCmpIdenticalEvaluates: "\(len(_pinCmpIdentical.#composedTransformers))|\(_pinCmpIdentical.#contracts.discriminated)|\(_pinCmpIdentical.#contracts.comparable[0].broader)|\(_pinCmpIdentical.#contracts.comparable[0].narrower)|\(len(_pinCmpIdentical.#contracts.comparable[0].contracts))"
_pinCmpIdenticalEvaluates: "2|false|opmodel.dev/catalogs/cmp-alpha/transformers/alpha@1.0.0|opmodel.dev/catalogs/cmp-beta/transformers/beta@1.0.0|1"

// ─── A strictly narrower predicate: ONE row, the broader one named first ────

_pinCmpNarrowerRows: (_pinCmpRows & {#in: _pinCmpNarrower.#contracts}).out
_pinCmpNarrowerRows: "opmodel.dev/catalogs/cmp-alpha/transformers/alpha@1.0.0>opmodel.dev/catalogs/cmp-gamma/transformers/gamma@1.0.0@[opmodel.dev/catalogs/cmp-base/resources/widget@v1beta1]"

// ─── Differing required label VALUES: nothing ───────────────────────────────

_pinCmpLabelValuesRows: "[\((_pinCmpRows & {#in: _pinCmpLabelValues.#contracts}).out)]\(_pinCmpLabelValues.#contracts.discriminated)"
_pinCmpLabelValuesRows: "[]true"

// ─── A distinct required TRAIT: nothing ─────────────────────────────────────
//
// epsilon requires {widget, tuning}; gamma requires {widget, workload-type}.
// On requiredLabels alone epsilon declares none and would read as a subset of
// gamma — the false positive this pin exists to keep out.

_pinCmpDistinctTraitRows: "[\((_pinCmpRows & {#in: _pinCmpDistinctTrait.#contracts}).out)]\(_pinCmpDistinctTrait.#contracts.discriminated)"
_pinCmpDistinctTraitRows: "[]true"

// ─── An optional demand does not widen a predicate ──────────────────────────
//
// zeta's optionalTraits is invisible, so its predicate is {widget} and gamma's
// is strictly larger: ONE row. Were the optional map folded in, zeta would
// read {widget, tuning} and the two would be incomparable — no row at all.

_pinCmpOptionalRows: (_pinCmpRows & {#in: _pinCmpOptional.#contracts}).out
_pinCmpOptionalRows: "opmodel.dev/catalogs/cmp-zeta/transformers/zeta@1.0.0>opmodel.dev/catalogs/cmp-gamma/transformers/gamma@1.0.0@[opmodel.dev/catalogs/cmp-base/resources/widget@v1beta1]"

// ─── A pair sharing TWO catalog-fulfilled contracts: one row, both names ────

_pinCmpTwoContractsRows: (_pinCmpRows & {#in: _pinCmpTwoContracts.#contracts}).out
_pinCmpTwoContractsRows: "opmodel.dev/catalogs/cmp-iota/transformers/iota@1.0.0>opmodel.dev/catalogs/cmp-kappa/transformers/kappa@1.0.0@[opmodel.dev/catalogs/cmp-base/resources/gadget@v1beta1,opmodel.dev/catalogs/cmp-base/resources/widget@v1beta1]"

// ─── Provider-fulfilled only: overSubscribed fires, comparable does not ─────
//
// eta and theta have IDENTICAL predicates and come from two catalogs. Their
// one shared contract is provider-fulfilled, so the comparability report skips
// them and the existing arity guard is what names the trait.

_pinCmpProviderOnlyReadout: (_pinInventoryReadout & {#in: _pinCmpProviderOnly.#contracts}).out
_pinCmpProviderOnlyReadout: "defined=4 unfulfilled=[] overSubscribed=[opmodel.dev/catalogs/cmp-vault/traits/vault@v1alpha1] fulfilled=true routable=false comparable=0 discriminated=true"

// ...and two adapters of ONE provider catalog trip neither report.
_pinCmpOneProviderCatalogReadout: (_pinInventoryReadout & {#in: _pinCmpOneProviderCatalog.#contracts}).out
_pinCmpOneProviderCatalogReadout: "defined=4 unfulfilled=[] overSubscribed=[] fulfilled=true routable=true comparable=0 discriminated=true"

// ─── A disabled entry's transformer is never paired ─────────────────────────

_pinCmpDisabledRows: "\(len(_pinCmpDisabled.#composedTransformers))|[\((_pinCmpRows & {#in: _pinCmpDisabled.#contracts}).out)]\(_pinCmpDisabled.#contracts.discriminated)"
_pinCmpDisabledRows: "1|[]true"
