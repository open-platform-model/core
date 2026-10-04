## ADDED Requirements

### Requirement: A catalog derives the provider-fulfilled contracts it implements

`#Catalog` MUST derive a regular field `provides: [...#ContractFQNType]` holding, sorted ascending and without duplicates, the FQN of every contract that at least one of the catalog's own `#transformers` names in `requiredResources` or `requiredTraits` with a requirement whose `fulfilment` is `"provider"`. Fulfilment MUST be read from the transformer's own requirement value, never from the catalog's `#resources` or `#traits` maps, so a contract another catalog defines still counts. Optional demands (`optionalResources`, `optionalTraits`), required labels and requirements whose `fulfilment` is `"catalog"` MUST NOT contribute. A catalog with no transformers, or none requiring a provider-fulfilled contract, MUST derive `[]`. The field is derived and never authored: an authored value that disagrees MUST fail validation on `provides` (CUE reports `incompatible list lengths` when the lengths differ and `conflicting values` on the differing element otherwise). A catalog that does not author `provides`, as every catalog published before this field does not, MUST validate unchanged.

Source: owner decision h2 of the beta.1 kernel plan walkthrough; library ADR-012 (the per-catalog provider set is the next derived rule to move into core). The set is what 0015:D11's claim check compares against.

#### Scenario: Two adapters requiring one provider contract derive it once

- **WHEN** a `#Catalog` ships two transformers that both list the provider-fulfilled `opmodel.dev/catalogs/opm/traits/backup@v1alpha1` trait under `requiredTraits`, and the catalog's own `#traits` does not list it
- **THEN** `provides` is `["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"]`

#### Scenario: A transformer requiring a provider-fulfilled resource contributes it

- **WHEN** a `#Catalog`'s transformer lists the provider-fulfilled resource `opmodel.dev/catalogs/s3/resources/bucket@v1alpha1` under `requiredResources` and the provider-fulfilled `backup` trait under `requiredTraits`
- **THEN** `provides` is `["opmodel.dev/catalogs/opm/traits/backup@v1alpha1", "opmodel.dev/catalogs/s3/resources/bucket@v1alpha1"]`, sorted ascending rather than in demand-map order

#### Scenario: Defining a provider contract is not providing it

- **WHEN** a `#Catalog` lists the provider-fulfilled `backup` trait in `#traits` and its only transformer requires catalog-fulfilled contracts
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
