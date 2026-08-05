# Tasks

**Sequencing.** Requires `core-identity-shape` (hard compile dependency — `#ArtifactRef` and the `@vN` `#ModulePathType`) and `core-primitive-keying` (`#ContractFQNType`, `#ImplFQNType`, `#APIVersionType`, `#FQNType` as a disjunction). This is the slice enhancement `0011` contributes to `core`, and `0010`'s `core-alpha-release` waits on it.

**What this change does not do.** It ships two schemas and nothing that unifies against them. The enforcement is `cli-publish-pipeline` and `cli-catalog-member-gate` in enhancement `0011`, both after the alpha cut. Do not close this change believing publish now validates anything.

**Commits.** Stage `src/*.cue` with the matching `SPEC.md` sections. Load `.claude/skills/core-schema-edit/SKILL.md` first.

## 1. `#IdentityPackage`

- [ ] 1.1 Add `#IdentityPackage` with `ModulePath!: #ModulePathType` and `Version!: #VersionType`.
- [ ] 1.2 Derive `RegistryPath` and `Major` through `_ref: #ArtifactRef & {modulePath: ModulePath}` — not by a second `SplitN`. One decomposition site is the point of `#ArtifactRef`.
- [ ] 1.3 Add the version-major assertion as two lines: `VersionMajor: "v" + strings.SplitN(Version, ".", 2)[0]` and `VersionMajor: Major`.
- [ ] 1.4 Doc-comment that this is the **only** assertion of that relation in the system, naming `0010` D43 and D45 as what removed the `core`-side copies. Without that note the next reader sees a redundant check and deletes it.
- [ ] 1.5 Add `kindPrefix` as an enumerated struct with exactly four keys, each `RegistryPath` plus one segment, **no major re-appended**. Doc-comment why it is enumerated rather than a pattern constraint — `id.kindPrefix.resources` yields `undefined field` under a pattern, measured in `0011/experiments/01`.
- [ ] 1.6 Use only CUE builtins. `strings` is a builtin and adds no module-graph edge; the import-free invariant this preserves is about **intra-module** imports.
- [ ] 1.7 `task vet`.

## 2. `#CatalogMemberFQNGate`

- [ ] 2.1 Add the shape with `identity!: #IdentityPackage`, `kind!` as the four-value closed enum, and `name!: #NameType`.
- [ ] 2.2 Declare `declaredFQN!: #FQNType`, `declaredModulePath!: #PackagePathType`, `declaredCatalogVersion!: #VersionType`.
- [ ] 2.3 Declare `declaredAPIVersion?: #APIVersionType` at the top level, with `if kind != "transformers" { declaredAPIVersion!: #APIVersionType }`.
- [ ] 2.4 Add the implied values as second declarations: `declaredModulePath: identity.kindPrefix[kind]`, `declaredCatalogVersion: identity.Version`.
- [ ] 2.5 Add `_keyVersion` as the two-element list comprehension selecting `identity.Version` for transformers and `declaredAPIVersion` otherwise, then `declaredFQN: identity.kindPrefix[kind] + "/" + name + "@" + _keyVersion`. Order matters — the transformer branch must be selected before `declaredAPIVersion` is reached, which is what spares the absent optional.
- [ ] 2.6 Do **not** check `apiVersion` against identity. Doc-comment why: nothing implies it, which is the point of the field.
- [ ] 2.7 Do **not** embed the gate in any primitive definition. Doc-comment that doing so would re-derive `fqn` and undo `0010` D21.
- [ ] 2.8 `task vet`.

## 3. Test cases

- [ ] 3.1 Positive, one per kind: a resource, trait, blueprint and transformer that conform.
- [ ] 3.2 MUST FAIL: a version whose major disagrees with the path, asserting the error names `VersionMajor` with the two conflicting values. This is the assertion two other changes deleted their copies on the strength of — it is the single most load-bearing case in this change.
- [ ] 3.3 MUST FAIL: a member one segment too deep. Assert it fails on **both** `declaredModulePath` and `declaredFQN`, and that the second surfaces the disjunction error — that is the diagnostic a string comparison would have discarded.
- [ ] 3.4 MUST FAIL: a stale `declaredCatalogVersion`; a stale transformer `declaredFQN`; a member declaring another catalog's path.
- [ ] 3.5 Assert the conditional optional in all three measured directions: transformer with the field **absent** yields the build with no error; a primitive supplying it yields the apiVersion; a primitive omitting it fails `declaredAPIVersion: field is required but not present`.
- [ ] 3.6 MUST FAIL: an unknown `kind`.
- [ ] 3.7 Assert `kindPrefix` values carry no `@vN`.

## 4. Documentation and gates

- [ ] 4.1 Add `#IdentityPackage` and `#CatalogMemberFQNGate` to `.tasks/spec-tracked.txt`. Both are top-level, consumer-facing, non-helper constructs — a catalog author meets the gate directly and needs its normative statement.
- [ ] 4.2 Write both `SPEC.md` sections in the four-part format. The gate's Rationale MUST record that it is the enforcement point `0010` D17, D21, D25 and D42 all delegate to, and that `0010` D21 traded `core`'s `fqn` derivation for it.
- [ ] 4.3 `task generate:index`.
- [ ] 4.4 `task check` — `spec:check` will fail until 4.1 and 4.2 are both done, which is the intended coupling.

## 5. Close the loop

- [ ] 5.1 `enhancements/0011/plan.yaml`: slice `core-identity-package` → `status: done`, `openspec_ref: core/core-identity-package`.
- [ ] 5.2 Same commit: `history` event in `enhancements/0011/config.yaml` citing that ref.
- [ ] 5.3 `task enhancements:plan:graph ID=0011` and `task enhancements:index`.
- [ ] 5.4 Confirm `task enhancements:plan:ready ID=0010` now shows `core-alpha-release` as reachable once the other two core slices are also done — this slice is one of its four dependencies and the only one owned by `0011`.
