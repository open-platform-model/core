# Design: core-context-projection

## Context

See `proposal.md` § Why. The design was settled in `enhancements/0019` (D12, resolving its OQ5); the CUE delta is pre-drafted and exercised in `enhancements/0019/schemas/` (`target.cue` § D12, `examples.cue`'s D12 assertions, `spec.md`'s §4.1 pre-draft). This document maps that delta onto this repo's files and protocols; it does not re-litigate the enhancement's decision.

Current state: `src/transformer.cue` declares `#transform.#context: #TransformerContext` as a bare slot; `#TransformerContext`'s two metadata blocks carry required fields the runtime fills (`library/opm/schema/context.go`), and its label/annotation folds already compute from those blocks. `src/platform_and_match_pins.cue` pins a standalone, hand-filled `#TransformerContext` (`_pinRenderContext`) for the 0010 D36 matchLabels-not-rendered assertions.

## Goals / Non-Goals

**Goals**

- Land the D12 projection in `src/transformer.cue` with the `SPEC.md` §4.1 co-update in the same commit (`core-schema-edit` protocol).
- Pins that fail if the projection stops computing or starts diverging from the sources, in this repo, at `task vet` time.

**Non-Goals**

- No `#TransformerContext` shape change: same fields, same folds, standalone construction preserved.
- No registry/platform surface (that is `core-registry-import`, the sibling slice on the same release train).
- No library-side changes: `context.go`'s staged fill-identical behavior and its eventual deletion are `library-render-cutover`'s (0019's staging plan inside D12).

## Research & Decisions

### The projection lives on `#transform`, not on `#TransformerContext`

**Context**: The computed fields need `#moduleInstance` and `#component` in scope.
**Explored**: projecting inside `#TransformerContext` itself (it has no access to the two inputs; it would need its own copies of them, a second fill surface); the `#transform` site (both inputs are lexically in scope).
**Decision**: the projection is written on `#transform.#context`, unifying `#TransformerContext` with the computed blocks. `#TransformerContext` is untouched.
**Rationale**: `enhancements/0019/schemas/target.cue` states exactly this shape, and it preserves standalone constructibility (the existing `_pinRenderContext` pin and any tooling that builds a context directly keep working). The delta, verbatim from the pre-draft:

```cue
#transform: {
	#moduleInstance: _
	#component:      _

	// CHANGED (D12): #context is no longer a bare slot. Its two metadata
	// blocks are projected from the inputs above; the runtime fills
	// #runtimeName alone.
	#context: #TransformerContext & {
		#moduleInstanceMetadata: {
			name:      #moduleInstance.metadata.name
			namespace: #moduleInstance.metadata.namespace
			fqn:       #moduleInstance.metadata.fqn
			uuid:      #moduleInstance.metadata.uuid
			version:   #moduleInstance.#moduleMetadata.version
			if #moduleInstance.metadata.labels != _|_ {
				labels: #moduleInstance.metadata.labels
			}
			if #moduleInstance.metadata.annotations != _|_ {
				annotations: #moduleInstance.metadata.annotations
			}
		}
		#componentMetadata: {
			name: #component.metadata.name
			if #component.metadata.labels != _|_ {
				labels: #component.metadata.labels
			}
			if #component.metadata.annotations != _|_ {
				annotations: #component.metadata.annotations
			}
		}
	}

	output: {...} | [...{...}]
}
```

### Guarded optional projections, matching the Go mirror's absent-stays-absent behavior

**Context**: `labels`/`annotations` are optional on both sources; an unguarded reference to an absent optional is an error, and an unconditional empty struct would turn "absent" into "empty".
**Explored**: unguarded references (error on label-less instances); defaulting to `{}` (changes observable shape: the folds would see an empty struct where they saw absence).
**Decision**: `if <source> != _|_ { ... }` guards, per the pre-draft.
**Rationale**: projects absent as absent, byte-matching what `context.go` produces today; the delta spec pins this as a requirement.

### `version` reads the module's metadata through the instance

**Context**: `#TransformerContext.#moduleInstanceMetadata.version` exists today and the runtime fills it with the module's version; `#ModuleInstance.metadata` itself carries no version (0010 D41 keeps the module's version out of instance identity).
**Decision**: `version: #moduleInstance.#moduleMetadata.version`, per the pre-draft.
**Rationale**: the only version in scope with the meaning the field always had; verified against `src/module_instance.cue` (`#moduleMetadata: #module.metadata`) and pinned by `enhancements/0019/schemas/examples.cue` (`_assertCtxInstanceVersion`).

### Pins ride `platform_and_match_pins.cue`, in a filled-`#transform` shape

**Context**: the file's rules (hidden top-level fields, pins must force evaluation, must-fail cases recorded as comments with observed text) already govern context pins, and its `_pinRenderContext` fixture is the standalone-construction case this change must keep green.
**Explored**: a new `transformer_context_pins.cue` (a third pins file for one section); extending the existing file beside the section that already pins the context.
**Decision**: extend `src/platform_and_match_pins.cue`: a minimal `#ComponentTransformer` with `#transform` filled (a small instance value with labels, a component value, `#runtimeName`), pinning the projected fields via interpolation (per the file's ONE RULE), the folds, and one absent-optional case (an instance without annotations pinned absent via the `== _|_` disunification shape the file already uses). A divergent-fill must-fail case is recorded as a comment with the observed error text, run once in place.
**Rationale**: the projection is exactly this file's subject area (what a transformer receives), the fixtures compose with what is already there, and the file's masked-pin lessons (interpolation, count pins for open structs) apply verbatim to the projected folds.

### The staged-migration constraint is spec text, not schema mechanics

**Context**: D12's staging plan has the runtime fill identical values for one release.
**Decision**: no schema mechanism marks the transition; the delta spec's transitional requirement (fill-identical MAY, divergent MUST conflict, stop after parity agreement) is the whole contract. The divergent-fill conflict is CUE unification doing its job, not code this change writes.
**Rationale**: unification of identical values is a no-op by construction; anything more (a flag, a mode) would be surface with no reader.

## Files and tracked constructs

- `src/transformer.cue`: the `#transform.#context` projection block; the `#transform` doc comment rewritten ("the runtime supplies `#moduleInstance` and `#component` concretely and `#runtimeName`; the context computes itself from them, D12"); a WHY note pointing at `SPEC.md` §4.1. Within the 6-line doc-comment rule.
- `src/platform_and_match_pins.cue`: the projection pins per the decision above.
- `SPEC.md` §4.1: Definition, Shape, Constraints (including the transitional rule), Rationale rewritten per the pre-draft (`enhancements/0019/schemas/spec.md` § `#ComponentTransformer.#transform` and `#TransformerContext`). Same commit as the CUE (pre-commit hook enforces).
- `.tasks/spec-tracked.txt`: no change; `#ComponentTransformer` and `#TransformerContext` are already tracked, nothing is added or removed.
- `src/INDEX.md`: regenerate; doc-comment changes only.

**Closedness / defaults / required-set callouts** (per this repo's design rules):

- No definition's closedness changes; no default changes; no required field is added or removed. `#runtimeName!` stays the runtime's one required fill.
- The effective tightening is behavioral: `#context`'s metadata fields go from runtime-authored to computed, so a divergent runtime fill becomes a conflict. Named in the proposal's Classification; no author-facing surface tightens.

## Risks / Trade-offs

- [A divergence between `context.go`'s fills and the projection surfaces as a render-time conflict when `library` re-pins] → the projection's field sources are cross-checked against `context.go` field by field before this releases (a verification task), and the library re-pin happens behind 0019's parity harness on the coordinated release train, so a divergence is caught in CI, not on a cluster. Experiment 01 already derived every field against the real published catalog.
  - **Cross-check outcome (2026-09-01): one divergence found and accepted.** `context.go` fills `#componentMetadata.name` with the `#components`-map key; the projection reads `#component.metadata.name`. The two diverge whenever a component authors a name different from its key — deliberate schema surface (the key is the stable embedding handle, the name the component's identity) — and `modules/k8up` does exactly that on two RBAC components. Owner decision: the projection's source is correct and lands as designed; the key-fill is the mirror drift this change ends. Consequence for the staged migration: before re-pinning, `library` must source its transitional component-name fill from evaluated `metadata.name` (not `pair.ComponentName`), or the k8up cases conflict in the parity harness; post-cutover the context name (and the `app.kubernetes.io/name`/`instance` labels) for such components follows `metadata.name`, aligning the context with what `resourceName` and `component.opmodel.dev/name` already derive. Full field table in tasks.md § 1.2.
- [Floating schema hazard: the kernel's default loader floats on the v2 line, so a cold cache picks this release up before any re-pin] → this change is agreement-additive for the old path (the kernel fills identical values, the projection unifies), so unlike `core-registry-import`'s D5 reshape it is cold-cache-safe on its own; it still rides the same coordinated train, and the cross-check task above is what backs the "identical" claim.
- [The projection reads `#moduleInstance` structurally (`.metadata.name` etc.) while `#transform.#moduleInstance` stays `_`] → deliberate: constraining the slot's type is out of scope (0019 D3 fixed the slot as `_`), and an unfilled or mis-shaped instance surfaces as an incomplete context at render, which is the pre-change failure mode too (the runtime simply had nothing to fill from).

## Migration Plan

One commit: `src/transformer.cue` + `src/platform_and_match_pins.cue` + `SPEC.md` + regenerated `src/INDEX.md`, subject `feat(transformer): project #context from the other two #transform inputs`. release-please advances the alpha; the release rides the same coordinated train as `core-registry-import` (the library wave re-pins once, picking both up). Rollback before release is a revert; after release, nothing external consumes the projection until the library wave, so a rollback release is an ordinary alpha increment.

## Open Questions

None. The one deferrable (when exactly `context.go` stops filling) is owned by 0019's staging plan and `library-render-cutover`, not by this change.
