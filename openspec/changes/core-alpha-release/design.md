## Context

Four changes reshape the `core` schema and none of them publishes. That is deliberate: enhancement `0010`'s `plan.yaml` records that the three `0010` core slices "land into the same unpublished alpha line; `core-alpha-release` is the single cut point 06-operational.md's *nothing else can move until this tag exists* describes, and it is what every downstream slice depends on." `0011`'s `core-identity-package` joins them for the same reason — `#IdentityPackage` belongs in the alpha the catalogs and the fleet retarget to.

Four independent `SPEC.md` edits leave a document that is correct section by section and unverified as a whole. `task spec:check` catches a construct with no section and a section naming a construct that no longer exists. It does not catch two sections describing the same invariant differently, a cross-reference to a renamed field, or a worked example that no longer evaluates.

## Goals / Non-Goals

**Goals:**

- `SPEC.md` MUST read as one document describing one schema.
- Every worked example in the repo MUST evaluate against the schema as published.
- The alpha MUST be cut through CI, on a reviewed release PR.

**Non-Goals:**

- **Re-litigating any of the four changes.** If the pass finds a design problem rather than an inconsistency, that is a new change, not an edit here.
- **Any downstream retarget.** `library-core-retarget` and everything behind it.
- **A stable `v1.0.0`.** This is `alpha.4`. When the alpha line ends is a separate decision.
- **Publishing by hand.** `cue mod publish` against a live registry is never run manually.

## Decisions

### The coherence pass is a read, with a fixed set of questions

Not a re-review. Four questions, each targeting a way independent edits diverge:

1. **Is the identity invariant stated identically where it appears twice?** `#Module` and `#ModuleInstance` both carry half of it, written by the same change but in different sections. `0010` D38's original single-sentence form was superseded by D41's two-part form precisely because one sentence was both imprecise and incomplete — if either section still carries the old wording, the document contradicts itself about what the owner label depends on.
2. **Is the primitive/adapter taxonomy consistent?** `SPEC.md:29` and `:38` move `#Blueprint` from Constructs to Primitives, and four kind sections were edited separately. A category line and a kind section disagreeing is the exact defect `0010` D44 was filed to fix — the log asserted both readings at once for two days.
3. **Does every cross-reference resolve?** Fields were renamed (`version` → `catalogVersion`), deleted (`nameSnakeCase`, `#definitionName`, `#SubscriptionFilter`, `#LabelWorkloadType`, `#ModuleFQNType`, `#CatalogFQNType`), and redefined (`fqn`, `#FQNType`). A section referring to any of them by the old name is wrong rather than stale.
4. **Does any section still describe replaced behaviour?** The known instance is `SPEC.md`'s claim that matching unions `metadata.labels` — but the pass looks for the class, not just that one.

### Examples are evaluated, not read

Every worked shape in `SPEC.md` and `docs/` goes through `cue vet`. Reading an example for plausibility is how a stale one survives: the failures this catches are exactly the ones that look right — a `modulePath` missing its new `@v1`, an FQN in the pre-split form, a `version` field on a primitive.

`enhancements/0010/schemas/examples.cue` is the reference for the target shapes and is already vetted; the check here is that this repo's own examples agree with what shipped, which is not the same claim.

### The release goes through release-please

`feat!:` commits have accumulated across the four changes, so release-please has a PR open. Merging it tags `v1.0.0-alpha.4` and runs the `publish-cue` job, gated on `release_created == 'true'`, in the workflow run triggered by the human merging — which is why it is not subject to GitHub's `GITHUB_TOKEN` tag-trigger suppression.

Nothing here runs `cue mod publish`. The one-line reason it matters: a manual publish produces a tag CI did not build, from a tree nobody reviewed, and the registry is append-only.

### No `feat!:` of its own

This change contributes no schema edit. Its commits are `docs:` for the `SPEC.md` pass and `chore:`/`test:` for example re-vets — all hidden types that cut no release on their own. The version bump comes from the four preceding changes, which is correct: the break is theirs.

## Risks / Trade-offs

**The pass finds a design problem, not an inconsistency.** The likely candidates are the two places the four changes touch one field from opposite directions — the primitive kinds, edited by both `core-primitive-keying` and `core-platform-and-match`, and `SPEC.md`'s taxonomy lines. If that happens, the alpha waits. Cutting a tag over a known incoherence to keep a schedule is the one failure this change exists to prevent, and the tag is immutable once pushed.

**The rollback window closes downstream, not here.** Re-pinning to `alpha.3` stays available for every consumer until it merges its retarget. So the real point of no return is `library-core-retarget`, and treating this cut as the irreversible step under-weights what follows it.

**Publishing an alpha that no consumer has compiled against.** Nothing downstream has been retargeted at cut time — that is the ordering, not an oversight — so the first real compile of the new schema happens after the tag exists. The mitigation is that `library-core-retarget` is deliberately behaviour-free: re-pin, fix breakage, regenerate testdata. If it turns into a design conversation, that is the signal a schema change was wrong, and the response is `alpha.5` rather than an amended `alpha.4`.

**Four changes' `SPEC.md` sections were written without seeing each other.** Accepted by construction — the slices are sequential and each was correct in isolation. This pass is the compensating control, and its value depends entirely on being done as a fresh read of the whole document rather than a diff review of the four sets of edits.
