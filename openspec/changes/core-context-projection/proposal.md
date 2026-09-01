## Why

`#transform` declares three inputs and the runtime hand-assembles one of them: `#context`'s two metadata blocks are decoded out of the instance and the component by `library/opm/schema/context.go` and re-encoded into a fresh value, a hand-maintained mirror of a derivation the schema could compute itself. Enhancement 0019 D12 ends that: `#TransformerContext` becomes a projection of `#transform`'s other two inputs, computed at the `#transform` site where both are already in scope, and the runtime's obligation narrows to `#runtimeName`, the one field nothing in the artifacts can know. Landing it now, beside `core-registry-import`, is itself a 0019 decision: under D9 the render is one CUE build, and a deferred projection would have the generated render glue hand-roll in CUE exactly what core can compute, then move it here later (churn D12's rationale explicitly rejects). The 0019 Phase B wave (`library-render-build`) consumes this release.

This change is `core-context-projection`, implementing `enhancements/0019` D12. The delta is pre-drafted and exercised in `enhancements/0019/schemas/` (`target.cue`, `examples.cue`, `spec.md`); this change lands it in `src/transformer.cue` and `SPEC.md` §4.1.

## What Changes

- `#ComponentTransformer.#transform.#context` stops being a bare `#TransformerContext` slot and gains the projection: `#moduleInstanceMetadata` computed from `#moduleInstance` (`name`, `namespace`, `fqn`, `uuid`, `version` via `#moduleMetadata.version`, guarded `labels`/`annotations`) and `#componentMetadata` computed from `#component` (`name`, guarded `labels`/`annotations`). Optional sources that are absent project as absent, not as errors or empty structs (guarded with `!= _|_`, matching what the Go mirror does today).
- `#TransformerContext` itself is unchanged in shape: same fields, same label and annotation folds (which were already projections of the two metadata blocks), `#runtimeName!` still required and runtime-supplied. A standalone `#TransformerContext` value remains constructible.
- The `#transform` doc comment ("The runtime supplies all three inputs concretely") is rewritten: the runtime supplies `#moduleInstance` and `#component` concretely plus `#runtimeName`; the context computes itself from them.
- Schema pins: projection assertions added beside the existing `_pinRenderContext` in `src/platform_and_match_pins.cue` (a filled `#transform` whose projected context fields, folds and rendered labels are pinned, in the style of `enhancements/0019/schemas/examples.cue`'s D12 section).
- `SPEC.md` §4.1 co-update (Definition, Shape, Constraints, Rationale) under `core-schema-edit`, following the pre-draft in `enhancements/0019/schemas/spec.md`, including the transitional rule: a runtime MAY keep filling the projected fields while every value it fills is identical to what the projection computes, and MUST stop once the parity harness reports agreement.

## Classification

**MINOR in surface (`feat(transformer):`), with one stated tightening, absorbed on the `@v2` alpha line.** From a transformer author's perspective the change is additive: the same field names hold the same values. The tightening is runtime-facing: a runtime that fills a context value DIVERGENT from what the projection computes now gets a unification conflict instead of silently winning. The only runtime is `library`, whose fills are identical by construction (measured by `enhancements/0019/experiments/01-purecue-render-flow`'s `_contextFor` and enforced by the parity harness); the staged migration (fill-identical, then remove the Go fills) is D12's stated plan, so there is no flag day. This relies on `@v2` still being pre-release only in the weak sense that a divergence discovered late would be an alpha-line fix; the change removes nothing.

## Downstream consumers

- **`library`**: no immediate action; it stays pinned to the prior alpha until its 0019 Phase B wave (the same sequencing `core-registry-import` states, and this change rides the same coordinated release train). At re-pin, `opm/schema/context.go` keeps filling identical values for one release while the parity harness confirms agreement, then the Go fills and the mirror are deleted (`library-render-cutover`); the render glue in `library-render-build` fills `#runtimeName` only and never carries an interim context derivation.
- **`cli` / `opm-operator`**: no action; both supply the runtime name through the kernel and never build a context by hand.
- **`catalog_opm` / catalogs**: no action; transformers read the same context fields with the same values. No republish needed on this change's account.
- **`modules`**: no impact.
- **`opmodel.dev`**: generated schema reference picks up the reshape on its next `task generate`.

## Principle V

No new definition and no new field: the change moves an existing obligation from a Go mirror into the schema, which is Principle III's "derived values SHOULD be computed in the schema" applied to a value that was already half-derived (the folds). The consumer exists today (`library-render-build` reads this release).

## Capabilities

### New Capabilities

- `transformer-context`: the projection contract for `#transform.#context`: which fields are computed from which input, the absent-optional rule, `#runtimeName` as the sole runtime obligation, and the transitional fill rule for staged runtimes.

### Modified Capabilities

None. `component-matching`'s one context requirement (matchLabels never reaches `componentLabels`, 0010 D36) is untouched: the folds do not change.

## Impact

- `src/transformer.cue`: the `#transform.#context` projection block and the rewritten doc comments.
- `src/platform_and_match_pins.cue`: projection pins beside the existing context pin.
- `SPEC.md` §4.1 (same commit, `core-schema-edit` protocol).
- `src/INDEX.md`: regenerate (doc-comment changes only; no definition added or removed).
- `.tasks/spec-tracked.txt`: no change (`#ComponentTransformer` and `#TransformerContext` are already tracked; nothing new, nothing removed).
