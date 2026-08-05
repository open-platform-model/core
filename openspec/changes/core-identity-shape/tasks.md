# Tasks

**On size.** `openspec/config.yaml` asks that a change reshaping several top-level definitions be split. This one is not, and the reason is stated rather than assumed: the identity model is one unification. Retyping `#ModulePathType` without redefining `#Module.metadata.fqn` in the same step leaves a tree that does not vet, and `#ModuleInstance`'s `fqn` cannot exist before `#Module.registryPath` does. The boundary was set by `enhancements/0010`'s `plan.yaml`, which separates the three core slices along *what they key* — identity here, contract keying in `core-primitive-keying`, platform and match in `core-platform-and-match`.

What the groups below do guarantee is that **every group ends at a tree that vets**, so the work is still resumable between them. `task vet` is the checkpoint, not the commit.

**On commits.** Groups 1–4 each stage `src/*.cue` together with the matching `SPEC.md` section. The pre-commit hook, `task spec:check` and the CI gate all reject a `*.cue` commit without `SPEC.md`, so the SPEC task inside each group is **not** a separate commit — it is the same one. Load `.claude/skills/core-schema-edit/SKILL.md` before the first edit.

## 1. Path types and address decomposition (`src/types.cue`)

- [x] 1.1 Narrow `#ModulePathType` to require a terminal `@vN`: `^[a-z0-9._-]+(/[a-z0-9._-]+)*@v[0-9]+$`. Update its doc comment — the current one describes a "plain registry path without embedded version", which becomes `#PackagePathType`'s.
- [x] 1.2 Add `#PackagePathType` carrying the old regex verbatim, doc-commented as what a *primitive* declares and why the major is inert there.
- [x] 1.3 Add `#ArtifactRef` with `modulePath!`, `_p: strings.SplitN(modulePath, "@", 2)`, `registryPath`, `major: #MajorVersionType & _p[1]`, `importPath: modulePath`.
- [x] 1.4 Retype `metadata.modulePath` to `#PackagePathType` in `src/resource.cue`, `src/trait.cue`, `src/blueprint.cue` and `src/transformer.cue`. Values are unchanged — this is a type rename at four sites, not a value migration.
- [x] 1.5 Delete `#KebabToSnake`. **Deferred into group 2** — its only reader is `#Module.metadata.nameSnakeCase` (2.2), so deleting it here would break group 1's own "must vet" checkpoint. Landed with 2.2. Leave `#KebabToPascal` and `#KebabToCamel` — the three primitive kinds still build `spec!` keys from them.
- [x] 1.6 `task vet` — the tree will not be internally consistent yet (`#Module.fqn` still recombines), but the types must compile.

## 2. Module identity (`src/module.cue` + `SPEC.md` §`#Module`)

- [x] 2.1 Retype `metadata.name!` to `#SnakeNameType`.
- [x] 2.2 Delete `metadata.nameSnakeCase`.
- [x] 2.3 Add `_ref: #ArtifactRef & {modulePath: metadata.modulePath}`.
- [x] 2.4 Redefine `fqn` as `#ModulePathType & modulePath`. Delete `#ModuleFQNType` from `src/types.cue`.
- [x] 2.5 Add `registryPath: _ref.registryPath`.
- [x] 2.6 Add the hidden leaf constraint: `_leaf: strings.HasSuffix(_ref.registryPath, "/" + name)` and `_leaf: true`.
- [x] 2.7 Confirm `version!` is retained and that neither `fqn` nor `uuid` reads it. Add **no** `versionMajor` field and **no** version/path major assertion — D45. Leave a comment saying so, naming D45, so its absence reads as specified rather than forgotten.
- [x] 2.8 Leave `uuid: SHA1(OPMNamespace, fqn)` unchanged in form. Its input has changed; the formula has not.
- [x] 2.9 Delete `#definitionName` — it computes a Pascal-case projection that under a snake `name` yields `Media_server`, and nothing reads it. (`transformer.cue`'s copy belongs to `core-primitive-keying`.)
- [x] 2.10 Update `SPEC.md` §`#Module` — Shape, Constraints, and a *Why* paragraph in Rationale for each of: the path widening, the name retype, the `fqn` redefinition, the `registryPath` addition, and the deliberate absence of the major assertion.
- [x] 2.11 `task vet`.

## 3. Instance identity (`src/module_instance.cue` + `SPEC.md` §`#ModuleInstance`)

- [x] 3.1 Add `metadata.fqn: "\(#moduleMetadata.registryPath):\(name):\(namespace)"`.
- [x] 3.2 Redefine `metadata.uuid` as `#UUIDType & cue_uuid.SHA1(OPMNamespace, fqn)`, replacing the inline `"\(#moduleMetadata.uuid):\(name):\(namespace)"` interpolation.
- [x] 3.3 Update `SPEC.md` §`#ModuleInstance` — state **both halves** of the invariant beside the fields, not only in the enhancement: artifact identity distinguishes majors and nothing finer; instance identity is reached by neither the version nor the major. Name the owner label and the prune behaviour that depends on it.
- [x] 3.4 `task vet`.

## 4. Catalog identity (`src/catalog.cue` + `SPEC.md` §`#Catalog`)

- [x] 4.1 Add `_ref: #ArtifactRef & {modulePath: M.modulePath}`; redefine `fqn` as `#ModulePathType & modulePath`. Delete `#CatalogFQNType`.
- [x] 4.2 Remove the `*"0.0.0-dev"` default from `version!`. An unfilled version becomes an incomplete value naming the field.
- [x] 4.3 Change the `#transformers` pattern constraint to stamp `"\(_ref.registryPath)/transformers"` — major split out and **not** re-appended. Leave the `version` stamp alone; its rename to `catalogVersion` is `core-primitive-keying`.
- [x] 4.4 Add **no** version/path major assertion — D43, the same holding as 2.7. Comment it for the same reason.
- [x] 4.5 Update the authoring-shape doc comment at the head of `#Catalog`: it still describes publish-time stamping into `identity/version_override.cue`, which D5 replaces with a committed `identity/identity.cue`.
- [x] 4.6 Update `SPEC.md` §`#Catalog`.
- [x] 4.7 `task vet`.

## 5. Schema-level test cases

Mirror `enhancements/0010/schemas/target.cue`'s cases so the properties are pinned where the schema lives, not only in the design document.

- [ ] 5.1 Positive: a module at `@v2` whose `fqn` equals its path and whose `registryPath` drops the major; a catalog likewise.
- [ ] 5.2 Invariant, both directions: `uuid` unchanged across a `version` change; `uuid` **changed** across a major bump. Assert `uuid` explicitly — a case checking `fqn` alone will not catch a `uuid` regression.
- [ ] 5.3 Instance invariant: `instance.uuid` unchanged across both a version change and a major bump, and **distinct** across a differing module registry path, a differing namespace, and a differing instance name.
- [ ] 5.4 MUST FAIL: a version interpolated into `fqn`; a kebab-case module name; a name disagreeing with the path leaf; a module path with no major; a primitive path carrying one; a module path substituted where a registry path belongs.
- [ ] 5.5 MUST VET CLEAN, deliberately: `modulePath: ".../postgres@v2"` with `version: "3.0.0"` on both `#Module` and `#Catalog`. This pins D43/D45's accepting behaviour so that reintroducing the `core`-side assertion reads as a change rather than as a fix. Comment it with that reason — an uncommented passing case looks like an oversight.

## 6. Generated artifacts and gates

- [ ] 6.1 `task generate:index` — `#ArtifactRef` and `#PackagePathType` are added; `#KebabToSnake`, `#ModuleFQNType` and `#CatalogFQNType` are removed. Review the extracted doc comments before staging.
- [ ] 6.2 Update `.tasks/spec-tracked.txt` only if a new **top-level, non-helper** construct was added. `#ArtifactRef` and `#PackagePathType` are helpers by the `core-schema-edit` allowlist's own definition (a constrained-string type and an internal decomposition helper), so the expected outcome is **no change** — confirm rather than assume.
- [ ] 6.3 `task check` — `fmt:check`, `vet`, `generate:index:check`, `spec:check`.
- [ ] 6.4 Verify no `*.cue` commit went in without its `SPEC.md` co-update: `git log --stat` over the change's commits.

## 7. Close the loop

- [ ] 7.1 Set `enhancements/0010/plan.yaml` slice `core-identity-shape` to `status: done` with `openspec_ref: core/core-identity-shape`.
- [ ] 7.2 In the **same commit**, append a `history` event to `enhancements/0010/config.yaml` citing the same `openspec_ref` in its `slice` field.
- [ ] 7.3 `task enhancements:plan:graph ID=0010` and `task enhancements:index` from the workspace root.
- [ ] 7.4 Confirm `task enhancements:plan:ready ID=0010` now surfaces `core-primitive-keying` and `core-platform-and-match`, and that `0011:core-identity-package` is unblocked.
