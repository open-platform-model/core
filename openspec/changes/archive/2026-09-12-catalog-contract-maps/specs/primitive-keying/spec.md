## MODIFIED Requirements

### Requirement: FQN map keys are typed by the role they hold

No map declared by `core` takes `#FQNType`. A map whose keys name contracts MUST be keyed `#ContractFQNType`: `#ComponentTransformer.requiredResources`, `optionalResources`, `requiredTraits` and `optionalTraits`, and `#Catalog.#resources`, `#traits` and `#blueprints`. A map whose keys name implementations MUST be keyed `#ImplFQNType`: `#TransformerMap` and `#Catalog.#transformers`.

A wrong-form key MUST be refused rather than merely failing to match, since an unmatched key surfaces as a transformer that renders nothing rather than as an error naming the key.

What `core` enforces is the key's **form**, not its agreement with anything. That a demand map's key equals its own value's `metadata.fqn` is an invariant of whichever runtime writes it, and that a catalog contract map's key equals its member's `metadata.fqn` is asserted at publish by `#CatalogMemberFQNGate`; `core` declares no constraint tying a key to its value.

#### Scenario: A build-shaped key is refused in a demand map

- **WHEN** a `#ComponentTransformer` declares `requiredResources` with the key `"opmodel.dev/catalogs/opm/resources/backup@1.2.0"`
- **THEN** validation fails with a field-not-allowed error, because no `#Resource` can carry a key in that form

#### Scenario: A contract-shaped key is refused in a transformer map

- **WHEN** a `#TransformerMap` is keyed `"opmodel.dev/catalogs/opm/transformers/backup-transformer@v1"`
- **THEN** validation fails with a field-not-allowed error

#### Scenario: A build-shaped key is refused in a catalog contract map

- **WHEN** a `#Catalog` lists a member under `#traits` with the key `"opmodel.dev/catalogs/opm/transformers/backup@4.1.0"`
- **THEN** validation fails with a field-not-allowed error naming that key
