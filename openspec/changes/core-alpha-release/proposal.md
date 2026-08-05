## Why

`core-identity-shape`, `core-primitive-keying`, `core-platform-and-match` and `core-identity-package` all land into the same unpublished alpha line. None of them publishes. Until a tag exists, nothing downstream can move: `library` cannot re-pin, and behind `library` sit `cli`, `opm-operator`, three catalogs, the module fleet and both republishes — twelve of enhancement `0010`'s sixteen slices and every one of `0011`'s CLI slices.

This change is that cut. It exists as a change rather than as a step inside the last schema change because it does something none of them do: it looks at the four together and asks whether they describe one coherent schema, then makes the result permanent.

The coherence pass is the substance. Four changes edited `SPEC.md` independently — `#Module`, `#Catalog`, `#ModuleInstance`, four member kinds, `#Platform`, `#Component`, two new gate constructs, and two category lines that moved `#Blueprint`. Each was correct against its own slice. Nothing has yet read them as one document, and `task spec:check` verifies inventory, not consistency.

## What Changes

**A `SPEC.md` coherence pass across everything the four changes touched.** Not a re-review of each section — a check that the document tells one story: that every cross-reference still resolves, that the identity invariant is stated the same way in `#Module` and `#ModuleInstance`, that the primitive/adapter taxonomy is consistent between the category lines and the four kind sections, and that no section still describes behaviour a later slice replaced.

**Worked examples re-vetted.** Every illustrative shape in `SPEC.md` and `docs/` is re-evaluated against the actual schema, not read for plausibility. A stale example in a normative document is a false statement about a published contract.

**`v1.0.0-alpha.4` published.** By merging the release-please PR, which tags and runs the `publish-cue` job. Not by hand.

## Capabilities

### New Capabilities

- `schema-release`: how the `core` schema reaches consumers — CI-only publication, what a break inside the alpha line does and does not move, the coherence bar a release must clear before it is tagged, and the post-publish verification. These rules have governed this repo since it was created and have never been specified; the first release that depends on all of them is the right place to write them down.

### Modified Capabilities

None. The four preceding changes carry every schema requirement; this one verifies they compose and publishes the result.

## Impact

**Depends on all four core changes.** `core-identity-shape`, `core-primitive-keying`, `core-platform-and-match` (enhancement `0010`) and `core-identity-package` (enhancement `0011`). Any one incomplete means no cut.

**Version.** `v1.0.0-alpha.4`. **Not a module-major event.** Measured 2026-08-05: `opmodel.dev/core@v1` has published `v1.0.0-alpha.1`, `.2` and `.3` and no stable `v1.0.0`, so the SemVer compatibility promise has not started. The break lands in the alpha line with the module path unmoved, which is what makes every downstream retarget an ordinary dep bump rather than an import rewrite.

**Rollback is a re-pin to `alpha.3`** for every consumer. That property is the reason the four changes were allowed to be breaking, and it stops being available the moment a consumer merges a retarget — so the rollback window closes at `library-core-retarget`, not here.

**What this unblocks, in order.** `library-core-retarget` first, then `library-identity-read-checks`, `library-subscription-collapse`, `library-contract-match` and `library-match-labels` in parallel, plus `docs-catalog-contract`. `cli-coordinate-adoption` and `operator-library-retarget` follow the library. Then the catalogs author their identity files, then the modules, then the two republishes.

**Consumers and their current pins**, each an explicit prerelease: `catalog_opm` and `catalog_kubernetes` on `alpha.1`, `catalog_opm_experimental` on `alpha.3`, plus `library`, `cli`, `opm-operator` and `modules/`. The retarget is a `task update-deps` sweep over an enumerable set.

**Design source.** `enhancements/0010` `06-operational.md` §Semver Impact and §Cross-Repo Coordination step 1; `plan.yaml`'s `core-alpha-release` slice.
