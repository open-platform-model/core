## Context

`core` today types an artifact's identity as a set of fragments that are recombined at the point of use. `#Module.metadata` (`src/module.cue:11-43`) declares `modulePath!` as a bare prefix, `name!` as kebab-case, a derived `nameSnakeCase`, and `version!`; `fqn` is `"\(modulePath)/\(name):\(version)"` typed `#ModuleFQNType`; `uuid` is `SHA1(OPMNamespace, fqn)`. `#Catalog.metadata` (`src/catalog.cue:61-68`) does the same with `"\(modulePath)@\(version)"` and a `*"0.0.0-dev"` default. `#ModuleInstance.metadata.uuid` (`src/module_instance.cue:25`) interpolates `#moduleMetadata.uuid` inline.

Three consequences follow, and they are what this change removes:

1. **The registry address is not recoverable from the artifact.** `modulePath` is a prefix, so every consumer that needs an OCI repository recomposes one. That composition is duplicated across `cli` and `library` and is why `0010` D1 exists.
2. **The version is in the key.** `fqn` interpolates `version`, so `module.uuid` moves on every release, and `instance.uuid` moves with it. `prune.go:107` skips deleting any object whose owner label disagrees with `Status.InstanceUUID`, which `reconcile/moduleinstance.go:308` repopulates from each new render — so every upgrade orphans what it removed, reporting success.
3. **Two spellings of one name.** `name` is kebab, `nameSnakeCase` is its snake projection, and the module path's leaf is a third independently-authored value that is supposed to equal one of them.

Enhancement `0010` is `accepted` with every open question resolved. This change implements the subset its `plan.yaml` calls `core-identity-shape`. The other three core slices (`core-primitive-keying`, `core-platform-and-match`, `0011:core-identity-package`) land into the same unpublished alpha and are separate changes; all four are cut once by `core-alpha-release`.

## Goals / Non-Goals

**Goals:**

- An artifact's declared `modulePath` MUST be the complete CUE module path, major suffix included, and MUST be the same string CUE, the registry and an `import` statement already agree on.
- A module path MUST decompose into its OCI repository and its major in exactly one place in the schema.
- `fqn` MUST be a value, not a recombination.
- Module artifact identity MUST distinguish majors and nothing finer.
- Instance identity MUST survive every upgrade of the module it deploys, a major bump included.
- A module's name MUST have one spelling.

**Non-Goals:**

- **Primitive keying.** `#Resource`, `#Trait`, `#Blueprint` and `#ComponentTransformer` keep the `modulePath` values they carry today. Retyping them to `#PackagePathType` is mechanical and belongs to this change only because the type is defined here; `apiVersion`, `catalogVersion` and authored `fqn` are `core-primitive-keying`.
- **Platform and match surface.** `#SubscriptionFilter`, `matchLabels`, `fulfilment` — `core-platform-and-match`.
- **`#IdentityPackage`.** It ships in `core` under `0011` D21, as `0011:core-identity-package`. This change defines the types it is built from and nothing more.
- **Publishing the alpha.** `core-alpha-release`.
- **Any migration of a live instance or a published artifact.** D18 subsumes the live-instance relabel into the `v0 → v1` fleet migration; the catalogs and the fleet are `0010`'s migration-phase slices.

## Decisions

### Two path types, not one widened type

`#ModulePathType` gains a terminal `@vN`; `#PackagePathType` is the current regex under a new name.

```cue
#ModulePathType:  string & =~"^[a-z0-9._-]+(/[a-z0-9._-]+)*@v[0-9]+$"
#PackagePathType: string & =~"^[a-z0-9._-]+(/[a-z0-9._-]+)*$"
```

An earlier revision of D1 widened one shared type and was amended (D20, merged into D1). The defect: every field typed with it inherited a major it has no use for. A primitive's major is structurally redundant — a `@vN` module publishes `vN.*` tags, so a primitive carrying a build SemVer already states its catalog's major. It is also not a path anyone writes: a consumer imports `opmodel.dev/catalogs/opm/resources` with no suffix and CUE resolves the major from `deps`.

Underscores were already legal in both regexes and stay legal, for a new reason: under D8 a module path *ends in* the module's own snake_case name, and every multi-word name contains one.

### Decomposition lives in `#ArtifactRef`

```cue
#ArtifactRef: {
	modulePath!: #ModulePathType
	_p: strings.SplitN(modulePath, "@", 2)
	registryPath: _p[0]
	major:        #MajorVersionType & _p[1]
	importPath:   modulePath
}
```

A module path carries at most one `@`, always terminal, so `SplitN(2)` is exact — CUE has no string slicing, so a `LastIndex`-plus-slice form is unavailable. `#MajorVersionType` already exists in `src/types.cue:30` and is currently used nowhere; this is the design its doc comment describes.

`importPath` is `modulePath` verbatim. It exists as a named field because it is the value a `cue.mod` dependency key carries, and naming it is what makes "nothing is recombined" checkable rather than implied.

### `fqn` is the module path

`#Module.metadata.fqn` and `#Catalog.metadata.fqn` are `modulePath`, typed `#ModulePathType`. `#ModuleFQNType` and `#CatalogFQNType` retire with the derivations they typed.

`uuid` keeps `SHA1(OPMNamespace, fqn)` unchanged. Its **input** changes, so every module's UUID moves exactly once — which is why this is a `feat!:` and why the fleet republishes once, in `0010`'s migration phase.

### The leaf constraint is expressed over one field

```cue
name!: #SnakeNameType
_leaf: strings.HasSuffix(_ref.registryPath, "/" + name)
_leaf: true
```

Hidden, because it is a check rather than a value a consumer reads. Today the same rule spans two independently-authored fields and is written down nowhere.

Only the **leaf** is constrained. CUE accepts hyphens in path segments, path segments are not CUE identifiers, and narrowing the whole path would make OPM unable to express its own GitHub organisation (`github.com/open-platform-model/...`). The leaf is different because it is also the CUE package name, and package names cannot contain hyphens.

`nameSnakeCase` and `#KebabToSnake` are deleted. With `name` already snake there is no projection left. `#KebabToPascal` and `#KebabToCamel` stay — `#Resource`, `#Trait` and `#Blueprint` keep kebab `#NameType` names and build their `spec!` keys from them.

### Instance identity derives from `registryPath`, not from `fqn`

```cue
// #Module.metadata
registryPath: _ref.registryPath

// #ModuleInstance.metadata
fqn:  "\(#moduleMetadata.registryPath):\(name):\(namespace)"
uuid: #UUIDType & cue_uuid.SHA1(OPMNamespace, fqn)
```

The two values answer different questions, and deriving one from the other forced them to agree when they must not:

- `module.uuid` is **artifact** identity. `@v2` and `@v3` are distinct modules under both CUE and Go semantics, so it MUST move across a major.
- `instance.uuid` is **ownership** identity — the `module-instance.opmodel.dev/uuid` label `prune.go:107` reads. It MUST survive every upgrade of the same deployment.

Stating `fqn` as a field rather than inlining the interpolation inside `uuid` is what makes the derivation reviewable in one place, and it mirrors `#Module`'s own `fqn → uuid` shape.

`registryPath` is not a spare value added for this: it is already computed by `#ArtifactRef` and has independent callers — it is the OCI repository every address-composition site in `cli` and `library` collapses into. Deriving instance identity from `name` instead was rejected on collision: `opmodel.dev/modules/jellyfin` and `example.com/jellyfin` both carry `name: "jellyfin"`, and a full module path is unique by construction.

### `core` asserts no version-major agreement

D40 had `core` assert `versionMajor == _ref.major` on both artifact types. **D43 removed it for `#Catalog` and D45 for `#Module`.** `identity/identity.cue` asserts the relation at the point both values are written, so a failure names the file the author has open; `core` re-deriving it tests the same relation over the same two values one hop downstream.

This is the one place where the enhancement's own documents were internally inconsistent when this change was opened — `schemas/target.cue` still carried the `core`-side assertion and `04-graduation.md` still required a test that both artifact types *refuse* the skew. Propagated 2026-08-05; recorded in `0010`'s history. **The behaviour specified here is D45's**, and the spec deltas pin the accepting direction explicitly so it is not later "fixed" back.

### Retained deliberately

`#Module.metadata.version!` stays (D38, amending D2). It has two readers: an instance derives its own version from it — `#moduleInstanceMetadata.version` is declared non-optionally at `src/transformer.cue:105` and is unfillable for a module rendered from disk — and it sources the `module.opmodel.dev/version` label (D9). Neither `fqn` nor `uuid` reads it, and that exclusion is what makes retaining it safe.

## Risks / Trade-offs

**Every module UUID and every instance UUID moves once.** Unavoidable — it is the point. Bounded by landing in one window: D41 was taken now rather than later specifically so this is the *last* time an instance UUID moves. Landed separately it would be a second fleet-wide relabelling carrying the same silent-orphaning exposure through a second cutover.

**A non-conformant identity package now carries no consumer-runnable major check.** Accepted, twice, by D43 and D45. `identity/identity.cue` is never evaluated as a package by a consumer — it reaches them only through the values it produced — and D11 keeps `cue mod publish` working, so that artifact class is not hypothetical. The skew then surfaces at `#SubscriptionSelection._majorAgrees` in a *platform author's* file about a *publisher's* mistake. Bounded by `0011` D8/D21 refusing a non-conformant identity file and `0011` D12 comparing `metadata.version` against `id.Version` for anything published through the tool. Removed outright by D43's recommended follow-on, which `0011:core-identity-package` implements.

**The `#SnakeNameType` retype is breaking in principle and inert in fact.** Measured 2026-08-05: zero hyphenated module names on either `modules/` branch. A rename surfacing during implementation means something was added under the old convention after that measurement — treat it as a signal, not as expected churn.

**`core` cannot enforce the identity-package wiring.** `#Module` has no way to reference an arbitrary module's identity package, so `metadata: {modulePath: id.ModulePath, version: id.Version}` is established by the template `opm module init` generates. CUE enforces it for free *while it is written* — editing the literal yields `conflicting values`. An author who **replaces** `id.Version` with a literal leaves nothing to conflict with, and that case is `0011` D12's publish check, not this change's.

**Every consumer breaks at once.** Accepted on the alpha argument: `@v1` has published only prereleases, so the compatibility promise has not started. Every consumer is a repo in this workspace pinning an explicit prerelease, so the retarget is a `task update-deps` sweep over an enumerable set, and rollback is a re-pin to `alpha.3`.
