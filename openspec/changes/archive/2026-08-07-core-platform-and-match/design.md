## Context

Three surfaces in `core` are reshaped together because all three are consequences of enhancement `0010` D4 moving the contract key off the build.

**Selection.** `src/platform.cue:16-20` defines `#SubscriptionFilter` with `range`, `allow` and `deny`; `:31-33` puts it on `#Subscription` as optional, and the doc comment records that "when every field is absent the kernel selects the highest SemVer published for the path". Under the *old* build-keyed contracts, breadth was load-bearing: a platform had to cover the authorship history of its installed fleet, because each module's demand key named the exact build it compiled against. D4 removed that requirement, and with it the default's reason to exist.

**Matching.** `src/component.cue:19-21` documents `metadata.labels` as "unified from all attached resources, traits, and blueprints", and `src/types.cue`-adjacent `#LabelWorkloadType` (`component.cue:4`) names the key `core.opmodel.dev/workload-type`. The same field carries categorisation labels — `resource.opmodel.dev/category` and `trait.opmodel.dev/category` — that legitimately disagree between primitives.

**Demand.** `library/opm/compile/match.go` produces three outcomes with three different volumes, and only one of them stops a render. `SPEC.md`'s union claim and `match.go`'s `UnhandledTraits`-without-`UnhandledResources` asymmetry are both symptoms.

## Goals / Non-Goals

**Goals:**

- Catalog selection MUST be a pure function of committed source. Git-identical inputs MUST materialize identical catalog bytes, with no lockfile.
- Matching identity MUST be structurally separate from categorisation, so a genuine disagreement between two primitives is a conflict and an unrelated one is not.
- The matching vocabulary MUST be catalog-owned by construction, not by `core` agreeing not to look at some keys.
- A contract author MUST be able to declare that fulfilment comes from elsewhere.
- An unmet demand MUST be an error, with the exception written down by the author who wants it.

**Non-Goals:**

- **The library implementations.** Deleting `materialize/filter.go`, moving `match.go:111` off `metadata.labels`, raising the unresolved-demand error and enforcing the single-provider guard are three separate `library` slices.
- **Rewriting live platforms.** Moving a deployed `Platform` from `range` to a scalar `version` is cluster work, out of scope for both entries.
- **Arbitration between two providers.** Deferred, not rejected — re-measured 2026-08-01, cross-catalog fulfilment does not exist anywhere in the workspace (141 self-imports, **zero** foreign, across all three catalogs), so there is nothing to design against. Every candidate mechanism is purely additive later.
- **Rendering `matchLabels`.** Demonstrated working in `experiments/04` and deliberately not taken.

## Decisions

### A subscription names exactly one build

```cue
#Subscription: {
	enable:   bool | *true
	version!: #VersionType
}
```

`#SubscriptionFilter` is deleted entirely. The field is spelled `version`, singular, rather than a one-element list — and the cost is recorded rather than discovered later: widening back to multi-build becomes a breaking rename instead of a list relaxation.

**Every use of breadth collapses on inspection**, which is why the list form did not survive either:

- **Union coverage** — build `1.0.0` ships transformers A and B, build `1.2.0` ships A only, and listing both yields `A@1.2.0` + `B@1.0.0`. The one case breadth uniquely served, and it describes a catalog that made a breaking change without saying so. Under D28 the dropped transformer now fails the render loudly, and the fix belongs to the catalog author.
- **Gradual migration** does not structurally exist: under D4 a module demands resources and traits and never a transformer, so no module can stay on the old build.
- **Two API versions of one contract** ship side by side in a single build — that is what `core-primitive-keying`'s contract keys are for.
- **Testing a new build beside the old** is two platforms. Already expressible, names both behaviours, costs nothing hidden.

**Newest-wins tie-breaking** was defensible and rejected: it makes listing two builds indistinguishable in effect from listing one in every case *except* the dropped-transformer catalog bug — a silent arbitration bought to serve the one scenario that should fail loudly.

**Ranges plus a lockfile** is the more expressive answer and stays available. It was not chosen because it is strictly more machinery for the same guarantee, and the asymmetry matters: reintroducing `range` alongside a recorded resolution takes nothing away from a platform that already names its version, while an established floating default cannot be withdrawn cheaply once platforms depend on it.

### Matching moves to `matchLabels`, unified wholesale

`#Resource`, `#Trait`, `#Blueprint` and `#Component` each carry `matchLabels`. A component's is the unification of its attached primitives' — no filter, no key list. `metadata.labels` keeps its current meaning and is **never** unified upward.

Every filter design was measured working and rejected **together**, for one mechanical reason: a filtered union must **iterate**, and CUE refuses to iterate a struct holding an unset required field (`missing required field in for comprehension`). So each filter forced dropping `!` from the container's workload type — degrading "the author must pick" from a required field into an incomplete value. Separating the fields removes the filter and its costs at once:

- the structs unify wholesale, so the `!` marker survives;
- categorisation labels never meet structurally, rather than meeting behind a filter that agrees not to look;
- a genuine disagreement becomes a meaningful conflict (`conflicting values "daemon" and "stateful"`) rather than an artifact of unrelated labels sharing a namespace.

This also removes an asymmetry that already existed: `#ComponentTransformer` declares its matching *demand* in a dedicated field (`transformer.cue:46`), separate from its own `metadata.labels`. Only the component side declared matching *supply* inside `metadata.labels`. The two now agree.

`#LabelWorkloadType` is deleted from `core` and the key renamed `opm.opmodel.dev/workload-type`, owned by `catalog_opm`. This costs nothing: measured 2026-08-01, it has **zero readers** across `catalog_opm`, `catalog_kubernetes`, `library`, `cli`, `opm-operator` and `modules` — all write the literal string. Because `core` no longer names the key, the vocabulary is catalog-owned by construction, which is what turns the rename from a follow-on migration into a consequence of the design.

`matchLabels` is **not rendered**: it does not reach `#TransformerContext.componentLabels` and therefore appears on no rendered object.

### A contract declares its fulfilment source

```cue
fulfilment: *"catalog" | "provider"
```

On `#Resource` and `#Trait` only. `"catalog"` is the default, so every existing primitive is unchanged and nothing opts in by accident. `"provider"` means the declaring catalog ships no transformer for it, deliberately, and a platform must carry **exactly one** transformer *requiring* it — two is refused at materialize naming both catalog paths and the contract key; zero is D28's unresolved demand.

**Deriving it was the obvious alternative and is not computable.** D17 records that "which catalog ships FQN X?" cannot be answered with no platform in hand — the kind-segment count is not fixed (`…/opm/resources` against `…/opm/blueprints/workload`), so the owning catalog cannot be read off an FQN. It is also fragile in principle: a catalog later adding a transformer would silently change the contract's character.

**Detecting competing providers by predicate equality** was measured to have no false positives today (21 transformers in `catalog_opm`, 21 distinct predicates) and rejected because it false-*negatives* on the real case: a k8up transformer requiring `backup` + `schedule` and a Velero transformer requiring `backup` alone are still two providers of one contract, and their predicates differ.

A closed enum rather than a boolean `providedExternally`, so a third fulfilment mode does not require a breaking rename.

**`#Blueprint` is excluded structurally**, not by preference: `src/transformer.cue:54-64` has `requiredResources` and `requiredTraits` and no blueprint equivalent, so a transformer can never demand one and the field would be unreachable. A blueprint's fulfilment is that of the contracts it composes.

### Demand is required by default, with one opt-out

Every resource a component declares is required. Traits carry an explicit opt-out; an unhandled trait without one fails, and only the opted-out case degrades to a warning that continues.

The asymmetry is real rather than convenient: a component does not attach a resource it can do without, while a trait can be advisory — `optionalTraits` already exists on the *supply* side, and this is its demand-side counterpart. Giving resources an optionality marker too was rejected on that ground.

`0010` D28 leaves only the **spelling** to the implementing slice; what it fixes is that there is exactly one opt-out, that it lives on the demand side, and that its absence means required. This change picks the spelling and is where it becomes reviewable.

## Risks / Trade-offs

**A label disappears from every live workload.** Rendered objects carry `core.opmodel.dev/workload-type` today via the `componentLabels` fold at `src/transformer.cue:147-157`, and `matchLabels` is not rendered. This is the author's call and recorded as provisional — the opt-in render flag is a four-line struct-level guard, demonstrated in `experiments/04`, addable later without disturbing anything here. It was not shipped now because deciding where the flag lives is a separate question, and a runtime-only flag is ruled out by the byte-identical-render gate in `04-graduation.md`. It lands in the same window as the identity migration rather than adding a second one.

**Every live Platform with a range breaks.** Unavoidable and out of scope here. It is a small, enumerable edit per platform, and it is visible: the schema refuses the old shape rather than silently reinterpreting it.

**Catalog upgrades become manual.** Accepted. For platforms living in git and reconciling continuously, an upgrade that appears in a diff and gets reviewed is the correct interaction; automating the bump belongs to enhancement `0004`.

**Shipping this schema without the library slices leaves matching reading an emptied field.** `compile/match.go:111` reads `schema.MetadataLabels` to build the set `match.go:350` tests `requiredLabels` against, with further readers at `compile/module.go:197` and `schema/context.go:68`. This is exactly the gap the 2026-08-05 plan audit found and fixed by adding `library-match-labels` — noted here because the failure mode is a matcher that silently matches nothing rather than an error.

**The single-provider guard is materialize-time, not schema-time.** `core` can declare `fulfilment`; it cannot count transformers across a platform's materialized set. The guard is `library-contract-match`'s. Until it lands, `"provider"` is a declaration with no enforcement — which is strictly better than today, where the concept cannot be declared at all, but it is not the finished state.

**Deferring arbitration is a bet on current measurements.** Zero cross-catalog fulfilment exists today, so "exactly one provider" costs nothing. The first real provider ecosystem may want `prefer` lists or per-contract binding, and all of those remain purely additive to this decision.
