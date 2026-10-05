## Purpose

Defines what a `#Catalog` publishes about the contracts it defines: three member maps beside `#transformers`, keyed by contract FQN and stamping provenance, so that "this catalog defines contract X" is a stated fact of the artifact, separate from "this catalog implements contract X". The two facts diverge exactly for a provider-fulfilled contract, which its declaring catalog deliberately ships no adapter for (enhancement 0015 D1).

## Requirements

### Requirement: A catalog publishes its contracts as members

`#Catalog` MUST declare three member maps beside `#transformers`: `#resources`, whose values are `#Resource`; `#traits`, whose values are `#Trait`; and `#blueprints`, whose values are `#Blueprint`. Each map MUST be a pattern constraint with no required entries, so a catalog that lists nothing MUST remain a valid `#Catalog` with every existing field unchanged in meaning. A member listed under a map of the wrong kind MUST be refused.

#### Scenario: A listed trait is readable from the catalog value

- **WHEN** a `#Catalog` declares `#traits: (t.#BackupTrait.metadata.fqn): t.#BackupTrait` for a trait declaring `fulfilment: "provider"`
- **THEN** `#traits["<that fqn>"]` evaluates to the trait value, and its `fulfilment` reads `"provider"` without any adapter being consulted

#### Scenario: A catalog listing no contracts stays valid

- **WHEN** a `#Catalog` declares `metadata` and `#transformers` only, as every catalog published before this change does
- **THEN** the value validates, and each of `#resources`, `#traits` and `#blueprints` evaluates to an empty struct

#### Scenario: A resource listed under the trait map is refused

- **WHEN** a `#Catalog` lists a `#Resource` value under `#traits`
- **THEN** validation fails with a `conflicting values "Resource" and "Trait"` error on that member's `kind`

### Requirement: Contract members are keyed by their contract FQN

Each of the three maps MUST be keyed `#ContractFQNType`. A key in implementation form (`path/name@<semver>`) MUST be refused as a field not allowed rather than accepted as a member nothing demands.

#### Scenario: A contract-form key is accepted

- **WHEN** a `#Catalog` lists a trait under the key `"opmodel.dev/catalogs/opm/traits/backup@v1alpha1"`
- **THEN** the value validates

#### Scenario: A build-form key is refused

- **WHEN** a `#Catalog` lists a trait under the key `"opmodel.dev/catalogs/opm/transformers/backup@4.1.0"`
- **THEN** validation fails with a field-not-allowed error naming that key

### Requirement: The catalog stamps provenance onto every listed member

Each map's pattern constraint MUST stamp every member's `metadata.catalogVersion` to the catalog's own `metadata.version`, and every member's `metadata.modulePath` to the catalog's registry path, followed by the map's kind segment (`resources`, `traits` or `blueprints`), followed by the member's own `metadata.apiVersion`: the version-segment filing a contract member already declares (enhancement 0010 D49). The stamp MUST use the major-free registry path. A member MAY omit both fields and receive them from the stamp; a member that authors either field MUST agree with the stamp, and a divergent value MUST fail with a `conflicting values` error at a path naming the member.

#### Scenario: A member authored without provenance receives both stamps

- **WHEN** a `#Catalog` declaring `modulePath: "opmodel.dev/catalogs/opm@v4"` and `version: "4.1.0"` lists a trait that authors only `name`, `apiVersion: "v1beta1"` and `fqn`
- **THEN** that member's `metadata.modulePath` evaluates to `"opmodel.dev/catalogs/opm/traits/v1beta1"` and its `metadata.catalogVersion` to `"4.1.0"`

#### Scenario: A member filed under a different version segment is refused

- **WHEN** the same catalog lists a trait declaring `apiVersion: "v1alpha1"` whose authored `modulePath` ends in `/traits/v1beta1`
- **THEN** validation fails with `conflicting values` on that member's `metadata.modulePath`, naming both paths

#### Scenario: A member naming another build is refused

- **WHEN** the same catalog lists a trait authoring `catalogVersion: "3.9.0"`
- **THEN** validation fails with `conflicting values "4.1.0" and "3.9.0"` on that member's `metadata.catalogVersion`

### Requirement: The contract stamp does not cover fqn

The pattern constraints MUST NOT stamp or bind `metadata.fqn`. An `fqn` is authored at the definition site (enhancement 0010 D21); the map key carries the member's own `fqn`, and the agreement between key, `fqn` and the identity package is asserted at publish by `#CatalogMemberFQNGate`, not by `#Catalog`.

#### Scenario: Key and fqn are not compared by core

- **WHEN** a `#Catalog` lists a trait under a well-formed contract key that differs from the trait's authored `metadata.fqn`
- **THEN** `core` validates the value; the disagreement is the publish gate's to refuse

### Requirement: Publishing a contract requires no adapter

A contract MUST be listable whether or not the same catalog, or any catalog, ships a transformer requiring it. A catalog listing a `fulfilment: "provider"` contract with an empty `#transformers` MUST validate.

#### Scenario: A provider-fulfilled contract with no adapter is a valid member

- **WHEN** a `#Catalog` declares `#transformers: {}` and lists one trait declaring `fulfilment: "provider"`
- **THEN** the value validates, and the trait is readable from `#traits` by its key

### Requirement: A catalog derives the provider-fulfilled contracts it implements

`#Catalog` MUST derive a regular field `provides: [...#ContractFQNType]` holding, sorted ascending and without duplicates, the FQN of every contract that at least one of the catalog's own `#transformers` names in `requiredResources` or `requiredTraits` with a requirement whose `fulfilment` is `"provider"`. Fulfilment MUST be read from the transformer's own requirement value, never from the catalog's `#resources` or `#traits` maps, so a contract another catalog defines still counts. Optional demands (`optionalResources`, `optionalTraits`), required labels and requirements whose `fulfilment` is `"catalog"` MUST NOT contribute. A catalog with no transformers, or none requiring a provider-fulfilled contract, MUST derive `[]`. The field is derived and never authored: an authored value that disagrees MUST fail validation on `provides` (CUE reports `incompatible list lengths` when the lengths differ and `conflicting values` on the differing element otherwise). A catalog that does not author `provides`, as every catalog published before this field does not, MUST validate unchanged.

Source: library ADR-012 (the per-catalog provider set is the next derived rule to move into core). The set is what 0015:D11's claim check compares against.

#### Scenario: Two adapters requiring one provider contract derive it once

- **WHEN** a `#Catalog` ships two transformers that both list the provider-fulfilled `opmodel.dev/catalogs/opm/traits/backup@v1alpha1` trait under `requiredTraits`, and the catalog's own `#traits` does not list it
- **THEN** `provides` is `["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"]`

#### Scenario: A transformer requiring a provider-fulfilled resource contributes it

- **WHEN** a `#Catalog`'s transformer lists the provider-fulfilled resource `opmodel.dev/catalogs/s3/resources/bucket@v1alpha1` under `requiredResources` and the provider-fulfilled `backup` trait under `requiredTraits`
- **THEN** `provides` is `["opmodel.dev/catalogs/opm/traits/backup@v1alpha1", "opmodel.dev/catalogs/s3/resources/bucket@v1alpha1"]`, sorted ascending rather than in demand-map order

#### Scenario: Defining a provider contract is not providing it

- **WHEN** a `#Catalog` lists the provider-fulfilled `backup` trait in `#traits` and its only transformer requires catalog-fulfilled contracts
- **THEN** `provides` is `[]`

#### Scenario: A catalog-fulfilled required trait does not provide

- **WHEN** a `#Catalog`'s only transformer requires a catalog-fulfilled resource under `requiredResources` and a catalog-fulfilled trait under `requiredTraits`
- **THEN** `provides` is `[]`

#### Scenario: An optional resource demand does not provide

- **WHEN** a `#Catalog`'s only transformer requires a catalog-fulfilled resource and names the provider-fulfilled resource `opmodel.dev/catalogs/s3/resources/bucket@v1alpha1` under `optionalResources`
- **THEN** `provides` is `[]`

#### Scenario: An optional demand does not provide

- **WHEN** a `#Catalog`'s only transformer names the provider-fulfilled `backup` trait under `optionalTraits` and requires nothing
- **THEN** `provides` is `[]`

#### Scenario: A catalog with no transformers provides nothing

- **WHEN** `core.#Catalog` is evaluated with no `#transformers` entries
- **THEN** `provides` is `[]`

#### Scenario: An authored value that disagrees is refused

- **WHEN** a `#Catalog` whose transformers require the provider-fulfilled `backup` trait also authors `provides: []`
- **THEN** validation fails on `provides` with an `incompatible list lengths` error
