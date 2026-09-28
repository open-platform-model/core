## Context

See proposal.md for motivation and specs/module-init-values/spec.md for the behavior contract. The design intent is `enhancements/0016` D3 and D4; `schemas/target.cue` and `schemas/spec.md` there pre-draft the shape and the SPEC.md text.

Current state:

- `src/module.cue` declares `#config: _` and `debugValues: _` on the closed `#Module`. `debugValues` is a regular, open field whose doc comment reads "Example values for testing and debugging".
- `#Module` is tracked in `.tasks/spec-tracked.txt`; its SPEC.md section is § 3.2 (Shape, Constraints, Rationale).
- `#ModuleInstance.#module` re-unifies an already-closed `#Module` value. SPEC.md § 3.2 records a past bug where a field that was not a registered member of the closed definition was rejected on that second unification, so an optional field has to survive it.

## Goals / Non-Goals

**Goals:**

- Add the field with no change to any existing module's validity, identity or `debugValues` meaning.
- Pin every spec scenario in a `*_pins.cue` fixture so `task vet` checks it on every commit.

**Non-Goals:**

- Asserting `initValues & #config` (0016 D4 rejected it: it would evaluate the config contract on every module load for a check only init cares about).
- Any change to `#ModuleInstance`, the kernel or the CLI.

## Decisions

### Shape

```cue
// src/module.cue, inside #Module, directly after debugValues
	// debugValues: Example values for testing and debugging.
	// It is unified and validated in the runtime
	debugValues: _

	// WHY optional, open and not unified with #config: 0016:D3/D4.
	// SPEC.md § 3.2 Rationale.

	// Values a freshly initialized instance package starts from.
	// Optional; MAY be non-concrete. Not checked against #config here.
	// See SPEC.md § 3.2.
	initValues?: _
```

- **Closedness**: unchanged. `#Module` stays closed; `initValues` is one newly permitted optional member.
- **Required-field set**: unchanged. The field is optional (`?`).
- **Defaults**: none added.
- **Tracked constructs**: none added. `#Module` is already tracked; its SPEC.md § 3.2 moves with this change (Shape, Constraints, Rationale).

### Files touched

| File | Change |
| --- | --- |
| `src/module.cue` | The field above |
| `src/module_init_values_pins.cue` (new) | One hidden pin per spec scenario (see Pins) |
| `SPEC.md` § 3.2 | Shape line, Constraints (including the order tooling reads `initValues` and `debugValues` in), three Rationale bullets |
| `docs/constructs.md` | `initValues` beside `debugValues` in the `#Module` walkthrough |
| `src/INDEX.md` | Regenerated; the Project Structure tree gains the new pins file |

### Pins

Hidden top-level fields in `src/module_init_values_pins.cue`, following the convention of `identity_pins.cue` (no leading underscore in the file name, MUST-FAIL cases commented out with the exact error recorded):

```cue
_pinInitConcrete:    #Module & {/* … */ initValues: {replicas: 2, logLevel: "info"}}
_pinInitOpen:        #Module & {/* … */ initValues: {replicas: *2 | int, logLevel: "info" | "debug", port?: int}}
_pinInitDisjunction: _pinInitOpen.initValues.logLevel & ("info" | "debug")
_pinInitNonConforming: #Module & {/* … */ #config: {replicas: int}, initValues: {replicas: "two"}}
_pinInitBoth:        #Module & {/* … */ debugValues: {logLevel: "debug"}, initValues: {logLevel: "info"}}
_pinInitSameModuleUUID:   _pinPlain.metadata.uuid & _pinInitConcrete.metadata.uuid
_pinInitInstance:    #ModuleInstance & {/* … */ #module: _pinInitOpen, values: {…}}
_pinInitSameInstanceUUID: _pinInstancePlain.metadata.uuid & _pinInitInstance.metadata.uuid
// MUST-FAIL: _pinInitTypo: #Module & {/* … */ initValuez: {}}
//   -> _pinInitTypo.initValuez: field not allowed
```

## Research & Decisions

### Does an optional open field survive `#ModuleInstance` re-unification?

**Context**: SPEC.md § 3.2 records a past bug in which the closed `#Module` rejected a field on its second unification inside `#ModuleInstance.#module`. Enhancement 0016 experiment 06 measured module-level vetting only, not the instance path.
**Explored**: A spike on a scratch copy of `src/` (2026-09-28): `initValues?: _` added after `debugValues`, then pins for a module setting non-concrete `initValues` and a `#ModuleInstance` deploying it. `cue vet ./...` was green. `_spikeInstanceInit.#module.initValues` evaluated to `{replicas: 2, logLevel: "info" | "debug"}`, with the default resolved, the disjunction kept and the optional field omitted, matching experiment 04. A sibling `initValuez` still failed with `field not allowed`. Two modules differing only in `initValues` produced equal module uuids (`720355ca-…`), and their instances produced equal instance uuids (`87395189-…`). A module with `#config: {replicas: int}` and `initValues: {replicas: "two"}` vetted.
**Decision**: Add the field as `initValues?: _` with no further schema surface.
**Rationale**: Every spec scenario held on the spike, so section 1 is the implementation, not a spike. The pins make the same checks permanent.

### Optional versus regular field

**Context**: `debugValues` is a regular field (`debugValues: _`), so it always exists as top.
**Decision**: `initValues` is optional (`?`), per 0016 D4.
**Rationale**: A consumer must be able to tell "the author declared no init values" from "the author declared `_`". An optional field is absent until set, so the CLI's ladder can fall through to `debugValues`; a regular `_` would always exist and never fall through.

## Risks / Trade-offs

- [A module that sets `initValues` fails against an older core with `field not allowed`] -> The ordinary floor of an additive field on a closed definition. SPEC.md § 3.2 Constraints states it, and `task deps:update` moves a module's pin.
- [Authors may expect `initValues` to be validated against `#config`] -> The doc comment says it is not checked here, and SPEC.md Rationale says why. The CLI points users at `opm instance vet`.
- [Non-concrete `initValues` inside a deployed module] -> Harmless. The spike shows the instance validates, and `debugValues: _` already puts non-concrete content inside `#module` in every module today.

## Migration Plan

None. The field is additive and optional. Rollback is reverting the commit; no module can depend on the field until a release ships it.
