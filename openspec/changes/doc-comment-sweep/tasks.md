## 1. Pass one: primitives and component (SPEC.md untouched, `SPEC_IMPACT=none` per commit)

- [x] 1.1 `src/component.cue`: split `resourceName` (20), `labels` (8), `_matchLabelsFromPrimitives` (25), `_matchLabelsAreDerived` (14), `_nameConstraints` (17), `_nameFits` (21), `#names` (7). D2 pointers for `resourceName`, `_nameFits`, `_matchLabelsAreDerived` where SPEC.md § 3.1 Rationale carries the argument.
- [x] 1.2 `src/resource.cue`: `apiVersion` (8), `fqn` (8), `matchLabels` (25), `#nameConstraint` (17), `fulfilment` (35). D2 pointer for `fulfilment` (§ 2.1).
- [x] 1.3 `src/trait.cue`: `matchLabels` (7), `#nameConstraint` (17), `fulfilment` (10), `optional` (29), `#TraitOptionalGate` (13). D2 pointer for `optional` (§ 2.2).
- [x] 1.4 `src/blueprint.cue`: `modulePath` (7), `matchLabels` (10), `#nameConstraint` (17).
- [x] 1.5 Per-file D5 checks after each of 1.1 to 1.4: comment-stripped diff empty, `cue fmt` idempotent, `task check` green, `docs:check` count down by the file's site count.

## 2. Pass one: types and identity

- [x] 2.1 `src/types.cue`: `#ObjectNameType` (8), `#SnakeNameType` (9), `#ModulePathType` (18), `#PackagePathType` (13), `#MajorVersionType` (10), `#APIVersionType` (11), `#APIVersionGated` (14), `#ArtifactRef` (8), `#ContractFQNType` (17), `#ImplFQNType` (12), `#FQNType` (21). D4 placement (block after the one-liner).
- [x] 2.2 `src/identity_package.cue`: `#IdentityPackage` (29), `VersionMajor` (36), `kindPrefix` (21), `#CatalogMemberFQNGate` (28), `declaredModulePath` (7), `_keyVersion` (9).
- [x] 2.3 `src/catalog.cue`: `#Catalog` (55). D4 placement (block after the closing brace).
- [x] 2.4 Per-file D5 checks after each of 2.1 to 2.3.

## 3. Pass one: module, platform, transformer, schemas

- [x] 3.1 `src/transformer.cue`: `#ComponentTransformer` (11), `metadata` (20), `requiredLabels` (13), `#transform` (12), `moduleLabels` (18).
- [x] 3.2 `src/platform.cue`: `#Subscription` (23), `#Platform` (16).
- [x] 3.3 `src/module_instance.cue`: `fqn` (18), `components` (9). `src/module.cue`: `#ctx` (8). `src/module_context.cue`: `#InstanceIdentity` (10).
- [x] 3.4 `src/schemas.cue`: `#Secret` (11), `#DiscoverSecrets` (16).
- [x] 3.5 Per-file D5 checks after each of 3.1 to 3.4; `task docs:check` reports 0 sites.

## 4. Pass two (D6): independent re-read of every touched file

- [x] 4.1 For each of the 13 files, fresh read: doc comment states the contract on its own; every sentence in the `git diff` removed hunks reappears in an added hunk or is covered by a named SPEC.md bullet; a blank line precedes every `// WHY` block; no `// WHY` block sits above another field's doc.
- [x] 4.2 Fix findings as one follow-up commit per affected file, not amendments. Findings: placement moved above the doc comment on all 51 sites (D8); `trait.cue` `optional` block reduced to its D2 form.
- [x] 4.3 Whole-tree D5 check: comment-stripped diff of `src/` against `main` is empty; `cue fmt ./...` idempotent; `task check` green.

## 5. Strict flip and wording

- [x] 5.1 `Taskfile.yml`: `docs:check` runs `bash .tasks/doc-check.sh src --strict`; update its `desc`.
- [x] 5.2 `CLAUDE.md` (command table row and § Doc comments) and `.claude/skills/core-schema-edit/SKILL.md`: remove "warn-only until the sweep lands"; state that the report fails the build.

## 6. Generated artifacts and validation gates

- [x] 6.1 `task generate:index`; review every changed row of `src/INDEX.md` (a changed row means a rewritten first sentence).
- [x] 6.2 `task check` green with strict `docs:check`; `git diff --stat main -- SPEC.md .tasks cue.mod` is empty.
