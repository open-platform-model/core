## Purpose

Defines where a contract's implementation is expected to come from, and what a component's demands oblige the platform to supply. Covers the `fulfilment` declaration on `#Resource` and `#Trait` and why `#Blueprint` is excluded structurally, the single-provider rule for a provider-fulfilled contract, the requirement that every declared resource be satisfied, and how a trait's optionality is stated by its declaring catalog, overridden at the attachment site, and held to that shape by a publish gate.

## Requirements

### Requirement: A contract declares where its fulfilment comes from

`#Resource` and `#Trait` MUST each carry `fulfilment: *"catalog" | "provider"`, a closed enum defaulting to `"catalog"`.

- `"catalog"` — the declaring catalog implements it. The default.
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

For a contract declaring `fulfilment: "provider"`, a platform MUST carry exactly one provider of that contract, a provider being an enabled registry entry whose transformers *require* the contract. Two providers MUST be refused, naming both registry keys and the contract key, and remain refused when the render's caller asked to skip unprovided demands (see "A render's caller may ask to skip unprovided demands"). This rule is enforced outside the schema.

#### Scenario: Two providers for one contract are refused

- **WHEN** a platform enables two catalogs whose transformers both declare the same provider-fulfilled contract in `requiredResources`
- **THEN** the render build refuses, naming both catalog paths and the contract key, with no arbitration between them

#### Scenario: One provider is accepted

- **WHEN** exactly one enabled catalog carries transformers requiring the provider-fulfilled contract, whether one transformer or several
- **THEN** the render build does not refuse on the provider count

#### Scenario: Optional demands do not count as provision

- **WHEN** a transformer names a provider-fulfilled contract among its optional demands rather than its required ones
- **THEN** it is not counted as a provider of that contract

#### Scenario: Two majors of one provider catalog are two providers

- **WHEN** a platform enables `opmodel.dev/catalogs/k8up@v2` and `opmodel.dev/catalogs/k8up@v3`, and a transformer of each requires the same provider-fulfilled contract
- **THEN** the platform's contract inventory reports the contract over-subscribed and not routable, naming both registry keys, and the render build refuses on that same count

#### Scenario: Providers count when the defining catalog is not enabled

- **WHEN** the catalog defining a provider-fulfilled contract is disabled or absent, and two enabled entries have transformers requiring it
- **THEN** the platform's contract inventory reports the contract over-subscribed and not routable, and the render build refuses on that same count

### Requirement: Every declared resource is a required demand

Every resource a component declares MUST be a demand the platform must satisfy. A demanded resource FQN that no transformer in the platform supplies MUST fail the render immediately, with one exception: an unprovided provider-fulfilled resource the render's caller asked to skip, which omits the whole component instead (see "A render's caller may ask to skip unprovided demands"). A component whose resource set is only partly satisfied MUST NOT render output for the satisfied part.

#### Scenario: An unsupplied resource fails the render

- **WHEN** a component declares a resource whose FQN no enabled transformer on the platform supplies, and the resource is catalog-fulfilled or the caller did not ask to skip unprovided demands
- **THEN** the render fails, naming the unresolved FQN

#### Scenario: A component with a partially satisfied set does not render

- **WHEN** a component declares two resources and the platform supplies a transformer for only one
- **THEN** the render fails rather than emitting output for the satisfied one, or, when the unsupplied resource is an unprovided provider-fulfilled one the caller asked to skip, the component renders nothing and the skip is reported

### Requirement: A trait states its own optionality, and the attachment may override it

A `#Component` MUST be able to override the declared posture at the attachment site, in either direction, without conflict.

An unhandled trait whose resolved `optional` is `false` fails the render, except when its contract is provider-fulfilled, nothing on the platform provides it, and the render's caller asked to skip unprovided demands (see "A render's caller may ask to skip unprovided demands").

#### Scenario: An unhandled load-bearing trait fails

- **WHEN** a component declares a trait no enabled transformer on the platform handles, whose resolved `optional` is `false`, and the trait is catalog-fulfilled or the caller did not ask to skip unprovided demands
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

### Requirement: The provider count is of registry entries

The provider count MUST be of registry entries, keyed by registry key (the catalog module path with its major): two transformers of one entry are one provider, and two enabled majors of one catalog are two. A provider MUST count whether or not any enabled entry defines the contract.

#### Scenario: Two transformers of one entry are one provider

- **WHEN** two transformers of one enabled registry entry both require a provider-fulfilled contract
- **THEN** the entry is counted as one provider

### Requirement: Zero providers are an unresolved demand

Zero providers of a provider-fulfilled contract MUST be an unresolved demand, which fails the render unless the render's caller asked to skip unprovided provider-fulfilled demands (see "A render's caller may ask to skip unprovided demands").

#### Scenario: A contract with no provider fails the render

- **WHEN** a demanded provider-fulfilled contract has no provider and the render's caller did not ask to skip unprovided demands
- **THEN** the render fails on the unresolved demand

### Requirement: The contract inventory computes the provider count once

`core` MUST declare "A provider-fulfilled contract admits exactly one provider" and compute the provider count once, as the platform's contract inventory (`#Platform.#contracts.providedBy`, `overSubscribed` and `routable`), which MUST report it without refusing on it. The requirement is stated here because it is what `fulfilment: "provider"` means.

#### Scenario: The inventory reports the count without refusing

- **WHEN** a platform has a contract with two providers
- **THEN** `#Platform.#contracts` reports it in `overSubscribed` and `routable`, and `core` refuses nothing

### Requirement: The render build and the generation step refuse on the one count

The kernel's render build and the generation step (operator, CLI) MUST refuse on the inventory's one provider count; none of them keeps a count of its own.

#### Scenario: Consumers refuse on the inventory count

- **WHEN** a platform's contract inventory reports a contract as over-subscribed
- **THEN** the render build and the generation step refuse on that one count and keep no count of their own

### Requirement: A resource has no demand-side optionality marker

A resource MUST NOT have a demand-side optionality marker.

#### Scenario: A resource carries no optionality marker on the demand side

- **WHEN** a component declares a resource
- **THEN** the demand for it carries no optionality marker, so the platform must satisfy it

### Requirement: A trait carries a posture its catalog states as a default

`#Trait` MUST carry `optional: bool`. `core` MUST NOT give it a default: the declaring catalog states the posture, and MUST state it as a *default* (`bool | *true` for advisory, `bool | *false` for load-bearing) rather than as a concrete value. A `#Component` MUST NOT carry an optionality field of its own.

#### Scenario: Core gives optional no default

- **WHEN** a `#Trait` is evaluated with no declaring catalog stating `optional`
- **THEN** `core` supplies no default for `optional`

#### Scenario: A component carries no optionality field

- **WHEN** a `#Component` is evaluated
- **THEN** it carries no optionality field of its own

### Requirement: A render's caller may ask to skip unprovided demands

A render's caller MAY ask the render to skip every demand that is *unprovided*: a demand on a contract declaring `fulfilment: "provider"` for which no enabled catalog on the platform carries a transformer requiring the demanded key, the single-provider count at zero. The request MUST be per render and belong to the caller; without it, every render MUST behave as the other requirements of this capability state.

#### Scenario: A provider on the platform is used, not skipped

- **WHEN** exactly one enabled catalog carries a transformer requiring the provider-fulfilled contract, that transformer matches the component, and the caller asked to skip unprovided demands
- **THEN** the render uses that provider's transformer, and nothing is reported as skipped

### Requirement: Only unprovided demands are skippable

Only unprovided demands are skippable. Under the request:

- a demand on a catalog-fulfilled contract that nothing supplies MUST still fail the render;
- a demand on a provider-fulfilled contract whose provider is present on the platform but did not match the component MUST still fail the render;
- an over-subscribed provider-fulfilled contract MUST still be refused.

#### Scenario: A catalog-fulfilled demand still refuses under the request

- **WHEN** a component demands a catalog-fulfilled resource that no transformer on the platform supplies, and the caller asked to skip unprovided demands
- **THEN** the render fails, naming the unresolved contract key

#### Scenario: A present provider that did not match still refuses

- **WHEN** a component attaches a provider-fulfilled, load-bearing trait, exactly one enabled catalog on the platform carries a transformer requiring that contract, that transformer does not match the component, and the caller asked to skip unprovided demands
- **THEN** the render fails, naming the unresolved contract key

#### Scenario: An over-subscribed contract still refuses under the request

- **WHEN** transformers from two enabled catalogs both require the same provider-fulfilled contract, and the caller asked to skip unprovided demands
- **THEN** the render is refused, naming both catalog paths and the contract key

### Requirement: A skipped trait demand leaves the rest of its component rendering

A skipped **trait** demand MUST leave its component rendering every pair it matched; the trait itself renders nothing.

#### Scenario: A skipped trait lets the rest of the component render

- **WHEN** a component attaches a trait whose contract declares `fulfilment: "provider"` and resolves `optional: false`, no enabled catalog on the platform carries a transformer requiring that contract, and the render's caller asked to skip unprovided demands
- **THEN** the render succeeds and the component renders every pair it matched
- **AND** the report names the component, the trait's contract key and the trait kind

### Requirement: A skipped resource demand omits the whole component

A skipped **resource** demand MUST leave its component rendering nothing at all, so a partly satisfied component still never renders, and that component MUST NOT be reported as unmatched.

#### Scenario: A skipped resource omits the whole component

- **WHEN** a component declares two resources, one of which is provider-fulfilled with zero providers on the platform, the other supplied by a matched transformer, and the render's caller asked to skip unprovided demands
- **THEN** the render succeeds and the component renders no object, not even for the supplied resource
- **AND** the component is not reported as unmatched
- **AND** the report names the component, the resource's contract key, and that the component rendered nothing

#### Scenario: Without the request the render still refuses

- **WHEN** the same component renders on the same platform and the caller did not ask to skip unprovided demands
- **THEN** the render fails, naming the unresolved contract key

### Requirement: Every skipped demand is reported

Every skipped demand MUST be reported, naming the component, the contract key and whether it was a resource or a trait demand; a skipped resource demand's report MUST also say that the whole component rendered nothing. A skip MUST never be silent. An unhandled trait whose resolved `optional` is `true` is unaffected by the request: it continues with a warning, with or without it.

#### Scenario: An advisory trait warns with or without the request

- **WHEN** a component attaches an unhandled trait whose resolved `optional` is `true` and the caller asked to skip unprovided demands
- **THEN** the render continues with a warning, as it does without the request

### Requirement: The kernel enforces the skip rule and the inventory is unchanged

Enforcement of the skip rule MUST be the kernel's, like the rest of this capability. `core` states the rule; the platform's contract inventory MUST be unchanged by it.

#### Scenario: The inventory does not change under the request

- **WHEN** a render's caller asked to skip unprovided demands
- **THEN** the platform's contract inventory is unchanged
