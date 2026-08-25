## Context

`#Component.metadata.resourceName` is `*name | #NameType` (`src/component.cue:13`); `#names` reads it and derives the DNS variants. D16 flips the default to the instance-qualified form. The decision text also asks for the default to be unified with `#NameType` and for a hidden assertion that makes the overlong refusal legible, noting the v0.17.1 caveat that the validated default alone fails as a bare `incomplete value`. This slice measured the combinations before choosing a spelling.

Constraints that shape the design:

- Every `src/*.cue` edit follows `core-schema-edit`: the `SPEC.md` §`#Component` section moves in the same commit. `#Component` is already in `.tasks/spec-tracked.txt`; nothing is newly tracked.
- `#instance.name` and `metadata.name` are both `#NameType`, so the concatenation can only fail on length (a hyphen between two valid labels is always a valid label body). The assertion therefore only has to catch the 63-rune bound.
- `_matchLabelsAreDerived` sets the house style for hidden assertions: a hidden field whose only legal value is the passing one, so a violation surfaces as a conflict at a named path.

## Goals / Non-Goals

**Goals:**
- Default `resourceName` is `<instance>-<component>`; explicit `resourceName` wins; `#names.dns.*` follow.
- An overlong default fails with the concatenation in the diagnostic. An explicit name is never subject to that check.
- `SPEC.md` Shape, Constraints and Rationale updated in the same commit.

**Non-Goals:**
- Anything under D15 (transformers reading `#names`, deleting `#ResourceNameTrait`): `catalog-names-readonly`.
- Renaming rendered fleet objects: `modules-fleet-rename`.
- Touching `#ComponentNames` / `#ModuleContext` shapes (`src/module_context.cue`): the projection is unchanged; only its values move.
- A namespace or uuid segment in the default (rejected in D16).

## Research & Decisions

### Spelling of the default and the assertion
**Context**: D16 asks for `*("\(#instance.name)-\(name)" & #NameType) | #NameType` plus a hidden assertion so the overlong case fails legibly. Whether both can hold at once was untested.
**Explored**: Four spellings on cue v0.17.1 (the CI `CUE_VERSION`), each against five inputs: default-named, overlong default (40 + 30 runes), explicit override under an overlong default, invalid explicit (`"Bad_Name"`), explicit equal to the default. Scratch files under the session scratchpad `d16/`.
  - *Validated default, no assertion* (D16's literal text): overlong fails as `incomplete value =~"^[a-z0-9]..." & strings.MinRunes(1) & strings.MaxRunes(63)`, no string named. The caveat D16 records, confirmed.
  - *Validated default, assertion on the concatenation, unguarded*: overlong fails legibly, but the explicit-override case fails too (the assertion still evaluates the overlong concatenation). Wrong.
  - *Unvalidated default, assertion on the final `metadata.resourceName & #NameType`*: inert. The hidden field unifies the unresolved disjunction with `#NameType`, which succeeds non-concretely, and `cue vet -c` does not report a non-concrete hidden field. Overlong ships silently.
  - *Validated default, assertion on the concatenation guarded by `if metadata.resourceName == _resourceNameDefault`*: overlong fails as `non-concrete value ... in operand to ==`, since the failed default leaves `resourceName` non-concrete. Illegible again.
  - *Unvalidated default, guarded assertion on the concatenation*: every case behaves as specified. Overlong: `_resourceNameDefaultFits: invalid value "aaaa…-bbbb…" (does not satisfy strings.MaxRunes(63))`. Explicit override: clean, `"short"`. Invalid explicit: `2 errors in empty disjunction … invalid value "Bad_Name" (out of bound =~…)`. Explicit equal to default: clean.
**Decision**: The last spelling.
**Rationale**: D16's requirement is the outcome (an overlong concatenation refuses the render, legibly) and the caveat it records is exactly the measured failure of the validated form. Unifying the default branch with `#NameType` is what makes the guard non-evaluable, so the assertion carries the validation instead, and it can only ever catch the length bound because both operands are already `#NameType`. The unvalidated spelling D16 rejected was rejected *without* the assertion; with it, nothing ships silently. This refines the mechanism in D16, not the decision; the note goes into the delivery log summary rather than a revision of the entry.

### Diagnostics through the built-in `error()`
**Context**: With the guarded assertion in place, the overlong diagnostic read `does not satisfy strings.MaxRunes(63)` and an explicit invalid name produced nine nested "empty disjunction / invalid interpolation" lines, one of them `conflicting values "shop-web" and "Bad_Name"`, which exposes the interpolated default arm and reads as nonsense to an author. The user asked whether `error()` (CUE v0.14+, under the v0.17.0 floor) could make both clearer.
**Explored**: Three placements on cue v0.17.1. (V1) `error(...)` as a last disjunction arm on `resourceName` plus `error(...)` as the value of the hidden `_resourceNameDefaultFits` under a guard extended with `&& len(_resourceNameDefault) > 63`. (V2) V1's assertion with the plain disjunction. (V3) the how-to's assertion shape, `metadata: resourceName: error(...)` inside the guard.
**Decision**: V1.
**Rationale**: V1 turns the overlong case into one sentence naming the string, its length and the remedy, and the invalid-explicit case into a single message naming the value and the DNS-label rule; the disjunction's error arm is only reported when every other arm fails, so the default and override paths are untouched (all pass cases re-measured identical). V3 is a trap: the guard reads `metadata.resourceName`, writing to it inside the same comprehension is a cycle, and cue v0.17.1 resolves it by not applying the comprehension at all, silently, so the overlong name exports clean. The assertion therefore stays on the hidden field, and the doc comment and SPEC rationale say why. `len` is exact because `#NameType` admits ASCII only.

### Guard semantics
**Context**: The guard compares `metadata.resourceName` to the concatenation; an author who writes the default value explicitly hits the assertion too.
**Explored**: The `sameexplicit` case above.
**Decision**: Accept it. An explicit value equal to an overlong default is itself overlong and invalid, so the assertion firing there is the correct outcome, and for a valid one it passes.
**Rationale**: No extra machinery to distinguish "authored" from "defaulted" is needed, and CUE offers none without a second field.

## The CUE

`src/component.cue`, inside `#Component`:

```cue
	metadata: {
		name!: #NameType

		// Per-component resource-name override. Defaults to the
		// instance-qualified name `<instance>-<component>` (enhancement 0019
		// D16), the name every rendered primary object already carries; an
		// explicit value wins via the disjunction-default cascade. #names reads
		// from here to compute the rendered resource name and its DNS variants.
		//
		// The default branch is deliberately NOT unified with #NameType: on
		// cue v0.17.1 a failed validated default degrades to a bare
		// `incomplete value` that never names the offending string, and it
		// leaves resourceName non-concrete so the guard below cannot run.
		// _resourceNameDefaultFits carries the length check instead.
		resourceName: *"\(#instance.name)-\(name)" | #NameType | error("resourceName \"\(resourceName)\" is not a DNS label (lowercase alphanumerics and hyphens, 1-63 runes)")
	}

	// The default resource name, and the assertion that it fits a DNS label
	// when it is the name in use. Both operands are #NameType, so the only
	// way the concatenation can fail is the 63-rune bound; naming the
	// string, its length and the remedy is the point (0019 D16). Guarded so
	// an explicit override, which #NameType already validates, is never
	// measured against the default. The error MUST live on this hidden
	// field: written onto metadata.resourceName it cycles through the guard
	// and is silently dropped (measured, cue v0.17.1).
	_resourceNameDefault: "\(#instance.name)-\(metadata.name)"
	if metadata.resourceName == _resourceNameDefault && len(_resourceNameDefault) > 63 {
		_resourceNameDefaultFits: error("default resourceName \"\(_resourceNameDefault)\" is \(len(_resourceNameDefault)) runes, over the 63-rune DNS label limit: shorten the instance or component name, or set metadata.resourceName explicitly")
	}
```

`#names` is unchanged. Closedness, defaults elsewhere and the required-field set are unchanged; the only default that moves is `resourceName`'s, and the only new refusal is the overlong default.

## SPEC.md changes (`## #Component`)

- Shape: `resourceName: *"\(#instance.name)-\(name)" | #NameType  // defaults to <instance>-<component>; override cascade`, plus the two hidden fields with a one-line comment.
- Constraints: replace "defaults to `metadata.name`" with the instance-qualified default; add "When no `resourceName` is authored and the default exceeds 63 runes, the component MUST fail validation with a diagnostic naming the concatenation, its length, the limit and the remedy; an explicit `resourceName` is validated by `#NameType` alone and reported with a single custom message."
- Rationale: rewrite the "Why `resourceName` is a cascade" bullet's default case (the common case is now the qualified name, and why: collision between two instances of one module in a namespace, agreement with what fleets render, the Helm fullname convention); add "Why the default branch is not unified with `#NameType`" with the measured v0.17.1 behaviour; add "Why the diagnostics are `error()` calls, and why the assertion is a hidden field" recording the V3 trap.

## Risks / Trade-offs

- [A later cue release makes the validated default legible] → the unvalidated spelling plus assertion remains correct there too; nothing to undo.
- [Consumers pinning computed names in tests] → `library` fixtures move on its dep bump (`web.default…` becomes `probe-demo-web.default…`); named in the proposal.
- [A module author relied on the bare default for an external name contract] → the explicit `resourceName` is the escape hatch, unchanged; the fleet slice records the residual cases.

## Migration Plan

One commit, `feat(component)!: default resourceName to the instance-qualified name`, carrying `src/component.cue` and `SPEC.md` together (the pre-commit hook and the CI gate require it). Body: `BREAKING CHANGE:` paragraph stating the default flip and the new overlong refusal, and `Closes open-platform-model/core#49`. release-please cuts the next `v2.0.0-alpha.N`. Rollback is a revert of the commit and a pin-back for consumers; no rendered object moves in either direction.

## Open Questions

None.
