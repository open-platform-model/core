## MODIFIED Requirements

### Requirement: The catalog stamps provenance onto every listed member

Each map's pattern constraint MUST stamp every member's `metadata.catalogVersion` to the catalog's own `metadata.version`, and every member's `metadata.modulePath` to the catalog's major-free registry path, then the map's kind segment, then the member's own `metadata.apiVersion`. A member MAY omit both fields and receive them from the stamp; a member that authors either field MUST agree with the stamp, and a divergent value MUST fail with a `conflicting values` error at a path naming the member.

#### Scenario: A member authored without provenance receives both stamps

- **WHEN** a `#Catalog` declaring `modulePath: "opmodel.dev/catalogs/opm@v4"` and `version: "4.1.0"` lists a trait that authors only `name`, `apiVersion: "v1beta1"` and `fqn`
- **THEN** that member's `metadata.modulePath` evaluates to `"opmodel.dev/catalogs/opm/traits/v1beta1"` and its `metadata.catalogVersion` to `"4.1.0"`

#### Scenario: A member filed under a different version segment is refused

- **WHEN** the same catalog lists a trait declaring `apiVersion: "v1alpha1"` whose authored `modulePath` ends in `/traits/v1beta1`
- **THEN** validation fails with `conflicting values` on that member's `metadata.modulePath`, naming both paths

#### Scenario: A member naming another build is refused

- **WHEN** the same catalog lists a trait authoring `catalogVersion: "3.9.0"`
- **THEN** validation fails with `conflicting values "4.1.0" and "3.9.0"` on that member's `metadata.catalogVersion`

## ADDED Requirements

### Requirement: A stamped module path files a contract member under its version segment

The stamped `metadata.modulePath` of a contract member MUST end in the map's kind segment (`resources`, `traits` or `blueprints`) followed by the member's own `metadata.apiVersion`: the version-segment filing a contract member already declares (enhancement 0010, "Contract kinds file under a version segment (`<kind>/<apiVersion>/`) derived from the key").

#### Scenario: The kind segment names the map

- **WHEN** a member is listed in `#resources`, `#traits` or `#blueprints`
- **THEN** the stamped `metadata.modulePath` carries the map's kind segment `resources`, `traits` or `blueprints` respectively

#### Scenario: The stamped path ends in the member apiVersion

- **WHEN** a member declaring `apiVersion: "v1beta1"` is listed in `#traits`
- **THEN** its stamped `metadata.modulePath` ends in the kind segment `traits` followed by `v1beta1`

### Requirement: A catalog derives the provider-fulfilled contracts its transformers require

`#Catalog` MUST derive a regular field `provides: [...#ContractFQNType]` holding the FQN of every contract that at least one of the catalog's own `#transformers` names in `requiredResources` or `requiredTraits` with a requirement whose `fulfilment` is `"provider"`.

Source: library ADR-012 (the per-catalog provider set is the next derived rule to move into core). The set is what the claim check of enhancement 0015 compares against.

#### Scenario: Defining a provider contract is not providing it

- **WHEN** a `#Catalog` lists the provider-fulfilled `backup` trait in `#traits` and its only transformer requires catalog-fulfilled contracts
- **THEN** `provides` is `[]`

### Requirement: The provides field is sorted ascending and holds no duplicates

The `provides` field MUST hold its FQNs sorted ascending and without duplicates.

#### Scenario: Two adapters requiring one provider contract derive it once

- **WHEN** a `#Catalog` ships two transformers that both list the provider-fulfilled `opmodel.dev/catalogs/opm/traits/backup@v1alpha1` trait under `requiredTraits`, and the catalog's own `#traits` does not list it
- **THEN** `provides` is `["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"]`

#### Scenario: A transformer requiring a provider-fulfilled resource contributes it

- **WHEN** a `#Catalog`'s transformer lists the provider-fulfilled resource `opmodel.dev/catalogs/s3/resources/bucket@v1alpha1` under `requiredResources` and the provider-fulfilled `backup` trait under `requiredTraits`
- **THEN** `provides` is `["opmodel.dev/catalogs/opm/traits/backup@v1alpha1", "opmodel.dev/catalogs/s3/resources/bucket@v1alpha1"]`, sorted ascending rather than in demand-map order

### Requirement: Fulfilment is read from the transformer's own requirement

Fulfilment MUST be read from the transformer's own requirement value, never from the catalog's `#resources` or `#traits` maps, so a contract another catalog defines still counts.

#### Scenario: A contract another catalog defines still counts

- **WHEN** a `#Catalog`'s transformer requires a provider-fulfilled contract that the catalog's own `#resources` and `#traits` maps do not list
- **THEN** `provides` holds that contract's FQN

### Requirement: Optional demands and catalog-fulfilled contracts do not provide

Optional demands (`optionalResources`, `optionalTraits`), required labels and requirements whose `fulfilment` is `"catalog"` MUST NOT contribute to `provides`. A catalog with no transformers, or none requiring a provider-fulfilled contract, MUST derive `[]`.

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

### Requirement: The provides field is derived and never authored

The field is derived and never authored: an authored value that disagrees MUST fail validation on `provides` (CUE reports `incompatible list lengths` when the lengths differ and `conflicting values` on the differing element otherwise). A catalog that does not author `provides`, as every catalog published before this field does not, MUST validate unchanged.

#### Scenario: An authored value that disagrees is refused

- **WHEN** a `#Catalog` whose transformers require the provider-fulfilled `backup` trait also authors `provides: []`
- **THEN** validation fails on `provides` with an `incompatible list lengths` error

#### Scenario: A catalog that authors no provides validates unchanged

- **WHEN** a `#Catalog` does not author `provides`, as every catalog published before this field does not
- **THEN** the value MUST validate unchanged, with `provides` derived

### Requirement: A contract map binds each member's fqn to its key

Each of the three contract maps (`#Catalog.#resources`, `#traits` and `#blueprints`) MUST bind every member's `metadata.fqn` to the key the member is listed under. A member whose authored `metadata.fqn` differs from its key MUST fail validation with a `conflicting values` error on that member's `metadata.fqn` that names both the key and the authored fqn. The key MUST stay typed `#ContractFQNType`.

Source: owner decision, beta.1 kernel plan walkthrough (2026-10-03).

#### Scenario: A member listed under its own fqn is accepted

- **WHEN** a `#Catalog` declaring `modulePath: "opmodel.dev/catalogs/opm@v4"` and `version: "4.1.0"` lists a trait with `fqn: "opmodel.dev/catalogs/opm/traits/scaling@v1beta1"` under `#traits: (t.metadata.fqn): t`
- **THEN** the value validates, and `#traits["opmodel.dev/catalogs/opm/traits/scaling@v1beta1"].metadata.fqn` reads that key

#### Scenario: A member listed under another contract's key is refused

- **WHEN** the same catalog lists that trait under the key `"opmodel.dev/catalogs/opm/traits/autoscale@v1beta1"`
- **THEN** validation fails with `#traits."opmodel.dev/catalogs/opm/traits/autoscale@v1beta1".metadata.fqn: conflicting values "opmodel.dev/catalogs/opm/traits/autoscale@v1beta1" and "opmodel.dev/catalogs/opm/traits/scaling@v1beta1"`

#### Scenario: A mis-keyed resource or blueprint member is refused the same way

- **WHEN** a `#Catalog` lists a `#Resource` under `#resources`, or a `#Blueprint` under `#blueprints`, at a well-formed contract key that is not the member's `metadata.fqn`
- **THEN** validation fails with `conflicting values` on that member's `metadata.fqn`, naming the key and the fqn

### Requirement: The contract map binding derives no fqn

The binding of the contract maps MUST NOT derive `fqn` from the member's `name`, `modulePath` or `apiVersion`; the key and the fqn are both authored, and `#CatalogMemberFQNGate` still checks the fqn against the identity package at publish.

#### Scenario: The binding derives nothing from the member fields

- **WHEN** a member is listed under a contract key equal to its authored `metadata.fqn`
- **THEN** the binding derives nothing from the member's `name`, `modulePath` or `apiVersion`, and `#CatalogMemberFQNGate` still checks the fqn against the identity package at publish

### Requirement: The transformer map is not bound to the transformer fqn

`#Catalog.#transformers` MUST NOT be bound to its transformers' `metadata.fqn` by the binding of the contract maps.

Source: owner decision, beta.1 kernel plan walkthrough (2026-10-03), which binds the attachment maps and leaves the transformer map out.

#### Scenario: The transformer map is not bound

- **WHEN** a `#Catalog` lists a transformer under `#transformers` at its implementation key
- **THEN** validation behaves as before this change: the key's form is checked as `#ImplFQNType` and nothing binds it to the transformer's `metadata.fqn`

## REMOVED Requirements

### Requirement: A catalog derives the provider-fulfilled contracts it implements
**Reason**: Split into five requirements that each state one behavior.
**Migration**: See "A catalog derives the provider-fulfilled contracts its transformers require", "The provides field is sorted ascending and holds no duplicates", "Fulfilment is read from the transformer's own requirement", "Optional demands and catalog-fulfilled contracts do not provide" and "The provides field is derived and never authored".

### Requirement: A contract member's key equals its fqn
**Reason**: Split into three requirements that each state one behavior.
**Migration**: See "A contract map binds each member's fqn to its key", "The contract map binding derives no fqn" and "The transformer map is not bound to the transformer fqn".

