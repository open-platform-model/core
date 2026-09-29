## Purpose

Lets a module author state, in the module itself, the values a freshly initialized instance of the module starts from, separately from the `debugValues` they test with.

## ADDED Requirements

### Requirement: A module may declare initValues

`#Module` SHALL accept an optional field `initValues` beside `debugValues`. The field is open: any CUE value is accepted, concrete or not, struct or not. A module without `initValues` SHALL remain valid and unchanged in meaning. `#Module` SHALL stay closed: no other new field becomes legal. Source: 0016:D3:R1, 0016:D4:R2.

#### Scenario: Module sets concrete initValues

- **WHEN** a `#Module` value sets `initValues: {replicas: 2, logLevel: "info"}`
- **THEN** it validates, and `initValues` reads back as written

#### Scenario: Module sets non-concrete initValues

- **WHEN** a `#Module` value sets `initValues: {replicas: *2 | int, logLevel: "info" | "debug", port?: int}`
- **THEN** it validates, and `initValues.logLevel` reads back as the disjunction `"info" | "debug"`

#### Scenario: Module without initValues

- **WHEN** a `#Module` value that validated before this change is evaluated again
- **THEN** it validates, and `initValues` is absent

#### Scenario: A misspelled sibling is still refused

- **WHEN** a `#Module` value sets `initValuez: {}`
- **THEN** evaluation fails with `field not allowed` naming `initValuez`

### Requirement: initValues is not checked against the config contract

The schema SHALL NOT assert that `initValues` satisfies `#config`. A module whose `initValues` does not satisfy its `#config` SHALL still validate as a module; the mismatch surfaces only where the value is consumed. Source: 0016:D4:R1.

#### Scenario: Non-conforming initValues still validates

- **WHEN** a module declares `#config: {replicas: int}` and `initValues: {replicas: "two"}`
- **THEN** the module validates

### Requirement: initValues is inert for debugValues and identity

Adding `initValues` SHALL change nothing about `debugValues`: its field, meaning and constraint are unchanged, and a module MAY carry both with different content. `initValues` SHALL NOT be an input to the module's `metadata.fqn` or `metadata.uuid`, nor to the `metadata.uuid` of any `#ModuleInstance` that deploys the module. An instance whose `#module` sets `initValues` SHALL evaluate exactly as one whose `#module` does not. Source: 0016:D3:R3.

#### Scenario: Both fields with different content

- **WHEN** a module sets `debugValues: {logLevel: "debug"}` and `initValues: {logLevel: "info"}`
- **THEN** it validates, and each field reads back its own content

#### Scenario: Identity does not move

- **WHEN** two modules differ only in that one sets `initValues`
- **THEN** their `metadata.uuid` values are equal, and so are the `metadata.uuid` values of instances with the same name and namespace deploying each

#### Scenario: Instance deploys a module with initValues

- **WHEN** a `#ModuleInstance` sets `#module` to a module that declares a non-concrete `initValues`, and supplies `values` satisfying `#config`
- **THEN** the instance validates
