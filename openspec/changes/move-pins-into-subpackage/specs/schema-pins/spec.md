## ADDED Requirements

### Requirement: Schema pins live in a package no consumer loads

Every schema pin (a hidden top-level field that fixes a property of a core definition, including the commented-out MUST-FAIL cases) MUST be declared in package `pins` in `src/pins/`, in a file named `*_pins.cue`. Package `pins` MUST import `opmodel.dev/core@v2` and reference core constructs only through that import. Package `core` MUST NOT declare a pin, and a file in package `core` MUST NOT read one. Because nothing imports package `pins`, a build of `opmodel.dev/core@v2` MUST NOT load, parse or evaluate a pin, whether the consumer imports core or builds it as the main instance.

Source: owner decision 2026-10-03, kernel plan task j2.

#### Scenario: Building core as the main instance does not evaluate the pins

- **WHEN** a consumer runs `load.Instances` on `opmodel.dev/core@v2` and `BuildInstance` on the result, as the library schema loader does
- **THEN** no file under `src/pins/` is loaded, and the build retains what core without pins retains (2.8 MB measured at cue v0.17.1, against 74.7 MB with the pins in package `core`)

#### Scenario: A broken pin is invisible to a consumer's build of core

- **WHEN** `src/pins/` holds a pin that conflicts (for example `_pinBroken: 1 & 2`) and a consumer builds core as the main instance
- **THEN** core's root value carries no error from that pin. Only core's own vet reports it.

#### Scenario: A pin declared in package core is refused at review

- **WHEN** a change adds a hidden pin field to a `src/*.cue` file in package `core`
- **THEN** the change does not meet this requirement and the pin moves to `src/pins/`, because every main-instance build of core would evaluate it

### Requirement: Core's vet gates every pin without a tag

`task vet` (`cue vet ./...` from `src/`) MUST build package `pins` and fail on any pin that does not evaluate cleanly. No build tag or extra flag is involved, so no vet site can skip the pins by omission. A recorded MUST-FAIL error MUST be the error that the commented case gives when it is uncommented in place in `src/pins/`.

#### Scenario: A conflicting pin fails the vet

- **WHEN** a pin in `src/pins/` conflicts with the core definition it unifies with (for example a module whose `metadata.name` disagrees with the leaf of its `modulePath`)
- **THEN** `task vet` fails and names the pin and the conflicting path (`_failLeafMismatch.metadata._leaf: conflicting values false and true`)

#### Scenario: A consistent pin set passes the vet

- **WHEN** every pin in `src/pins/` evaluates cleanly against the core definitions it unifies with
- **THEN** `task vet` passes, and `cue vet .` from `src/` (package `core` alone) passes too
