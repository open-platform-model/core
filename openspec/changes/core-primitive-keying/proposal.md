## Why

A primitive's FQN currently interpolates the catalog build it shipped in — `opmodel.dev/catalogs/opm/resources/backup@1.1.0`. That single string is doing two incompatible jobs, and the conflict is not theoretical.

`catalog_opm` defines a generic `backup` resource and trait with **no transformer of its own**, because the contract is meant to be fulfilled by whatever provider a platform installs. A `k8up` provider catalog ships the transformer that requires it. The demand key is the exact `catalog_opm` build the *module* compiled against; the supply key is whichever `catalog_opm` build the *provider* compiled against, fixed by the provider's own `cue.mod` because each catalog loads as its own root. Matching requires them to be **equal**, not compatible. Subscription breadth cannot repair it — subscribing to every `catalogs/opm` build supplies every build's own transformers, and `backup` has none.

So every `catalog_opm` release breaks backup for modules that adopt it, until the provider re-releases and the module is rebuilt to match: an N×M lockstep between two independently-released catalogs.

Enhancement `0010` D4 resolves this by splitting the key by **role**. What a module *demands* is a contract, keyed by that primitive's own API version, which a catalog release does not move. What a platform *executes* is an implementation, keyed by its build, because an operator upgrading a catalog is choosing new rendering logic and wants to know which bytes are running.

This change is that split, in the schema.

## What Changes

**Two FQN types, split by role.** `#ContractFQNType` is `path/name@vN` where `vN` is the primitive's own `apiVersion`. `#ImplFQNType` is `path/name@1.2.0` — the current form, kept for transformers. `#FQNType` becomes their disjunction for the map shapes that hold both.

**`apiVersion` on primitives only.** `#Resource`, `#Trait` and `#Blueprint` gain a required `metadata.apiVersion` typed `#APIVersionType`, admitting the Kubernetes ladder `vNalphaM | vNbetaM | vN`. `#ComponentTransformer` gains none — it is an adapter, not a primitive, and "this transformer's contract major" has no referent.

**`version` becomes `catalogVersion` on all four kinds.** It keeps its full SemVer and its source, and becomes provenance: the build a definition shipped in, never part of a contract key.

**`fqn` stops being derived and becomes authored.** `core` no longer computes it. Each catalog interpolates it at the primitive's definition site from its `identity` package, so `fqn`, `modulePath` and `catalogVersion` all trace to one source and a release moves them together. Enforcement moves from `core`'s unification to a publish gate — `#CatalogMemberFQNGate`, which ships in `core` under the sibling `core-identity-package` change.

**The shared identity shape splits.** Rather than trimming `apiVersion` off a four-member shape, the shape divides: primitives narrow `fqn` to `#ContractFQNType`; transformers get their own shape with `#ImplFQNType` and no `apiVersion`, closed so the field is inexpressible rather than merely unread. There is **no shared parent** — a parent spanning a category split is where the next field lands ambiguously.

**`#definitionName` is deleted from `#ComponentTransformer`.** Nothing reads it. It stays on the three primitives, where each builds its `spec!` key from it.

**`#Blueprint` is reclassified.** `SPEC.md:29` and `:38` currently list it under Constructs; it moves to Primitives. It composes resources and traits rather than introducing vocabulary, but it is still a building block a module attaches and its `spec` is a surface modules write against, so it earns the contract key and the additive-only promise.

## Capabilities

### New Capabilities

- `primitive-keying`: what a `#Resource`, `#Trait`, `#Blueprint` and `#ComponentTransformer` declare as their key — the two FQN types, `apiVersion` and the ladder it admits, `catalogVersion` as provenance, the authored rather than derived `fqn`, and the primitive/adapter split that decides which kind carries what.

### Modified Capabilities

None. `artifact-identity` supplies `#PackagePathType` for these keys' path portion, but no requirement of it changes — that is a dependency on `core-identity-shape`, recorded under Impact rather than as a delta.

## Impact

**Depends on `core-identity-shape`.** `#PackagePathType`, `#ArtifactRef` and the widened `#ModulePathType` must exist first. This change adds no path types of its own.

**Schema — this repo.** `src/types.cue` (`#APIVersionType`, `#ContractFQNType`, `#ImplFQNType`, `#FQNType` as a disjunction), `src/resource.cue`, `src/trait.cue`, `src/blueprint.cue`, `src/transformer.cue`. `SPEC.md` sections for all four kinds co-update, plus the two category lines that move `#Blueprint`.

**Version.** `feat!:` into the same unpublished `v1.0.0-alpha.4` line. Not published here — `core-alpha-release` is the cut point.

**The largest downstream surface in the enhancement.** Every leaf in every catalog is touched: `catalog_opm` (38 contracts — 7 resources, 26 traits, 5 blueprints — plus ~21 transformers), `catalog_kubernetes` (27 resources), `catalog_opm_experimental` (3 resources). Each leaf renames `version` to `catalogVersion`, adds an `apiVersion` where it is a primitive, and adds an authored `fqn` line. Day-one levels are `v1beta1` for the two mainline catalogs and `v1alpha1` for experimental — assigned on measured history, not caution: `catalog_opm`'s contract history is 715 field additions against 30 removals, and inspection shows most of the 30 are a single blueprint guard hoist.

**What this change does not deliver, and must not be read as delivering.** `core` loses its ability to refuse a wrong `fqn`, and the gate that replaces it (`#CatalogMemberFQNGate`) ships in `core-identity-package` under enhancement `0011` D22. Until both have landed there is a window in which an authored `fqn` is unchecked. The two are cut in the same alpha, so the window does not reach a published artifact — but it is real inside the repo and is why the two changes are sequenced together rather than independently.

**Design source.** `enhancements/0010` — D4, D21, D25, D33, D34, D44. `schemas/target.cue` carries `#PrimitiveIdentity`, `#TransformerIdentity`, `#APIVersionType` and `#APIVersionGated` as the target shapes.
