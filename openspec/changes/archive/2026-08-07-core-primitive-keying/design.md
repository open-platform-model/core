## Context

`core` types every primitive's key with one `#FQNType` (`src/types.cue:52`) — `path/name@semver` — and derives the value: `src/resource.cue:18` computes `fqn: #FQNType & "\(modulePath)/\(name)@\(version)"`. All four kinds share that shape.

Enhancement `0001` D5 lifted these keys from major-only to SemVer deliberately, so two builds of one primitive at adjacent versions occupy distinct keys and divergent definitions surface as structured errors rather than colliding on a major bucket. That goal is accepted throughout `0010` and is not reversed here; only the mechanism moves, and it moves because the same key is being asked to serve two parties with opposite requirements.

`0010` D4 has flipped twice — catalog-major keys, then full-SemVer keys with subscription breadth, then the role split adopted here. The two rejected shapes are worth carrying because their defects bound what this one must not reintroduce:

- **Catalog-major keys** made every installed module key to `@v1`, so publishing `1.3.0` changed the transformer bodies every already-installed module renders against. Nobody edited a module and the output moved.
- **Full-SemVer contract keys** made a module's demand name the exact build it was authored against, which is the cross-catalog `backup` failure in the proposal.

## Goals / Non-Goals

**Goals:**

- A module's demand for a contract MUST survive a release of the catalog that declares it.
- A platform's transformer map MUST name the bytes it executes.
- Two API versions of one contract MUST be able to ship side by side in a single catalog build.
- A catalog MUST have a cheap, legitimate way to break one contract on purpose.
- The primitive/adapter distinction MUST be carried by the type system, not by remembering to exclude transformers field by field.

**Non-Goals:**

- **The compatibility gate.** D27's additive-only rule and `0011` D9's publish-side enforcement are `library` and `cli` work.
- **Ordering of API versions.** Match is exact-key; nothing compares two levels. The one reader that sorts them is a diagnostic in `library`, and its kube-aware comparator is `library-match-labels`.
- **`#CatalogMemberFQNGate`.** Ships in `core-identity-package` (`0011` D22).
- **Matching labels and fulfilment.** `core-platform-and-match`.
- **Re-keying the catalogs.** `catalogs-identity-authoring`, in `0010`'s plan.

## Decisions

### Two FQN types, split by role

```cue
#ContractFQNType: string & =~"^[a-z0-9._-]+(/[a-z0-9._-]+)*/[a-z0-9]([a-z0-9-]*[a-z0-9])?@v[0-9]+((alpha|beta)[0-9]+)?$"
#ImplFQNType:     string & =~"^…@\\d+\\.\\d+\\.\\d+(-…)?(\\+…)?$"
#FQNType:         #ContractFQNType | #ImplFQNType
```

`#ImplFQNType` is the form `core` carries today, unchanged. `#ContractFQNType` is new.

There is a deliberate visual collision with `#ModulePathType`, which also ends `@v1`, and it is safe because the two namespaces never meet in one field: a module path carries `@v1` as an **address**, a contract FQN carries it as a **key**. What must stay distinguishable is a contract key from an implementation key, and `@v1` versus `@1.2.0` does that.

A **semver-range-aware matcher** was rejected at every revision of D4 and stays rejected: it turns an O(1) keyed lookup into constraint solving, re-implements resolution CUE already performs for module dependencies, and does not address the cross-catalog case at all — the provider's key is not a range either.

### `apiVersion` follows the Kubernetes ladder

```cue
#APIVersionType: string & =~"^v[0-9]+((alpha|beta)[0-9]+)?$"
```

The form is not decoration. D34 keys D27's additive-only promise to the **level**: alpha promises nothing and its publish gate is off; beta and GA are gated in full, and a break requires a level bump that may ship beside its predecessor.

`core` MUST also expose `#APIVersionGated`, which reports whether the promise binds:

```cue
#APIVersionGated: {
	apiVersion!: #APIVersionType
	gated:       !strings.Contains(apiVersion, "alpha")
}
```

This is the only place the ladder is **interpreted** rather than matched, and it still introduces no ordering — the level is read off the string, never compared against another level.

The likely misreading is worth naming: a catalog's **release** version (`1.0.0-alpha.2`) and a contract's **level** (`v1beta1`) are independent axes, and only the second decides whether D27 binds. The day-one assignment has both mainline catalogs at `v1beta1` while they publish only `1.0.0-alpha.*`, so the two spellings disagree in the live regime rather than in a constructed example.

`#MajorVersionType` (`^v[0-9]+$`) is **untouched** and keeps naming module majors. `#APIVersionType` is its widened sibling, and they are separate types because they answer to different things.

### The shape splits; there is no shared parent

`#PrimitiveIdentity` covers `#Resource`, `#Trait`, `#Blueprint` and narrows `fqn` to `#ContractFQNType`. A new `#TransformerIdentity` carries `name` + `modulePath` + `catalogVersion` + `#ImplFQNType`, closed, with no `apiVersion`.

Deleting the field from a four-member shape was the minimal edit and was rejected as treating the symptom. **The shape is the mechanism**: name a struct after three things, admit a fourth, and every field added to it lands on the fourth for free. `apiVersion` is the one that has bitten; `fulfilment` (D37) and `matchLabels` (D36) were each kept off transformers by hand. The next field gets the same manual exclusion or the same defect.

Closing `#TransformerIdentity` makes `apiVersion` on a transformer **inexpressible rather than unread** — measured 2026-08-03 against cue v0.17.1, the pinned case yields `apiVersion: field not allowed`.

A kind-neutral shared parent (`#CatalogMemberIdentity`) was available and rejected narrowly: it saves repeating three field lines and reintroduces the straddle.

### `catalogVersion` is provenance, on all four kinds

The rename is four-kind where the `apiVersion` addition is three. A transformer's `catalogVersion` is its own key's source component, and it is the provenance both ends of a match read.

`moduleVersion` was rejected on collision — "module" already means three things in OPM (`#Module`, the CUE module, the module path), so on a primitive it reads as the version of the `#Module`, which is the field D2 deleted. Dropping the provenance field entirely was rejected because it is what lets a diagnostic say "this platform's provider was built against 1.0.0; this module needs 1.3.0" when the shapes are compatible but the provider lags.

### `fqn` is authored, and enforcement moves

`core` stops deriving `fqn`. Each catalog writes it at the definition site:

```cue
fqn: "\(id.RegistryPath)/resources/\(name)@\(apiVersion)"
```

Kind segments are retained. A flat FQN would make primitive names globally unique across all four kinds within a catalog, and `catalog_opm` already ships a resource named `secrets`.

The cost is accepted explicitly and is the author's: the value becomes visible and overridable at its definition site, in exchange for one identity source that a release moves by one edit. Enforcement **moves** rather than disappearing — from `core`'s unification, where a wrong value is inexpressible, to `#CatalogMemberFQNGate` at publish.

Two rejected alternatives are load-bearing, both measured 2026-07-27:

- **Remove `version` and author only `fqn`.** With nothing to interpolate, a catalog on `1.2.0` shipping `fqn: "…/secret-transformer@1.1.0"` passes `cue vet -c` with **exit 0**. The key names a build the catalog is not, silently, and under D4 that key is what modules match against permanently.
- **Derive `version` from `fqn`.** A CUE cycle — `t.fqn: cycle with field: version`.

### `#Blueprint` is a primitive

`core/SPEC.md:29` and `:38` list it under Constructs. It moves. It composes resources and traits rather than introducing vocabulary, but it is a fundamental building block a module attaches and its `spec` is a surface modules write against, so it earns the contract key and D27's promise.

Nothing else follows from the reclassification. D37's exclusion of `#Blueprint` from `fulfilment` stands on its own structural ground — `src/transformer.cue:54-64` has `requiredResources` and `requiredTraits` and no blueprint equivalent, so a transformer can never demand one — which makes a blueprint a primitive that nothing demands rather than a non-primitive.

## Risks / Trade-offs

**`core` loses the ability to refuse a wrong key, before the gate that replaces it exists.** The measured failure is exact: a catalog on `1.2.0` shipping a stale `fqn` vets clean at exit 0. This is why `core-identity-package` is not optional and why the two land in one alpha. Inside the repo the window is real; it does not reach a published artifact because nothing publishes until `core-alpha-release`.

**A wrong key is permanent once published.** Under D4 modules match against it forever. That raises the stakes on the gate rather than on this change, but it is the reason the trade was made with a named owner (`0011` D22) rather than on the promise of one.

**Two version spellings now live in one system.** `@v1beta1` on a contract and `@1.2.0` on an implementation, plus `@v1` on a module path. Accepted: the alternative — normalising to major at match time — creates two notions of FQN, the string the schema declares and the key the matcher uses, which is exactly the declared-versus-effective split `0010` exists to remove.

**Alpha contracts give up one class of protection.** D34 turns D27's gate off at alpha, so a default change on an alpha contract is caught by nothing: closedness still fails a removed field loudly at match time, but two builds disagreeing on a default unify to a non-concrete value and the render fails later naming a field rather than a build. Under the day-one assignment that is confined to `catalog_opm_experimental`'s three contracts.

**"Alpha contract inside an alpha catalog" reads as one thing and is two.** The most likely implementation error is gating on the catalog's release prerelease instead of the contract's level. Both mainline catalogs publish `1.0.0-alpha.*` and carry `v1beta1` contracts, so the correct behaviour and the plausible bug differ on every primitive currently shipping.

**The rename reaches every leaf in every catalog.** Mechanical, and large: ~68 contracts and ~50 transformers. It is `catalogs-identity-authoring`'s work, not this change's, but this change is what makes it necessary and the two must not be separated by a release.
