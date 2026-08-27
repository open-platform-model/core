## Why

`core-identity-shape`, `core-primitive-keying`, `core-platform-and-match` and `core-identity-package` all land into the same alpha line, and none of them publishes. Until a tag carrying **all four** exists, nothing downstream can move: `library` cannot re-pin, and behind `library` sit `cli`, `opm-operator`, three catalogs, the module fleet and both republishes — twelve of enhancement `0010`'s sixteen slices and every one of `0011`'s CLI slices.

**A partial tag now exists, and it is not a retarget target.** `v2.0.0-alpha.1` was published on 2026-08-07 by the `opmodel.dev/core@v2` major bump, which landed ahead of this change and carried `core-identity-shape` alone. It is resolvable, which makes it more dangerous than no tag at all: a consumer that re-pins to it compiles against an identity model whose contract keying, platform surface and identity package have not landed. **Nothing downstream retargets before the cut this change makes.** The "single cut point" the plan describes is therefore about completeness, not about being the first tag on the line — that property is already spent.

This change is that cut. It exists as a change rather than as a step inside the last schema change because it does something none of them do: it looks at the four together and asks whether they describe one coherent schema, then makes the result permanent.

The coherence pass is the substance. Four changes edited `SPEC.md` independently — `#Module`, `#Catalog`, `#ModuleInstance`, four member kinds, `#Platform`, `#Component`, two new gate constructs, and two category lines that moved `#Blueprint`. Each was correct against its own slice. Nothing has yet read them as one document, and `task spec:check` verifies inventory, not consistency.

## What Changes

**A `SPEC.md` coherence pass across everything the four changes touched.** Not a re-review of each section — a check that the document tells one story: that every cross-reference still resolves, that the identity invariant is stated the same way in `#Module` and `#ModuleInstance`, that the primitive/adapter taxonomy is consistent between the category lines and the four kind sections, and that no section still describes behaviour a later slice replaced.

**Worked examples re-vetted.** Every illustrative shape in `SPEC.md` and `docs/` is re-evaluated against the actual schema, not read for plausibility. A stale example in a normative document is a false statement about a published contract.

**The next alpha on the `@v2` line published** — `v2.0.0-alpha.2` unless a further cut intervenes first. By merging the release-please PR, which tags and runs the `publish-cue` job. Not by hand.

## Capabilities

### New Capabilities

- `schema-release`: how the `core` schema reaches consumers — CI-only publication, what a break inside the alpha line does and does not move, the coherence bar a release must clear before it is tagged, and the post-publish verification. These rules have governed this repo since it was created and have never been specified; the first release that depends on all of them is the right place to write them down.

### Modified Capabilities

None. The four preceding changes carry every schema requirement; this one verifies they compose and publishes the result.

## Impact

**Depends on all four core changes.** `core-identity-shape`, `core-primitive-keying`, `core-platform-and-match` (enhancement `0010`) and `core-identity-package` (enhancement `0011`). Any one incomplete means no cut.

**Version.** `v2.0.0-alpha.2`, on `opmodel.dev/core@v2`. **Not itself a module-major event** — the major move already happened, on 2026-08-07, in the commit that edited `src/cue.mod/module.cue` and forced `v2.0.0-alpha.1` with a `Release-As:` footer. This change advances the prerelease counter on a line that has already crossed. Revised from its original `v1.0.0-alpha.4` scoping, which assumed the break would stay on `@v1`.

**Rollback is an import rewrite, not a re-pin.** Reverting means restoring `opmodel.dev/core@v1` at `v1.1.0-alpha.1` — the import path as well as the version pin. Both majors stay resolvable indefinitely, because a published tag names fixed bytes permanently, so the old line does not rot; it is only more expensive to return to. The window still closes at `library-core-retarget` rather than here, and it now deserves closer watching, because what it costs to use has gone up.

**What this unblocks, in order.** `library-core-retarget` first, then `library-identity-read-checks`, `library-subscription-collapse`, `library-contract-match` and `library-match-labels` in parallel, plus `docs-catalog-contract`. `cli-coordinate-adoption` and `operator-library-retarget` follow the library. Then the catalogs author their identity files, then the modules, then the two republishes.

**Consumers and their current pins**, each an explicit prerelease on the retired `@v1` line: `catalog_opm` and `catalog_kubernetes` on `v1.0.0-alpha.1`, `catalog_opm_experimental` on `v1.0.0-alpha.3`, plus `library`, `cli`, `opm-operator` and `modules/`. The set is enumerable, but the retarget is **an import rewrite, not a `task update-deps` sweep** — every `import "opmodel.dev/core@v1"` becomes `@v2` alongside the `cue.mod` edit, and `update-deps` cannot do it, because resolving a new major is not the same operation as raising a version within one.

**Design source.** `enhancements/0010` `06-operational.md` §Semver Impact and §Cross-Repo Coordination step 1; `plan.yaml`'s `core-alpha-release` slice.
