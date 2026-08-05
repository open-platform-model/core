## Context

An OPM artifact — module or catalog — carries a committed `identity/identity.cue` holding the two values a release moves. Everything else about its identity derives from those two: the registry path, the major, the prefix every primitive hangs off, and the `metadata` the root package wires up.

`catalog_opm/src/identity/identity.cue` exists today and has a property worth stating before anything is designed around it: **it imports nothing within its module**, and it mirrors `core.#VersionType` locally rather than importing `core`, so that it stays at the bottom of the import graph and cannot create a cycle. Any validation design that changes that has taken something away.

Enhancement `0010` leaned on a schema for this file four separate times without one existing. This change ships it, plus the member gate that `0010` traded `core`'s `fqn` derivation away for.

## Goals / Non-Goals

**Goals:**

- The conformant shape of an identity package MUST exist in shipped code, not only in a design document.
- The catalog-member path and FQN rule MUST have exactly one statement, in `core`.
- Validation MUST produce CUE's own diagnostic, not a hand-written one.
- The identity package's import-free invariant MUST survive.
- Both schemas MUST be reachable by anything that needs them, including a module that depends on no catalog.

**Non-Goals:**

- **The publish pipeline.** Loading a tree, unifying it, formatting refusals — `cli`, enhancement `0011`.
- **The compatibility comparator.** `0011` D9's field-wise walk is `library`.
- **Making `identity.cue` import the schema.** Explicitly excluded; see below.
- **Migrating the existing identity files.** `catalogs-identity-authoring` and `modules-identity-authoring`, in `0010`'s plan.

## Decisions

### Both schemas ship in `core`

`core` is the only module everything already depends on. Shipping either in a catalog fails immediately: modules carry an identity package too (`0010` D38, `0011` D12), and a module need not depend on any particular catalog. Shipping the gate in `cli` fails for the transposed reason — a gate living in one consumer's binary cannot be run by anyone else, and it splits one validation route into two.

They ship together, in the same release, because they are checked by the same mechanism and because `0010`'s trades depend on both.

### Validation is unification; `core` ships no comparator

Neither schema comes with a Go-side expected-versus-found check. The consumer loads the value and unifies it against the definition.

A **procedural check in Go** — walk the package, look for `ModulePath` and `Version`, report what is missing — was the drafted approach and is rejected on two grounds. It is a second statement of the contract, and the two drift. And it produces a *worse* diagnostic on the interesting cases: a wrong type or a wrong constraint is not a missing field. `0011` D8 already frames the refusal as "this tree is not a conformant catalog" rather than "this field lacks an attribute"; unification is what makes that sentence true.

On the gate specifically, the discarded information is measurable: a blueprint one segment too deep fails on **both** `declaredModulePath` and `declaredFQN`, and `0010` D42 measured that CUE reports the second wrapped as `2 errors in empty disjunction`, because `#FQNType` is a disjunction. A string comparison throws that away.

### The identity package derives rather than repeats

```cue
#IdentityPackage: {
	ModulePath!: #ModulePathType
	Version!:    #VersionType

	_ref: #ArtifactRef & {modulePath: ModulePath}

	RegistryPath: _ref.registryPath
	Major:        _ref.major

	VersionMajor: "v" + strings.SplitN(Version, ".", 2)[0]
	VersionMajor: Major

	kindPrefix: {
		resources:    RegistryPath + "/resources"
		traits:       RegistryPath + "/traits"
		blueprints:   RegistryPath + "/blueprints"
		transformers: RegistryPath + "/transformers"
	}
}
```

Tooling writes exactly `ModulePath` and `Version`; everything else follows, so a publisher gains nothing new to keep in step.

`strings` is a CUE **builtin**, not a module import, so it adds no edge to the module graph and the import-free invariant is preserved. The invariant's accurate wording is "free of **intra-module** imports."

**`VersionMajor` is the only assertion of the version/path major relation in the entire system.** `0010` D40 originally had `core` assert it independently on both artifact types; D43 removed that for `#Catalog` and D45 for `#Module`, both citing this validation as what replaces it. That is the dependency this change discharges — and it is why the assertion belongs *here* rather than being another thing a consumer could omit.

**`kindPrefix` is enumerated, not a pattern constraint.** Measured in `0011/experiments/01`, finding (b): `[Kind=string]: …` is unusable at the call site — `id.kindPrefix.resources` yields `undefined field`, because a pattern constrains keys that exist rather than generating them.

The map is a **complete statement of the catalog's key space**, not a convenience for the common case: exactly one prefix per kind, no grouping subdirectory beneath any of them (`0010` D42). The gate builds both the path and the key from the same value, so a primitive one segment deeper is refused.

### The gate derives what was authored, and unification does the comparing

```cue
#CatalogMemberFQNGate: {
	identity!: #IdentityPackage
	kind!:     "resources" | "traits" | "blueprints" | "transformers"
	name!:     #NameType

	declaredFQN!:            #FQNType
	declaredModulePath!:     #PackagePathType
	declaredCatalogVersion!: #VersionType

	declaredAPIVersion?: #APIVersionType
	if kind != "transformers" {
		declaredAPIVersion!: #APIVersionType
	}

	declaredModulePath:     identity.kindPrefix[kind]
	declaredCatalogVersion: identity.Version

	_keyVersion: [
		if kind == "transformers" {identity.Version},
		declaredAPIVersion,
	][0]

	declaredFQN: identity.kindPrefix[kind] + "/" + name + "@" + _keyVersion
}
```

Each `declared*` field is stated twice — once as what the catalog authored, once as what identity implies. Unification is the check.

**The conditional optional is load-bearing and was measured** (2026-08-03, cue v0.17.1). `declaredAPIVersion` is optional at the top level and required for the three primitive kinds, because a transformer declares none (`0010` D44) and requiring it unconditionally would force ~50 leaves to author a value nothing reads. `_keyVersion`'s transformer branch is selected **before** `declaredAPIVersion` is reached, so CUE's laziness spares the absent optional. Measured: a transformer with the field absent yields the build with no error; a contract supplying it yields the apiVersion; a contract omitting it fails `declaredAPIVersion: field is required but not present`.

`apiVersion` is deliberately **not** checked against identity. Nothing implies it — it is a judgement about that primitive's contract, made by its author, which is the whole point of the field.

The gate is **not** part of the primitive identity shape. Expressing it there would re-derive `fqn` and undo `0010` D21. Unifying it is the check; the derivation stays out of `core`'s primitive definitions.

**Checking only primitives and skipping transformers** was rejected: `0010` D44 records that the gate's four-kind scope is correct and survives the primitive/adapter split — D17's rule binds a transformer's package path, and a transformer's build-keyed FQN is exactly what D21's stale-literal failure applies to. Only the shape's name changed (`#PrimitiveFQNGate` → `#CatalogMemberFQNGate`).

### `identity.cue` does not import `core`

The attractive alternative — have `identity/identity.cue` import `core` and embed `#IdentityPackage`, so plain `cue vet` catches non-conformance with no tooling at all — is **excluded**, and it is recorded rather than omitted because it is the first thing a reader will propose.

It would put the schema module at the bottom of every catalog's import graph to buy a check that works fine from outside. If the import-free invariant is ever revisited, this becomes the better design and `0010` D43's recommended follow-on (identity files embedding the shipped definition, so `VersionMajor` comes from the definition rather than from an author remembering to write it) becomes available with it. Until then, `core` **exports** the shape and the CLI does the unifying.

## Risks / Trade-offs

**The assertion this ships is the only one left.** `0010` D43 and D45 removed `core`'s copies on the strength of it. If `#IdentityPackage` ships wrong — or if the CLI's unification is skipped for some artifact class — nothing else catches a version whose major disagrees with its path, and the failure surfaces at `#SubscriptionSelection._majorAgrees` in a *platform author's* file about a *publisher's* mistake. The tests in this change are load-bearing for two other changes' correctness.

**Shipping the schema does not ship the enforcement.** `core` gains two definitions; nothing in `core` or `library` unifies against them. Until `cli-publish-pipeline` and `cli-catalog-member-gate` land, an authored `fqn` is unchecked and a non-conformant identity file is unrefused. That window is inside the workspace rather than in published artifacts, but it is longer than the alpha cut — the CLI slices come after `core-alpha-release`.

**An artifact published outside `opm publish` is never checked.** `0010` D11 keeps `cue mod publish` working and records that it is what every artifact published to date used. `identity/identity.cue` is never evaluated as a package by a consumer — it reaches them only through the values it produced — so for that artifact class both schemas are inert. Accepted by D43 and D45 explicitly; the residual exposure is stated in `0010/05-risks.md`.

**`kindPrefix` freezes the layout.** Exactly one prefix per kind, no grouping subdirectory. `catalog_opm`'s five blueprints sit at `…/blueprints/workload` today and must move up one segment. That is `catalogs-identity-authoring`'s work, but this change is what makes it mandatory rather than tidy.

**Adding these to `.tasks/spec-tracked.txt` commits to maintaining `SPEC.md` sections for them.** That is the intended outcome — they are consumer-facing contracts, and a catalog author meeting `#CatalogMemberFQNGate` for the first time needs the normative statement — but it is a standing obligation, not a one-off.
