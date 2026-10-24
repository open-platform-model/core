## ADDED Requirements

### Requirement: A contract member's key equals its fqn

Each of the three contract maps (`#Catalog.#resources`, `#traits` and `#blueprints`) MUST bind every member's `metadata.fqn` to the key the member is listed under. A member whose authored `metadata.fqn` differs from its key MUST fail validation with a `conflicting values` error on that member's `metadata.fqn` that names both the key and the authored fqn. The key MUST stay typed `#ContractFQNType`. The binding MUST NOT derive `fqn` from the member's `name`, `modulePath` or `apiVersion`; the key and the fqn are both authored, and `#CatalogMemberFQNGate` still checks the fqn against the identity package at publish. `#Catalog.#transformers` MUST NOT be bound by this requirement.

Source: owner decision, beta.1 kernel plan walkthrough (2026-10-03), which binds the attachment maps and leaves the transformer map out.

#### Scenario: A member listed under its own fqn is accepted

- **WHEN** a `#Catalog` declaring `modulePath: "opmodel.dev/catalogs/opm@v4"` and `version: "4.1.0"` lists a trait with `fqn: "opmodel.dev/catalogs/opm/traits/scaling@v1beta1"` under `#traits: (t.metadata.fqn): t`
- **THEN** the value validates, and `#traits["opmodel.dev/catalogs/opm/traits/scaling@v1beta1"].metadata.fqn` reads that key

#### Scenario: A member listed under another contract's key is refused

- **WHEN** the same catalog lists that trait under the key `"opmodel.dev/catalogs/opm/traits/autoscale@v1beta1"`
- **THEN** validation fails with `#traits."opmodel.dev/catalogs/opm/traits/autoscale@v1beta1".metadata.fqn: conflicting values "opmodel.dev/catalogs/opm/traits/autoscale@v1beta1" and "opmodel.dev/catalogs/opm/traits/scaling@v1beta1"`

#### Scenario: A mis-keyed resource or blueprint member is refused the same way

- **WHEN** a `#Catalog` lists a `#Resource` under `#resources`, or a `#Blueprint` under `#blueprints`, at a well-formed contract key that is not the member's `metadata.fqn`
- **THEN** validation fails with `conflicting values` on that member's `metadata.fqn`, naming the key and the fqn

#### Scenario: The transformer map is not bound

- **WHEN** a `#Catalog` lists a transformer under `#transformers` at its implementation key
- **THEN** validation behaves as before this change: the key's form is checked as `#ImplFQNType` and nothing binds it to the transformer's `metadata.fqn`

## REMOVED Requirements

### Requirement: The contract stamp does not cover fqn

**Reason**: The owner decision of 2026-10-03 (beta.1 kernel plan walkthrough) binds the contract-map key to the member's `metadata.fqn` as a hard vet error. The requirement and its scenario "Key and fqn are not compared by core" assert the opposite.

**Migration**: Replaced by "A contract member's key equals its fqn". A catalog that keys each member as `(X.metadata.fqn): X`, as every published catalog does, validates unchanged. A catalog with a key that differs from its member's fqn must re-key that entry.
