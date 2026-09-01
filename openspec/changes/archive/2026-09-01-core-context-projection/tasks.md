# Tasks: core-context-projection

Load `.claude/skills/core-schema-edit/SKILL.md` before task 1.1. Schema tasks and their SPEC.md tasks land in the same commit (Principle II); they are paired below, not scheduled apart.

## 1. src/transformer.cue

- [x] 1.1 Add the `#transform.#context` projection block per design.md (the two computed metadata blocks with `!= _|_` guards on the optional sources; `version` from `#moduleInstance.#moduleMetadata.version`); rewrite the `#transform` doc comment (runtime supplies `#moduleInstance`, `#component`, `#runtimeName`; the context computes itself) within the 6-line rule with a `SPEC.md § 4.1` pointer. Pair: rewrite `SPEC.md` §4.1's `#TransformerContext`/`#transform` material per the pre-draft (`enhancements/0019/schemas/spec.md`), including the transitional fill rule.
- [x] 1.2 Cross-check the projection's field sources against `library/opm/schema/context.go` field by field (name, namespace, fqn, uuid, version, labels, annotations on both blocks); record the result in this file. Any mismatch is a stop-and-ask, not a silent adaptation (the staged migration's "identical values" claim rests on it).

  **Cross-check record (2026-09-01, context.go at the current library main).** Nine of ten fields match source-for-source; one mismatch was found, raised as a stop-and-ask, and resolved by the owner (land as designed):
  - `#moduleInstanceMetadata.name` / `namespace` / `fqn` / `uuid`: Go reads the instance's decoded `metadata.{name,namespace,fqn,uuid}` (`InstanceName`/`Namespace`/`InstanceFQN`/`InstanceUUID`); projection reads `#moduleInstance.metadata.*`. Match.
  - `#moduleInstanceMetadata.version`: Go reads `#moduleMetadata.version` via `ModuleMetadataPath` (`ModuleVersion`); projection reads `#moduleInstance.#moduleMetadata.version` (`#moduleMetadata: #module.metadata`). Match.
  - `labels` / `annotations` on both blocks: Go decodes when present, `omitempty` drops nil (absent stays absent); projection guards with `!= _|_`. Match.
  - `#componentMetadata.name`: **MISMATCH.** Go fills the `#components`-map key (`pair.ComponentName` from the match plan); the projection reads `#component.metadata.name`. The schema deliberately lets them diverge (`name: string | *Id`) — the key is the stable embedding/addressing handle, `metadata.name` the component's own identity — and `modules/k8up` exercises it (`"manager-cluster-role"` → `"k8up-manager"`, `"executor-cluster-role"` → `"k8up-executor"`, confirmed by `cue eval`). **Resolution (owner decision):** the projection's source is correct; the Go key-fill is the mirror drift this change exists to end. Before `library` re-pins (0019 Phase B), its staged fill must source the component name from evaluated `metadata.name`, else k8up conflicts in the parity harness. Recorded in design.md § Risks, SPEC.md § 4.1 Rationale, and the pins file's must-fail case.

## 2. src/platform_and_match_pins.cue

- [x] 2.1 Add projection pins per design.md: a minimal filled `#transform` (small instance fixture with labels, component fixture, `#runtimeName`), pinning the projected instance and component fields by interpolation, the `controllerLabels` fold, and a rendered-labels count pin (the file's masked-pin rule for open structs).
- [x] 2.2 Add the absent-optional pin (instance without annotations, `== _|_` disunification shape) and run the divergent-fill must-fail case once in place; record it commented out with the observed cue v0.17.x error text, per the file's rules. (Both the component-name and instance-name variants were run once in place on cue v0.17.1; the component-name case is the recorded one, being the k8up drift class.)
- [x] 2.3 Confirm the existing `_pinRenderContext` standalone-construction pin and the 0010 D36 matchLabels pins pass untouched. (Same `task vet` run as the new pins; no existing pin edited.)

## 3. Sanity check against the enhancement delta

- [x] 3.1 Compare the landed projection against `enhancements/0019/schemas/target.cue` § D12 (shape-identical) and `examples.cue`'s D12 assertions (same pinned values); deviations get a note in design.md. (Shape-identical, same field order and guards; pins carry examples.cue's values — shop/apps/`opmodel.dev/modules/shop:shop:apps`/`0f8fad5b-…`/1.2.0, component `web`, controller fold `opm-cli`/`web`/`web`. No deviations; the pins additionally cover the rendered-labels count and the two absent-optional cases, which examples.cue does not assert.)

## 4. Validation

- [x] 4.1 `task generate:index` (doc-comment changes only); review the extracted comments in `src/INDEX.md`. (No diff: only the nested `#transform`/`#context` comments changed, and the index extracts top-level definition comments; nothing added or removed.)
- [x] 4.2 `task check` (fmt, vet, INDEX freshness, SPEC inventory, doc-comment limit) passes.
