## ADDED Requirements

### Requirement: A contract declares where its fulfilment comes from

`#Resource` and `#Trait` MUST each carry `fulfilment: *"catalog" | "provider"`, a closed enum defaulting to `"catalog"`.

- `"catalog"` — the declaring catalog implements it. Today's behaviour.
- `"provider"` — the declaring catalog ships no transformer for it, deliberately, and fulfilment is expected from a transformer in another catalog.

#### Scenario: An existing primitive is unchanged

- **WHEN** a `#Resource` is declared without mentioning `fulfilment`
- **THEN** `fulfilment` is `"catalog"`, and nothing about the primitive's behaviour changes

#### Scenario: A provider-fulfilled contract is declarable

- **WHEN** a `#Resource` declares `fulfilment: "provider"`
- **THEN** the value validates

#### Scenario: A third mode is refused

- **WHEN** a `#Trait` declares `fulfilment: "external"`
- **THEN** validation fails against the closed enum

### Requirement: A blueprint declares no fulfilment

`#Blueprint` MUST NOT carry `fulfilment`. A transformer declares `requiredResources` and `requiredTraits` and has no blueprint equivalent, so a blueprint can never be demanded and the field would be unreachable.

#### Scenario: Fulfilment on a blueprint is inexpressible

- **WHEN** a `#Blueprint` declares `fulfilment: "provider"`
- **THEN** validation fails with a field-not-allowed error

### Requirement: A provider-fulfilled contract admits exactly one provider

For a contract declaring `fulfilment: "provider"`, a platform MUST carry exactly one transformer *requiring* that contract. Two MUST be refused, naming both catalog paths and the contract key. Zero is an unresolved demand.

This is enforced at materialize rather than by the schema — `core` declares the intent; counting transformers across a materialized set is the kernel's. The requirement is stated here because it is what `fulfilment: "provider"` means.

#### Scenario: Two providers for one contract are refused

- **WHEN** a platform materializes two catalogs whose transformers both declare the same provider-fulfilled contract in `requiredResources`
- **THEN** materialize fails, naming both catalog paths and the contract key, with no arbitration between them

#### Scenario: One provider is accepted

- **WHEN** exactly one materialized transformer requires the provider-fulfilled contract
- **THEN** materialize succeeds

#### Scenario: Optional demands do not count as provision

- **WHEN** a transformer names a provider-fulfilled contract among its optional demands rather than its required ones
- **THEN** it is not counted as a provider of that contract

### Requirement: Every declared resource is a required demand

Every resource a component declares MUST be a demand the platform must satisfy. A demanded resource FQN that no transformer in the platform supplies MUST fail the render immediately.

A resource MUST NOT have a demand-side optionality marker.

#### Scenario: An unsupplied resource fails the render

- **WHEN** a component declares a resource whose FQN no materialized transformer supplies
- **THEN** the render fails, naming the unresolved FQN

#### Scenario: A component with a partially satisfied set does not render

- **WHEN** a component declares two resources and the platform supplies a transformer for only one
- **THEN** the render fails rather than emitting output for the satisfied one

### Requirement: A trait states its own optionality, and the attachment may override it

`#Trait` MUST carry `optional: bool`. `core` MUST NOT give it a default: the declaring catalog states the posture, and MUST state it as a *default* (`bool | *true` for advisory, `bool | *false` for load-bearing) rather than as a concrete value.

A `#Component` MUST be able to override the declared posture at the attachment site, in either direction, without conflict. A `#Component` MUST NOT carry an optionality field of its own.

#### Scenario: An unhandled load-bearing trait fails

- **WHEN** a component declares a trait no materialized transformer handles, whose resolved `optional` is `false`
- **THEN** the render fails, naming the trait

#### Scenario: An unhandled advisory trait warns

- **WHEN** the same trait's resolved `optional` is `true`
- **THEN** the render continues and a warning names the unhandled trait

#### Scenario: A module overrules the catalog in either direction

- **WHEN** a component attaches a trait the catalog declared `bool | *false` and writes `optional: true` at the attachment site
- **THEN** the resolved value is `true`, with no conflict, and the catalog's own definition is unchanged
- **AND** the same holds in reverse for a trait declared `bool | *true` and attached with `optional: false`

### Requirement: A catalog may suggest a posture but may not decide it

A published `#Trait` whose `optional` is never stated, or is pinned to a concrete value, MUST be refused at publish. `core` MUST ship the rule as a definition a publishing tool unifies against, so the diagnostic is CUE's own.

This is enforced at publish rather than by the schema: CUE cannot express "this field may be given a default here but not a concrete value", because what distinguishes the two cases is who wrote it.

#### Scenario: A posture stated as a default is accepted

- **WHEN** a catalog publishes a trait declaring `optional: bool | *false`
- **THEN** the gate passes

#### Scenario: A pinned posture is refused

- **WHEN** a catalog publishes a trait declaring `optional: false`
- **THEN** publish fails, because no module could override it

#### Scenario: An unstated posture is refused

- **WHEN** a catalog publishes a trait that never mentions `optional`
- **THEN** publish fails under concrete evaluation, naming the field
