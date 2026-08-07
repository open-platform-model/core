# Tasks

**Sequencing.** This change requires `core-identity-shape` to have landed — `#PackagePathType` must exist and the four kinds must already be typed with it. It is paired with `core-identity-package`, which ships the `#CatalogMemberFQNGate` that replaces the `fqn` derivation removed here. Both land in `v1.0.0-alpha.4`; neither is published alone.

**Commits.** Each group stages `src/*.cue` with its `SPEC.md` section. Load `.claude/skills/core-schema-edit/SKILL.md` first.

## 1. Key types and the API version ladder (`src/types.cue`)

- [x] 1.1 Add `#APIVersionType`: `^v[0-9]+((alpha|beta)[0-9]+)?$`. Doc-comment that it is `#MajorVersionType`'s widened sibling and that the two type different things.
- [x] 1.2 Add `#APIVersionGated` with `apiVersion!` and `gated: !strings.Contains(apiVersion, "alpha")`. Doc-comment that this is the only place the ladder is interpreted, and that it introduces no ordering.
- [x] 1.3 Rename the existing `#FQNType` regex to `#ImplFQNType`, unchanged.
- [x] 1.4 Add `#ContractFQNType` — the same path/name portion, terminated by `#APIVersionType`'s form.
- [x] 1.5 Redefine `#FQNType` as `#ContractFQNType | #ImplFQNType`. Doc-comment the deliberate `@v1` collision with `#ModulePathType` and why it is safe.
- [x] 1.6 Leave `#MajorVersionType` untouched. Confirm rather than assume — it is the type `#ArtifactRef.major` uses.
- [x] 1.7 `task vet`.

## 2. The three primitives (`src/resource.cue`, `src/trait.cue`, `src/blueprint.cue`)

- [x] 2.1 Add required `metadata.apiVersion!: #APIVersionType` to each.
- [x] 2.2 Rename `metadata.version!` to `metadata.catalogVersion!` in each. Type unchanged.
- [x] 2.3 Remove the `fqn` derivation. Declare `fqn!: #ContractFQNType` and leave the value to the catalog. Doc-comment that the agreement is enforced at publish by `#CatalogMemberFQNGate`, naming it, so the absent derivation reads as specified.
- [x] 2.4 Confirm `#definitionName` is **retained** on all three, and that each kind's `spec!` key still derives from it.
- [x] 2.5 Confirm `name` stays `#NameType` (kebab). Only `#Module.name` became snake, in `core-identity-shape`.
- [x] 2.6 Update `SPEC.md` §`#Resource`, §`#Trait`, §`#Blueprint` — Shape and Constraints for the new and renamed fields, plus a *Why* in Rationale for the derivation removal that names what replaces it.
- [x] 2.7 `task vet`.

## 3. The adapter (`src/transformer.cue`)

- [x] 3.1 Rename `metadata.version!` to `metadata.catalogVersion!`.
- [x] 3.2 Add **no** `apiVersion`. Ensure the transformer's identity shape is **closed**, so supplying one yields `field not allowed` rather than being silently ignored. Verify with a MUST-FAIL case in group 5 — this is the property that makes the exclusion structural rather than remembered.
- [x] 3.3 Remove the `fqn` derivation; declare `fqn!: #ImplFQNType`.
- [x] 3.4 Delete `#definitionName` (`src/transformer.cue:24`) — nothing reads it.
- [x] 3.5 Update `SPEC.md` §`#ComponentTransformer`, stating the adapter rationale: a transformer's inputs are other people's contracts and its output is platform objects, so "this transformer's contract major" has no referent.
- [x] 3.6 `task vet`.

## 4. Identity shapes and the category correction

- [x] 4.1 Ensure the primitive and transformer identity shapes are **independent** — no shared parent definition spanning them. If a shared shape exists after groups 2 and 3, split it now rather than trimming it.
- [x] 4.2 Move `#Blueprint` from Constructs to Primitives in `SPEC.md:29` and `:38`. Both lines, not one.
- [x] 4.3 Confirm `#Blueprint` gains **no** `fulfilment` field — that field is `core-platform-and-match`'s and is `#Resource`/`#Trait` only.
- [x] 4.4 `task vet`.

## 5. Schema-level test cases

- [x] 5.1 Positive: a resource, trait and blueprint each with an authored `#ContractFQNType` key; a transformer with an authored `#ImplFQNType` key.
- [x] 5.2 `#APIVersionGated` returns `false` for `v1alpha1` and `true` for `v1beta1` and `v1`.
- [x] 5.3 MUST FAIL: a build-shaped FQN on a primitive; a contract-shaped FQN on a transformer; a SemVer as an `apiVersion`; a primitive with `apiVersion` unset; **`apiVersion` supplied on a transformer** — assert the error is `field not allowed`, since a merely-unread field would pass.
- [x] 5.4 Pin that a resource and a trait sharing a name at one `apiVersion` produce distinct FQNs.
- [x] 5.5 MUST VET CLEAN, deliberately: a primitive whose authored `fqn` disagrees with its own `name`. This pins that `core` no longer refuses it. Comment it with the gate that does — an uncommented passing case reads as an oversight, and this one is the trade D21 made.

## 6. Generated artifacts and gates

- [x] 6.1 `task generate:index` — `#APIVersionType`, `#APIVersionGated`, `#ContractFQNType`, `#ImplFQNType` added; `#FQNType` redefined.
- [x] 6.2 `.tasks/spec-tracked.txt` — no change expected. The four kinds are already tracked; the new types are constrained-string types and a helper, which the `core-schema-edit` allowlist puts out of scope. Confirm.
- [x] 6.3 `task check`.

## 7. Close the loop

- [x] 7.1 `enhancements/0010/plan.yaml`: slice `core-primitive-keying` → `status: done`, `openspec_ref: core/core-primitive-keying`.
- [x] 7.2 Same commit: `history` event in `enhancements/0010/config.yaml` citing that ref.
- [x] 7.3 `task enhancements:plan:graph ID=0010` and `task enhancements:index`.
