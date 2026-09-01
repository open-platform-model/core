# Tasks: core-registry-import

Load `.claude/skills/core-schema-edit/SKILL.md` before task 1. Schema tasks and their SPEC.md tasks land in the same commit (Principle II); they are paired below, not scheduled apart.

## src/platform.cue

- [ ] 1. Replace `#Subscription` with `#CatalogEntry` (`enable: bool | *true`, `#catalog: #Catalog`, derived `version` and `#transformers` per design.md), with doc comments within the 6-line rule and the WHY block rewritten from "scalar version" to the import model. Pair: rewrite `SPEC.md` §3.4's `#Subscription` material into the `#CatalogEntry` section per the pre-draft (`enhancements/0019/schemas/spec.md`).
- [ ] 2. Reshape `#Platform`: `#registry` value type `#CatalogEntry` with the `{#catalog: metadata: modulePath: Path}` key binding; `#composedTransformers` becomes the derived non-optional fold over enabled entries (comprehension copy per entry); delete `#matchers`; rewrite the "kernel-filled slots" WHY block. Pair: `SPEC.md` §3.4 `#Platform` Definition/Shape/Constraints/Rationale per the pre-draft, including the D17 removal rationale.
- [ ] 3. Add `#CatalogEntry` to `.tasks/spec-tracked.txt`.
- [ ] 4. Sanity-check the delta against `enhancements/0019/schemas/target.cue` (shape-identical for `#CatalogEntry` and the three `#Platform` regions) and against `examples.cue`'s pinned expectations; deviations get a note in design.md.

## Validation

- [ ] 5. `task generate:index` (definition added + removed); review the extracted doc comments in `src/INDEX.md`.
- [ ] 6. `task check` (fmt, vet, INDEX freshness, SPEC inventory, doc-comment limit) passes.
- [ ] 7. Grep the repo for leftover `#Subscription` / `#matchers` references outside `openspec/changes/archive/` and `CHANGELOG.md` (docs/, README): rewrite or delete each hit.
