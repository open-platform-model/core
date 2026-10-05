# schema-pins Specification

## Purpose

Where core's schema pins live and how they are gated: in the test-only package `pins` under `src/pins/`, which imports core and which nothing imports, so `task vet` evaluates every pin while no consumer's build of core loads one.

## Requirements

### Requirement: Schema pins live in a package no consumer loads

Every schema pin (a top-level field that fixes a property of a core definition, including the commented-out MUST-FAIL cases) MUST be declared in package `pins` in `src/pins/`, in a file named `*_pins.cue`. A pin MUST be a hidden field, except an applied (uncommented) pin that applies a publish gate, which follows "Publish-gate pins are applied non-hidden". Package `pins` MUST import `opmodel.dev/core@v2` and reference core constructs only through that import. Package `core` MUST NOT declare a pin, and package `core` MUST NOT import package `pins`. Because nothing imports package `pins`, a build of `opmodel.dev/core@v2` MUST NOT load, parse or evaluate a pin, whether the consumer imports core or builds it as the main instance.

Source: owner decision, 2026-10-03.

#### Scenario: Building core as the main instance does not evaluate the pins

- **WHEN** a consumer runs `load.Instances` on `opmodel.dev/core@v2` and `BuildInstance` on the result, as the library schema loader does
- **THEN** no file under `src/pins/` is among the built instance's files

#### Scenario: A broken pin is invisible to a consumer's build of core

- **WHEN** `src/pins/` holds a pin that conflicts (for example `_pinBroken: 1 & 2`) and a consumer builds core as the main instance
- **THEN** core's root value carries no error from that pin. Only core's own vet reports it.

#### Scenario: Package core declares no top-level hidden field

- **WHEN** a file of package `core` in `src/*.cue` declares a top-level hidden field
- **THEN** `task spec:check` fails, names the file and line, and points the author at `src/pins/`; with no such field it passes

### Requirement: Core's vet gates every pin without a tag

`task vet` (`cue vet ./...` from `src/`) MUST build package `pins` and fail on any pin that does not evaluate cleanly. No build tag or extra flag is involved, so no vet site can skip the pins by omission. A recorded MUST-FAIL error MUST be the error that the commented case gives when it is uncommented in place in `src/pins/`.

#### Scenario: A conflicting pin fails the vet

- **WHEN** a pin in `src/pins/` conflicts with the core definition it unifies with (for example a module whose `metadata.name` disagrees with the leaf of its `modulePath`)
- **THEN** `task vet` fails and names the pin and the conflicting path (`_failLeafMismatch.metadata._leaf: conflicting values false and true`)

#### Scenario: A consistent pin set passes the vet

- **WHEN** every pin in `src/pins/` evaluates cleanly against the core definitions it unifies with
- **THEN** `task vet` passes, and `cue vet .` from `src/` (package `core` alone) passes too

### Requirement: Publish-gate pins are applied non-hidden

An applied (uncommented) pin that unifies a value against a publish gate (`#TraitOptionalGate` or `#CatalogMemberFQNGate`) MUST be a regular (non-hidden) top-level field of package `pins`, as SPEC §5.1 requires of every gate application. A commented-out MUST-FAIL gate case MAY keep the hidden shape: a conflict is reported in a hidden field too, and its recorded error was measured in that shape. The one commented case that tests incompleteness (`failGateUnstated`) MUST be written non-hidden, because a hidden field is never checked for completeness. `cue vet` checks a regular field for completeness, so plain `task vet` MUST fail when such a pin is incomplete. Because nothing imports package `pins`, the regular field MUST NOT reach any consumer and MUST NOT add a row to `src/INDEX.md`.

Source: follow-up from the change that moved the pins into `src/pins/` (2026-10-03).

#### Scenario: A posture-gate pin with an unstated posture fails plain vet

- **WHEN** `src/pins/` applies `#TraitOptionalGate` in a regular field to a trait that never states `optional` (the recorded `failGateUnstated` case, uncommented)
- **THEN** `cue vet ./...` from `src/` exits 1 with `some instances are incomplete; use the -c flag to show errors or -c=false to allow incomplete instances`, and `cue vet -c ./...` names `failGateUnstated.optional: incomplete value bool`

#### Scenario: The conformant gate pins pass both vets

- **WHEN** every publish-gate pin in `src/pins/` applies a gate to a conformant value
- **THEN** `cue vet ./...` and `cue vet -c ./...` from `src/` both exit 0

#### Scenario: A hidden gate application checks nothing

- **WHEN** the same unstated-posture case is applied in a hidden field (`_failGateUnstated`)
- **THEN** `cue vet ./...` and `cue vet -c ./...` both exit 0, which is why a gate pin may not be hidden

#### Scenario: spec:check refuses a hidden applied gate pin

- **WHEN** an uncommented line in `src/pins/*.cue` declares a hidden top-level field whose value starts `core.#TraitOptionalGate` or `core.#CatalogMemberFQNGate`
- **THEN** `task spec:check` fails, names the file and line and this requirement, and tells the author to drop the leading underscore; commented must-fail cases are not matched
