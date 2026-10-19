## MODIFIED Requirements

### Requirement: FQN map keys are typed by the role they hold

No map declared by `core` takes `#FQNType`. A map whose keys name contracts MUST be keyed `#ContractFQNType`: `#ComponentTransformer.requiredResources`, `optionalResources`, `requiredTraits` and `optionalTraits`, and `#Catalog.#resources`, `#traits` and `#blueprints`. A map whose keys name implementations MUST be keyed `#ImplFQNType`: `#TransformerMap` and `#Catalog.#transformers`. A wrong-form key MUST be refused rather than merely failing to match.

#### Scenario: A build-shaped key is refused in a demand map

- **WHEN** a `#ComponentTransformer` declares `requiredResources` with the key `"opmodel.dev/catalogs/opm/resources/backup@1.2.0"`
- **THEN** validation fails with a field-not-allowed error, because no `#Resource` can carry a key in that form

#### Scenario: A contract-shaped key is refused in a transformer map

- **WHEN** a `#TransformerMap` is keyed `"opmodel.dev/catalogs/opm/transformers/backup-transformer@v1"`
- **THEN** validation fails with a field-not-allowed error

#### Scenario: A build-shaped key is refused in a catalog contract map

- **WHEN** a `#Catalog` lists a member under `#traits` with the key `"opmodel.dev/catalogs/opm/transformers/backup@4.1.0"`
- **THEN** validation fails with a field-not-allowed error naming that key

#### Scenario: A wrong-form key is an error, not a silent non-match

- **WHEN** a map key has the wrong form for its role
- **THEN** it MUST be refused, since an unmatched key surfaces as a transformer that renders nothing rather than as an error naming the key

### Requirement: An attachment map key equals its member's fqn

`#ResourceMap`, `#TraitMap` and `#BlueprintMap`, and therefore `#Component.#resources`, `#traits` and `#blueprints`, MUST bind every entry's `metadata.fqn` to the key the entry sits under. An entry whose `metadata.fqn` differs from its key MUST fail `cue vet` with a `conflicting values` error at `<map>.<key>.metadata.fqn` that names both the key and the fqn. An entry keyed by its own fqn MUST validate as before.

Source: owner decision, beta.1 kernel plan walkthrough (2026-10-03).

#### Scenario: A resource keyed by its fqn is accepted

- **WHEN** a `#Component` declares `#resources: (c.metadata.fqn): c` for a resource with `fqn: "opmodel.dev/catalogs/opm/resources/container@v1beta1"`
- **THEN** the value validates, and `#resources["opmodel.dev/catalogs/opm/resources/container@v1beta1"]` reads that resource

#### Scenario: A short resource key is refused

- **WHEN** a `#Component` declares `#resources: container: c` for the same resource
- **THEN** `cue vet` fails with `#resources.container.metadata.fqn: conflicting values "container" and "opmodel.dev/catalogs/opm/resources/container@v1beta1"`

#### Scenario: A trait under another trait's key is refused

- **WHEN** a `#Component` attaches a trait with `fqn: "opmodel.dev/catalogs/opm/traits/expose@v1beta1"` under the key `"opmodel.dev/catalogs/opm/traits/scaling@v1beta1"`
- **THEN** `cue vet` fails with `conflicting values` on `#traits."opmodel.dev/catalogs/opm/traits/scaling@v1beta1".metadata.fqn`, naming both FQNs

#### Scenario: A blueprint under another blueprint's key is refused

- **WHEN** a `#Component` attaches a blueprint with `fqn: "opmodel.dev/catalogs/opm/blueprints/stateful-workload@v1beta1"` under the key `"opmodel.dev/catalogs/opm/blueprints/stateless-workload@v1beta1"`
- **THEN** `cue vet` fails with `conflicting values` on that entry's `metadata.fqn`, naming both FQNs

#### Scenario: Entries contributed by an embedded blueprint fragment are accepted

- **WHEN** a `#Component` embeds a catalog fragment that writes its blueprint, resources and traits as `(X.metadata.fqn): X`
- **THEN** the component validates, and every attachment is readable by its fqn key

## ADDED Requirements

### Requirement: An attachment map binding derives no fqn

`#ResourceMap`, `#TraitMap` and `#BlueprintMap`, and therefore `#Component.#resources`, `#traits` and `#blueprints`, MUST bind every entry's `metadata.fqn` to the key the entry sits under. The binding MUST NOT derive `fqn` from the member's `name`, `modulePath` or `apiVersion`.

Source: owner decision, beta.1 kernel plan walkthrough (2026-10-03).

#### Scenario: The attachment map binding derives no fqn

- **WHEN** an entry of `#ResourceMap`, `#TraitMap` or `#BlueprintMap` is bound to the key it sits under
- **THEN** the binding does not derive `fqn` from the member's `name`, `modulePath` or `apiVersion`

### Requirement: A catalog member's FQN is authored by the catalog

`core` MUST NOT derive `metadata.fqn` for any of the four kinds. The field MUST be declared with its type and left for the catalog to author from its identity package. The definitions compute nothing from `name`, `modulePath` or `apiVersion`. Outside the six attachment maps, the agreement between an authored value and the member's own `modulePath`, `name` and `apiVersion` is **not** checked by `core`. It is checked by `#CatalogMemberFQNGate` at publish, which ships separately.

#### Scenario: An authored FQN is accepted as written

- **WHEN** a `#Resource` declares `fqn: "opmodel.dev/catalogs/opm/resources/backup@v1beta1"` and `name: "backup"`
- **THEN** the value validates, with no derivation from `modulePath`, `name` or `apiVersion`

#### Scenario: An FQN disagreeing with the primitive's own fields is not refused by `core`

- **WHEN** a `#Resource` declares `name: "backup"` and `fqn: "opmodel.dev/catalogs/opm/resources/restore@v1beta1"`
- **THEN** the value validates against `core`, because the agreement is a publish-time gate rather than a schema constraint

### Requirement: An unset FQN in an attachment map takes its key

Inside the six attachment maps (`#Component.#resources`, `#traits` and `#blueprints`, and `#Catalog.#resources`, `#traits` and `#blueprints`) the map key MUST bind `metadata.fqn`: an authored value that disagrees with its key MUST be refused with `conflicting values`, and a member that leaves `fqn` unset there MUST take the key as its `fqn`. The binding derives nothing from the member's own fields; the key and the fqn are both authored.

#### Scenario: An unset FQN takes its attachment key

- **WHEN** a `#Resource`, `#Trait` or `#Blueprint` that leaves `metadata.fqn` unset is placed in one of the six attachment maps under a contract key
- **THEN** the value validates, and the entry's `metadata.fqn` reads that key

#### Scenario: A disagreeing authored FQN in an attachment map is refused

- **WHEN** a member of one of the six attachment maps authors a `metadata.fqn` that disagrees with its key
- **THEN** validation MUST fail with `conflicting values`

### Requirement: `#Trait.appliesTo` is not checked against the component's resources

`#Trait.appliesTo` MUST stay unchecked against the component's resources; core#99 tracks whether to enforce or drop it.

#### Scenario: appliesTo is not checked against the attached resources

- **WHEN** a `#Component` attaches a trait whose `appliesTo` names a resource the component does not attach
- **THEN** `core` leaves `#Trait.appliesTo` unchecked against the component's resources

### Requirement: The six attachment maps bind a key to its member's fqn

Beyond the key's form, `core` MUST bind the key to its member's `metadata.fqn` in exactly the six attachment maps: `#Component.#resources`, `#traits` and `#blueprints` (through `#ResourceMap`, `#TraitMap` and `#BlueprintMap`; requirement "An attachment map key equals its member's fqn") and `#Catalog.#resources`, `#traits` and `#blueprints` (capability `catalog-contracts`, "A contract map binds each member's fqn to its key").

#### Scenario: A component attachment map refuses a key that is not the member fqn

- **WHEN** a member sits in `#Component.#traits` under a key that is not its `metadata.fqn`
- **THEN** `core` MUST refuse it, as "An attachment map key equals its member's fqn" says

### Requirement: Demand maps and implementation maps enforce the key form only

In the demand maps and the two implementation maps, `core` MUST enforce the key form only. That a demand map's key equals its value's `metadata.fqn` is an invariant of whichever runtime writes it.

#### Scenario: A demand map key is checked for form only

- **WHEN** a demand map key has the contract form but differs from its value's `metadata.fqn`
- **THEN** `core` enforces the form only; the equality is an invariant of whichever runtime writes the map

### Requirement: A transformer map key is checked for form only

A transformer map key MUST be checked for form only: neither `core` nor the publish gate compares it to the transformer's `metadata.fqn`, because `#CatalogMemberFQNGate` is filled from the member definitions and never reads a `#Catalog` map key. Binding `#Catalog.#transformers` is a possible later tightening.

#### Scenario: A transformer map key is not compared with the transformer fqn

- **WHEN** a `#TransformerMap` key has the implementation form
- **THEN** neither `core` nor the publish gate compares it to the transformer's `metadata.fqn`

## REMOVED Requirements

### Requirement: A catalog member's FQN is authored, not derived
**Reason**: Split into two requirements that each state one behavior.
**Migration**: See "A catalog member's FQN is authored by the catalog" and "An unset FQN in an attachment map takes its key".

