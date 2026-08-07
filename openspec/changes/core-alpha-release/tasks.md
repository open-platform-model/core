# Tasks

**Gate.** Do not start until all four are landed: `core-identity-shape`, `core-primitive-keying`, `core-platform-and-match`, `core-identity-package`. Verify from `enhancements/`, not from memory — `task enhancements:plan:ready ID=0010` must show `core-alpha-release` with its dependencies satisfied.

**Commit types.** Everything here is `docs:`, `chore:` or `test:` — hidden types that cut no release. The version bump comes from the four preceding changes. A `feat:` in this change means something was implemented here that belonged in one of them.

## 1. Preconditions

- [ ] 1.1 Confirm all four slices are `done` in `enhancements/0010/plan.yaml` and `enhancements/0011/plan.yaml`, each with an `openspec_ref`, and that each has a matching `history` event. A slice marked done with no event means one of the two is stale.
- [ ] 1.2 `task check` on a clean tree.
- [ ] 1.3 Read the accumulated release-please PR. Confirm it is targeting `v2.0.0-alpha.2` and that its changelog lists the schema breaks. A misclassified commit shows up here as a missing or unexpected entry.

## 2. `SPEC.md` coherence pass

Read the whole document start to finish. Four questions, in order.

- [ ] 2.1 **The identity invariant, stated twice.** Compare §`#Module` and §`#ModuleInstance`. Both must carry D41's two-part form — artifact identity distinguishes majors and nothing finer; instance identity is reached by neither the version nor the major. If either still carries D38's single-sentence version ("version is never an input to fqn or to uuid"), fix it: that wording is superseded, and taken literally it is false, because the major *is* an input by way of the path.
- [ ] 2.2 **The taxonomy, stated in six places.** `:29` and `:38`'s category lines against §`#Resource`, §`#Trait`, §`#Blueprint` and §`#ComponentTransformer`. `#Blueprint` is a primitive; `#ComponentTransformer` is an adapter and carries no `apiVersion`. A category line disagreeing with a kind section is the defect `0010` D44 was filed over.
- [ ] 2.3 **Cross-references.** Grep the document for every renamed, deleted and redefined name: `version` on a catalog member (now `catalogVersion`), `nameSnakeCase`, `#KebabToSnake`, `#definitionName` on `#Module`/`#ComponentTransformer`, `#SubscriptionFilter`, `#LabelWorkloadType`, `#ModuleFQNType`, `#CatalogFQNType`, `#FQNType` used as a single regex. Each hit is wrong, not stale.
- [ ] 2.4 **Replaced behaviour.** Look for sections still describing how something used to work. The known instance is the claim that matching unions `metadata.labels` — but search for the class: any sentence describing derivation, resolution or selection that one of the four changes replaced.
- [ ] 2.5 Fix what the pass finds. If it finds a **design** problem rather than an inconsistency, stop and open a new change — do not resolve a design question inside a release.

## 3. Examples re-vetted

- [ ] 3.1 Extract every worked shape from `SPEC.md` and run it through `cue vet` against the actual schema. Do not read them for plausibility — the failures that matter look correct.
- [ ] 3.2 Same for `docs/`.
- [ ] 3.3 Same for the authoring-shape doc comments inside `src/*.cue`, particularly `#Catalog`'s header block, which described publish-time stamping into `identity/version_override.cue`.
- [ ] 3.4 Cross-check against `enhancements/0010/schemas/examples.cue`. Divergence between what shipped and what the design documented is a finding in one of them — determine which before editing either.

## 4. Final gates

- [ ] 4.1 `task fmt:check`, `task vet`, `task generate:index:check`, `task spec:check` — or `task check`.
- [ ] 4.2 Confirm `src/INDEX.md` lists every new construct and no removed one.
- [ ] 4.3 Confirm `.tasks/spec-tracked.txt` matches what shipped, including `#IdentityPackage` and `#CatalogMemberFQNGate`.

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
