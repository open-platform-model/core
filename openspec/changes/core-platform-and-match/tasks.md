# Tasks

**Sequencing.** Requires `core-identity-shape`. Independent of `core-primitive-keying` and `core-identity-package` except that all four land in `v1.0.0-alpha.4`. If `core-primitive-keying` lands first, the primitives it touches are the same files — expect to rebase, not to conflict semantically.

**A caution that outlives this change.** The library still reads `metadata.labels` for matching (`compile/match.go:111` via `schema/paths.go:71`, with further readers at `compile/module.go:197` and `schema/context.go:68`). Landing this schema without `library-match-labels` gives a matcher that silently matches nothing. Do not treat a green `task check` here as evidence the system works end to end.

**Commits.** Each group stages `src/*.cue` with its `SPEC.md` section. Load `.claude/skills/core-schema-edit/SKILL.md` first.

## 1. Subscription (`src/platform.cue` + `SPEC.md` §`#Platform`)

- [x] 1.1 Delete `#SubscriptionFilter` entirely (`:16-20`) — `range`, `allow`, `deny`, and its doc comment's resolution-order block.
- [x] 1.2 Replace `#Subscription.filter?` with `version!: #VersionType`. Keep `enable` unchanged.
- [x] 1.3 Rewrite `#Subscription`'s doc comment. The current note that "multi-channel-per-path is not expressible at this stage" becomes the permanent rule rather than a staging limitation — two builds of one catalog is two platforms.
- [x] 1.4 Rewrite `#Platform`'s doc comment: the kernel no longer "resolves every subscription's filter against the OCI registry", it pulls the named build.
- [x] 1.5 Update `SPEC.md` §`#Platform` — Shape, Constraints, and a *Why* covering reproducibility: git-identical inputs materialize identical bytes because the platform file is the resolution.
- [x] 1.6 `task vet`.

## 2. Match labels (`src/component.cue`, `src/resource.cue`, `src/trait.cue`, `src/blueprint.cue`, `src/transformer.cue`)

- [x] 2.1 Add `matchLabels` to `#Resource`, `#Trait` and `#Blueprint`.
- [x] 2.2 Add `matchLabels` to `#Component` as the wholesale unification of its attached primitives'. **No filter, no key list, no iteration** — iteration is what forced dropping `!` from required match labels in every rejected design.
- [x] 2.3 Leave `metadata.labels` alone on all four. Delete the "unified from all attached resources, traits, and blueprints" claim from `#Component.metadata.labels`' doc comment (`component.cue:19-21`) — it is about to be false.
- [x] 2.4 Point `#ComponentTransformer.requiredLabels` at `matchLabels`.
- [x] 2.5 Verify `matchLabels` does **not** reach `#TransformerContext.componentLabels` (`transformer.cue:147-157`). This is a deliberate omission; add a comment saying so, or it reads as an oversight.
- [x] 2.6 Delete `#LabelWorkloadType` (`component.cue:4`). Measured 2026-08-01: zero readers across all six consuming repos — all write the literal string.
- [x] 2.7 Update `SPEC.md` — the existing claim that matching unions `metadata.labels` becomes wrong and must be rewritten, not merely supplemented.
- [x] 2.8 `task vet`.

## 3. Fulfilment (`src/resource.cue`, `src/trait.cue`)

- [x] 3.1 Add `fulfilment: *"catalog" | "provider"` to `#Resource` and `#Trait`. Closed enum, defaulted — nothing opts in by accident.
- [x] 3.2 Add it to **neither** `#Blueprint` nor `#ComponentTransformer`. For `#Blueprint`, ensure the definition is closed so declaring it fails rather than being ignored.
- [x] 3.3 Update `SPEC.md` for both kinds, stating the single-provider rule and naming materialize as where it is enforced — `core` declares the intent and cannot count transformers across a platform.
- [x] 3.4 `task vet`.

## 4. Demand-side optionality (`src/component.cue` + `SPEC.md` §`#Component`)

- [x] 4.1 Choose and implement the trait opt-out spelling. `0010` D28 fixes that there is exactly one, that it lives on the demand side, and that its absence means required — the spelling is this change's to pick, so record the choice in `SPEC.md` Rationale rather than only in the schema.
- [x] 4.2 Add **no** optionality marker for resources. A component does not attach a resource it can do without.
- [x] 4.3 `task vet`.

## 5. Schema-level test cases

- [x] 5.1 Positive: a subscription with a scalar `version`, including a prerelease selected with no flag.
- [x] 5.2 MUST FAIL: a subscription with `filter`; a subscription with no `version`.
- [x] 5.3 Positive: two primitives with disjoint `matchLabels` unify into one component; two primitives with differing `metadata.labels["*.opmodel.dev/category"]` values coexist without conflict. The second is the case that broke every rejected design — pin it.
- [x] 5.4 MUST FAIL: two primitives whose `matchLabels` disagree on one key, asserting the error names that key.
- [x] 5.5 Assert a **required** match label survives into the component unset, reporting a missing required field rather than an incomplete value. This is the property the filter designs could not preserve.
- [x] 5.6 MUST FAIL: `fulfilment` on a `#Blueprint`; a third enum value.
- [x] 5.7 Assert `matchLabels` does not appear in rendered output for a component that declares them.

## 6. Generated artifacts and gates

- [x] 6.1 `task generate:index` — `#SubscriptionFilter` and `#LabelWorkloadType` removed.
- [x] 6.2 `.tasks/spec-tracked.txt` — no change expected; `#Platform`, `#Component` and the primitives are already tracked and `#SubscriptionFilter` was never listed. Confirm.
- [x] 6.3 `task check`.

## 7. Close the loop

- [ ] 7.1 `enhancements/0010/plan.yaml`: slice `core-platform-and-match` → `status: done`, `openspec_ref: core/core-platform-and-match`.
- [ ] 7.2 Same commit: `history` event citing that ref. Record the trait opt-out spelling chosen in 4.1 — D28 explicitly left it to the implementing slice, so the entry has no record of it until this event.
- [ ] 7.3 `task enhancements:plan:graph ID=0010` and `task enhancements:index`.
