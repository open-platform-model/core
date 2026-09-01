# Tasks: core-context-projection

Load `.claude/skills/core-schema-edit/SKILL.md` before task 1.1. Schema tasks and their SPEC.md tasks land in the same commit (Principle II); they are paired below, not scheduled apart.

## 1. src/transformer.cue

- [ ] 1.1 Add the `#transform.#context` projection block per design.md (the two computed metadata blocks with `!= _|_` guards on the optional sources; `version` from `#moduleInstance.#moduleMetadata.version`); rewrite the `#transform` doc comment (runtime supplies `#moduleInstance`, `#component`, `#runtimeName`; the context computes itself) within the 6-line rule with a `SPEC.md § 4.1` pointer. Pair: rewrite `SPEC.md` §4.1's `#TransformerContext`/`#transform` material per the pre-draft (`enhancements/0019/schemas/spec.md`), including the transitional fill rule.
- [ ] 1.2 Cross-check the projection's field sources against `library/opm/schema/context.go` field by field (name, namespace, fqn, uuid, version, labels, annotations on both blocks); record the result in this file. Any mismatch is a stop-and-ask, not a silent adaptation (the staged migration's "identical values" claim rests on it).

## 2. src/platform_and_match_pins.cue

- [ ] 2.1 Add projection pins per design.md: a minimal filled `#transform` (small instance fixture with labels, component fixture, `#runtimeName`), pinning the projected instance and component fields by interpolation, the `controllerLabels` fold, and a rendered-labels count pin (the file's masked-pin rule for open structs).
- [ ] 2.2 Add the absent-optional pin (instance without annotations, `== _|_` disunification shape) and run the divergent-fill must-fail case once in place; record it commented out with the observed cue v0.17.x error text, per the file's rules.
- [ ] 2.3 Confirm the existing `_pinRenderContext` standalone-construction pin and the 0010 D36 matchLabels pins pass untouched.

## 3. Sanity check against the enhancement delta

- [ ] 3.1 Compare the landed projection against `enhancements/0019/schemas/target.cue` § D12 (shape-identical) and `examples.cue`'s D12 assertions (same pinned values); deviations get a note in design.md.

## 4. Validation

- [ ] 4.1 `task generate:index` (doc-comment changes only); review the extracted comments in `src/INDEX.md`.
- [ ] 4.2 `task check` (fmt, vet, INDEX freshness, SPEC inventory, doc-comment limit) passes.
