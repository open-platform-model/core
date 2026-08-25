## Why

`#Component.#names` is documented as the single source of truth for a component's rendered name, but the value it computes is not the name anything renders. Every hand-rolled formula in `catalogs/opm` names the primary object `<instance>-<component>`, while `#names.resourceName` defaults to the bare component name (open-platform-model/core#49). Enhancement 0019 resolves this with D16: the default flips to the instance-qualified form so the computed name agrees with rendered reality, and it lands **before** the D15 catalog sweep so that sweep becomes a byte-identical refactor instead of a double rename (0019 06-operational, Phase A step 5). The bare default also collides outright when two instances of one module share a namespace; the qualified form is the `<release>-<chart>` convention every Helm operator already knows.

This change is `core-resourcename-default`, implementing `enhancements/0019` D16. It has no dependency on the library slices and no other slice depends on it except the sweep (`catalog-names-readonly`) and the fleet revalidation (`modules-fleet-rename`).

## What Changes

- `#Component.metadata.resourceName` defaults to `"\(#instance.name)-\(name)"` instead of `name`. An explicit `resourceName` still wins.
- An overlong default (the two `#NameType` operands plus the hyphen exceed 63 runes) refuses the render with a diagnostic that names the offending string, via a hidden assertion in the style of `_matchLabelsAreDerived`. Measured on cue v0.17.1 (the CI pin): the assertion must be guarded to the default case and the default branch must stay unvalidated for that diagnostic to be legible; see `design.md`.
- `#names.dns.*` follow by construction: service DNS becomes `<instance>-<component>.<namespace>.svc.<clusterDomain>`.
- `SPEC.md` §`#Component` co-update (Shape, Constraints, Rationale) under `core-schema-edit`.

Nothing else on `#Component` moves: closedness, the required-field set, `matchLabels`, `#instance` wiring and the `#names` projection into `#Module.#ctx.components` are unchanged.

## Classification

**BREAKING by content (a changed default), absorbed on the `@v2` alpha line** as a `feat(component)!:` alpha increment (Principle IV; this relies on `@v2` still being pre-release, as 0019 06-operational states explicitly: the flip must land before `2.0.0` graduates or it becomes a v3 event). The published constraint is not tightened; a value that validated yesterday validates today. What changes is the **computed** value of `#names.resourceName` and `#names.dns.*` for every component that does not set `resourceName`, and one new refusal: an instance name plus component name whose concatenation exceeds 63 runes, which was accepted before (and shipped a bare name) and is refused now.

## Downstream consumers

- **`library`**: no schema-shape change, so the kernel is untouched. Its fixtures pin the computed names (`web.default.svc.cluster.local` in the parity probe, `component_fill_test.go`, and `schematest` fixtures) and move to `probe-demo-web.default.svc.cluster.local` when `library` re-pins core; that is the ordinary dep-bump commit, no design work.
- **`catalog_opm`**: rendered output is unchanged because no shipped transformer reads `#names` at render time (measured at 50 transformers, 0019). The D15 sweep (`catalog-names-readonly`) consumes this release and is gated on byte-identical goldens.
- **`modules`**: the v2 staging fleet revalidates under `modules-fleet-rename`; residual renames are confined to components that set `metadata.resourceName` explicitly (silently ignored by hand-rolled formulas today, honoured after the sweep) and users of the deleted `#ResourceNameTrait`. This change itself renames nothing rendered.
- **`cli`, `opm-operator`**: no code reads `resourceName` or `#names`; they re-pin on their normal cadence.
- **`opmodel.dev`**: the generated schema reference picks up the new doc comment and SPEC text on its next `task generate`.

## Principle V

No new published field. The hidden assertion is internal (underscore field, not part of the closed shape a consumer unifies against) and exists because the measured alternative ships an invalid DNS label silently.

## Capabilities

### New Capabilities
- `component-names`: how `#Component` computes `#names.resourceName` and its DNS variants from `metadata.resourceName`, the default cascade, the explicit override, and the overlong-default refusal.

### Modified Capabilities
None. No existing capability spec covers `resourceName` or `#names`.

## Impact

- `src/component.cue` (`#Component.metadata.resourceName`, new hidden fields `_resourceNameDefault` / `_resourceNameDefaultFits`), `SPEC.md` §`#Component`.
- `src/INDEX.md` unchanged (no top-level definition added, removed or renamed); `.tasks/spec-tracked.txt` unchanged (`#Component` is already tracked).
- Closes open-platform-model/core#49 on release.
