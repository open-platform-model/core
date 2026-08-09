# Tasks

**Gate.** Do not start until all four are landed: `core-identity-shape`, `core-primitive-keying`, `core-platform-and-match`, `core-identity-package`. Verify from `enhancements/`, not from memory — `task enhancements:plan:ready ID=0010` must show `core-alpha-release` with its dependencies satisfied.

**Commit types.** Everything here is `docs:`, `chore:` or `test:` — hidden types that cut no release. The version bump comes from the four preceding changes. A `feat:` in this change means something was implemented here that belonged in one of them.

## 1. Preconditions

- [x] 1.1 Confirm all four slices are `done` in `enhancements/0010/plan.yaml` and `enhancements/0011/plan.yaml`, each with an `openspec_ref`, and that each has a matching `history` event. A slice marked done with no event means one of the two is stale.
- [x] 1.2 `task check` on a clean tree.
- [x] 1.3 Read the accumulated release-please PR. Confirm it is targeting `v2.0.0-alpha.2` and that its changelog lists the schema breaks. A misclassified commit shows up here as a missing or unexpected entry.

> **VERSION DEVIATION — the cut is `v2.0.0-alpha.4`, not `alpha.2`.** Two further cuts intervened, which the proposal anticipated ("`v2.0.0-alpha.2` unless a further cut intervenes first"). The four slices did not land in one alpha; they landed across three, and the release PR is open for a fourth. Read every later task's `alpha.2` as `alpha.4`.
>
> | Release | Carries |
> | --- | --- |
> | `v2.0.0-alpha.1` (2026-08-07) | `core-identity-shape` + the `opmodel.dev/core@v2` major move |
> | `v2.0.0-alpha.2` (2026-08-07) | `core-primitive-keying` |
> | `v2.0.0-alpha.3` (2026-08-07) | `core-platform-and-match` |
> | **`v2.0.0-alpha.4`** (PR #39, open) | `core-identity-package` |
>
> All four slices are accounted for and no commit is misclassified: each `feat!:` cut its own break entry, and `#38` is correctly a plain `feat:` because the identity package is additive. **Consequence for the proposal's own reasoning:** `v2.0.0-alpha.1` is not the only partial tag on the line — `alpha.2` and `alpha.3` are partial too, and `alpha.3` is the most hazardous of them, because it carries three of the four slices and is the tag a consumer is most likely to mistake for complete.

## 2. `SPEC.md` coherence pass

Read the whole document start to finish. Four questions, in order.

- [x] 2.1 **The identity invariant, stated twice.** Compare §`#Module` and §`#ModuleInstance`. Both must carry D41's two-part form — artifact identity distinguishes majors and nothing finer; instance identity is reached by neither the version nor the major. If either still carries D38's single-sentence version ("version is never an input to fqn or to uuid"), fix it: that wording is superseded, and taken literally it is false, because the major *is* an input by way of the path.
- [x] 2.2 **The taxonomy, stated in six places.** `:29` and `:38`'s category lines against §`#Resource`, §`#Trait`, §`#Blueprint` and §`#ComponentTransformer`. `#Blueprint` is a primitive; `#ComponentTransformer` is an adapter and carries no `apiVersion`. A category line disagreeing with a kind section is the defect `0010` D44 was filed over.
- [x] 2.3 **Cross-references.** Grep the document for every renamed, deleted and redefined name: `version` on a catalog member (now `catalogVersion`), `nameSnakeCase`, `#KebabToSnake`, `#definitionName` on `#Module`/`#ComponentTransformer`, `#SubscriptionFilter`, `#LabelWorkloadType`, `#ModuleFQNType`, `#CatalogFQNType`, `#FQNType` used as a single regex. Each hit is wrong, not stale.
- [x] 2.4 **Replaced behaviour.** Look for sections still describing how something used to work. The known instance is the claim that matching unions `metadata.labels` — but search for the class: any sentence describing derivation, resolution or selection that one of the four changes replaced.
- [x] 2.5 Fix what the pass finds. If it finds a **design** problem rather than an inconsistency, stop and open a new change — do not resolve a design question inside a release.

**What the pass found — all editorial, no design problem, so the cut is not blocked.**

1. **A false mechanism claim, in four places.** `SPEC.md` §3.6 and §5.2, `src/identity_package.cue`'s doc comment and `src/identity_package_pins.cue`'s note all said the scalar-subscription reshape *removed* the platform-side major-agreement backstop that D43/D45 accepted their exposure against. It removed nothing. Verified independently rather than taken from the enhancement's own correction: `git log --all -S_majorAgrees -- src/` is empty, and the pre-reshape subscription filter (`git show 0070d41^:src/platform.cue`) carried only `range`, `allow`, `deny`. The check was **never built in `core`**. The exposure is unchanged either way, but the ownership is not: an unbuilt check belongs to `library`'s subscription-collapse slice (`status: planned`), where a deleted one would be a regression this repo introduced and nobody holds.
2. **A version-number error, in three places.** The subscription filter was removed in `v2.0.0-alpha.3` (tag verified to contain `c51f833`), not `alpha.4`. `SPEC.md:576`, `docs/publishing.md:67` and `:118`.
3. **`#Secret` was listed as a Primitive** in `SPEC.md`'s category line. It is a config-value contract type (a disjunction of `#SecretLiteral` / `#SecretK8sRef`) with no `metadata`, no `apiVersion`, no contract key and no `spec` — it satisfies none of the clauses of the sentence it appeared in, and no catalog publishes it as a member.
4. **`#Blueprint` (§3.3) sits under the `## 3. Constructs` H2** while §1 and §3.3's own Rationale call it a primitive. The section *number* is deliberately retained for anchor stability; the enclosing heading was the unreconciled half. Noted at the heading rather than renumbered.
5. **Two sections contradicted each other on grouping segments.** §3.3 admitted "any grouping segments the catalog uses beneath" `/blueprints` and its Shape gave `…/blueprints/workload`; §5.2 and §5.3 forbid exactly that, and `#CatalogMemberFQNGate` refuses it by equality against `kindPrefix`. D42 settles it — every kind is flat — so §3.3 was the stale side. Also corrected in `src/blueprint.cue` and `src/types.cue` doc comments, and in the `identity_pins.cue` / `platform_and_match_pins.cue` fixtures, which modelled a path the sibling gate file's MUST-FAIL case refuses. Pins re-verified by mutation test after the rename.
6. **A rationale premise invalidated by a later slice.** §2.1 and `src/resource.cue` justified "fulfilment cannot be derived" on the kind-segment count being unfixed — which D42 fixed. The conclusion survives on a different ground and is restated: a member declares a `#PackagePathType`, which carries no major, so stripping name and kind off a member FQN recovers the catalog's `registryPath` and never its major. **D32 itself is untouched.**
7. **`docs/` carried the pre-0010 schema throughout** — see §3.2 below.

## 3. Examples re-vetted

- [x] 3.1 Extract every worked shape from `SPEC.md` and run it through `cue vet` against the actual schema. Do not read them for plausibility — the failures that matter look correct.
- [x] 3.2 Same for `docs/`.
- [x] 3.3 Same for the authoring-shape doc comments inside `src/*.cue`, particularly `#Catalog`'s header block, which described publish-time stamping into `identity/version_override.cue`.
- [x] 3.4 Cross-check against `enhancements/0010/schemas/examples.cue`. Divergence between what shipped and what the design documented is a finding in one of them — determine which before editing either.

**Method.** A scratch tree holding a copy of `src/` plus the extracted examples as files in the same package, so every shape is evaluated against the real definitions rather than read.

- **3.1** `SPEC.md`'s Shape blocks are simplified re-statements of the definitions, not instantiable values; they were checked field-by-field against `src/` and against each other. The defects found are recorded at 2.5 (items 4, 5, 6).
- **3.2** `docs/` was the worst of it — the whole tree still described the pre-0010 schema. Confirmed by evaluation, not by reading: the Resource example failed `metadata.version: field not allowed`, and the Module example failed on **both** `name` (kebab, now `#SnakeNameType`) and `modulePath` (`"example.com/modules"`, no `@vN`). Also fixed: `apiVersion: #ApiVersion` in seven places — a definition that has never existed in the schema at any commit, at the wrong nesting level besides; `version!: #MajorVersionType` → `apiVersion!` + `catalogVersion!` across all three primitives and the transformer; `fqn: #FQNType // computed` → the authored `#ContractFQNType` / `#ImplFQNType` split; `#TransformerMap: [#FQNType]` → `[#ImplFQNType]`; missing `optional` on the Trait shape and example; missing `fulfilment`; and `#Component.metadata.labels // unified from attached primitives`, **the exact claim D36 deleted**, which contradicted the corrected prose 26 lines below it in the same file. `docs/definition-types.md` classified `#Platform` as a *planned Adapter* (it is a shipped Construct), omitted `#Catalog` and all three publish gates, and stated the superseded pre-D44 dividing question as the litmus test.
- **3.3** `#Catalog`'s header block — the task's named suspect — is **already correct**: it describes `identity/version_override.cue` as the arrangement the committed identity package *replaced*. The doc-comment defects were elsewhere (2.5 items 1, 5, 6).
- **3.4** **No divergence.** `examples.cue`'s `_catalogAfter` agrees with what shipped on every value — `ModulePath: "opmodel.dev/catalogs/opm@v1"`, catalog `fqn` as the module path verbatim, `@SemVer` transformer keys against `@vN` contract keys, `catalogVersion` as stamped provenance, `apiVersion` as the one authored-per-primitive value.

**Verification.** Every corrected example — all three primitives, the module, and the gates over them — vets clean under `cue vet -c`, and the primitives additionally pass `#CatalogMemberFQNGate` and `#TraitOptionalGate`. That is stronger than "does not fail": it proves the documented shapes are ones a real catalog could publish.

## 4. Final gates

- [x] 4.1 `task fmt:check`, `task vet`, `task generate:index:check`, `task spec:check` — or `task check`.
- [x] 4.2 Confirm `src/INDEX.md` lists every new construct and no removed one.
- [x] 4.3 Confirm `.tasks/spec-tracked.txt` matches what shipped, including `#IdentityPackage` and `#CatalogMemberFQNGate`.

- **4.1** `vet`, `generate:index:check` and `spec:check` all pass; `cue fmt` is idempotent. Note that `fmt:check` is `cue fmt` followed by `git diff --exit-code -- 'src/*.cue'`, so it reports any *uncommitted* change to `src/` and can only pass once this work is committed — it is a post-commit/CI gate, not a working-tree one. **`spec:check` earned its keep here**: it rejected a regression this pass introduced, when the corrected text wrote `#SubscriptionFilter` with its `#` and Direction 3 refused a `#Name` that no longer resolves. The prose now names it without the sigil, which is why the original text was phrased that way.
- **4.2** `src/INDEX.md` carries all three gates, `#Subscription`, `#ContractFQNType` / `#ImplFQNType` / `#APIVersionType` / `#APIVersionGated`, `#ArtifactRef`, `#SnakeNameType` and `#PackagePathType`; none of `#SubscriptionFilter`, `#LabelWorkloadType`, `#ModuleFQNType`, `#CatalogFQNType` or `#KebabToSnake` survives anywhere in the repo.
- **4.3** `.tasks/spec-tracked.txt` lists twelve constructs including `#IdentityPackage`, `#CatalogMemberFQNGate` and `#TraitOptionalGate`; `SPEC.md` has exactly twelve matching sections (§2.1–§5.3).

## 5. Cut the release

- [ ] 5.1 Merge the release-please PR. This tags `v2.0.0-alpha.2` and triggers `publish-cue`.
- [ ] 5.2 **Do not run `cue mod publish` by hand**, under any circumstance, including a failed CI job. A failed publish is debugged and re-run in CI.
- [ ] 5.3 Confirm the GitHub Release exists and the `publish-cue` job succeeded.
- [ ] 5.4 Verify the published artifact resolves: from a scratch tree, add `opmodel.dev/core@v2` at `v2.0.0-alpha.2` and evaluate a minimal `#Module` in the new shape. This is the first real compile of the new schema by a consumer.

## 6. Close the loop

- [ ] 6.1 `enhancements/0010/plan.yaml`: slice `core-alpha-release` → `status: done`, `openspec_ref: core/core-alpha-release`.
- [ ] 6.2 Same commit: `history` event citing that ref and the published version.
- [ ] 6.3 `task enhancements:plan:graph ID=0010` and `task enhancements:index`.
- [ ] 6.4 Confirm `task enhancements:plan:ready ID=0010` now surfaces `library-core-retarget` and `docs-catalog-contract`.
- [ ] 6.5 Record the rollback boundary where the next slice will see it: re-pinning to `opmodel.dev/core@v1` at `v1.1.0-alpha.1` stays available until `library-core-retarget` merges — an import rewrite now, not a version pin. Put it in the `history` event, not only here.
