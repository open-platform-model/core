## Context

The gate spec was written before enhancement 0010 amended the filing rule. The component-matching spec said "declaring one MUST fail" from the start, while the code only compares key counts. The code, `SPEC.md` section 5.3 and the pins hold the real rules. These two specs lag, and `SPEC.md` line 346 carries the same too-broad sentence as the matching spec.

## Research & Decisions

### Which side wins
**Context**: Spec and code disagree on two rules.
**Explored**: Read `src/identity_package.cue` and `src/component.cue`. Ran the gate and a component on a scratch copy of `src/` with cue v0.17.1. Read the pins.
**Decision**: The specs follow the code. No code changes.
**Rationale**: The owner ruled so (2026-10-11). The pins fix the code behaviour: `_failGateFlatContractMember` and `_failGateGroupedBlueprint` in `src/pins/identity_package_pins.cue`, `_failAuthoredMatchLabel` and `_failInlineAnsweredMatchLabel` in `src/pins/platform_and_match_pins.cue`.

### Gate path
**Context**: `declaredModulePath` is unified with a list of two arms, selected by kind (`src/identity_package.cue:205-208`): the prefix for a transformer, else the prefix plus `/` plus `declaredAPIVersion`.
**Decision**: State the rule in those words. Keep the requirement header, which tools read as its name. Add the scenarios the pins already show: a flat contract member is refused, a resource files under its own version, a transformer files at the prefix.
**Rationale**: The old scenario "A conformant resource passes" used the flat path and would now fail the gate. The body changes; the name stays.

### Component matching test
**Context**: `_matchLabelsAreDerived` is `len(matchLabels) == len(_matchLabelsFromPrimitives)` (`src/component.cue:130-131`). `len` counts regular fields only; an unanswered required key (`k!`) is not counted.
**Decision**: State the test as a count of keys. Three observed cases: an invented key adds one and fails; a restated key with the same value adds none and passes; a required key answered on the component adds one (the union counts it only when a primitive answers it) and fails. A restated key with another value fails earlier, as a conflict of values.
**Rationale**: This is exactly what the code does. The old words ("declaring one MUST fail") also forbade the restated key, which the code allows.

## Risks

A scenario that states more than a pin shows could drift. Each new scenario traces to a pin or to a run on cue v0.17.1; the report lists both. Cite-lint stays at 0 findings: the new text cites an enhancement only beside a reason in words.
