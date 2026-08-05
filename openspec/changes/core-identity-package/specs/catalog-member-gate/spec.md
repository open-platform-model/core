## ADDED Requirements

### Requirement: `core` ships the catalog-member gate shape

`core` MUST export `#CatalogMemberFQNGate`, which takes an `identity!` (`#IdentityPackage`), a `kind!` restricted to the four catalog member kinds, a `name!`, and the values a catalog actually authored — `declaredFQN!`, `declaredModulePath!`, `declaredCatalogVersion!` — and states what each must equal.

The gate MUST express the rule by declaring each `declared*` field twice: once as the authored value and once as what identity implies. Refusal MUST come from unification, not from a comparison performed outside CUE.

#### Scenario: A conformant resource passes

- **WHEN** the gate is unified with an identity at `"opmodel.dev/catalogs/opm@v1"` version `"1.2.0"`, `kind: "resources"`, `name: "backup"`, `declaredModulePath: "opmodel.dev/catalogs/opm/resources"`, `declaredCatalogVersion: "1.2.0"`, `declaredAPIVersion: "v1beta1"`, `declaredFQN: "opmodel.dev/catalogs/opm/resources/backup@v1beta1"`
- **THEN** the unification succeeds

### Requirement: A member's declared path must sit under its catalog's

`declaredModulePath` MUST equal `identity.kindPrefix[kind]`.

#### Scenario: A member one segment too deep is refused

- **WHEN** `kind: "blueprints"` and `declaredModulePath` is `"opmodel.dev/catalogs/opm/blueprints/workload"`
- **THEN** unification fails on `declaredModulePath`, and — because the FQN built from that prefix also disagrees — on `declaredFQN`

#### Scenario: A member declaring another catalog's path is refused

- **WHEN** the identity is `"opmodel.dev/catalogs/opm@v1"` and `declaredModulePath` is `"example.com/catalogs/other/resources"`
- **THEN** unification fails on `declaredModulePath`

### Requirement: A member's provenance must name its own build

`declaredCatalogVersion` MUST equal `identity.Version`.

#### Scenario: A stale provenance value is refused

- **WHEN** the identity's `Version` is `"1.2.0"` and `declaredCatalogVersion` is `"1.1.0"`
- **THEN** unification fails on `declaredCatalogVersion`

### Requirement: A contract key is built from the API version, an implementation key from the build

`declaredFQN` MUST equal `identity.kindPrefix[kind] + "/" + name + "@" + v`, where `v` is `identity.Version` for `kind: "transformers"` and `declaredAPIVersion` for the three primitive kinds.

`apiVersion` MUST NOT be checked against identity — nothing implies it.

#### Scenario: A primitive keys on its API version

- **WHEN** `kind: "traits"`, `name: "scaling"`, `declaredAPIVersion: "v1beta1"`, under an identity at `"opmodel.dev/catalogs/opm@v1"` version `"1.2.0"`
- **THEN** `declaredFQN` must be `"opmodel.dev/catalogs/opm/traits/scaling@v1beta1"`

#### Scenario: A transformer keys on its build

- **WHEN** `kind: "transformers"`, `name: "configmap-transformer"`, under the same identity
- **THEN** `declaredFQN` must be `"opmodel.dev/catalogs/opm/transformers/configmap-transformer@1.2.0"`

#### Scenario: A stale authored key is refused

- **WHEN** the identity's `Version` is `"1.2.0"` and a transformer declares `declaredFQN` ending `@1.1.0`
- **THEN** unification fails on `declaredFQN`

### Requirement: The API version is required for primitives and absent for transformers

`declaredAPIVersion` MUST be optional at the top level and required when `kind` is not `"transformers"`.

#### Scenario: A transformer omitting the API version passes

- **WHEN** `kind: "transformers"` and `declaredAPIVersion` is absent
- **THEN** the gate resolves `declaredFQN` from the build with no error about the absent field

#### Scenario: A primitive omitting the API version is refused

- **WHEN** `kind: "resources"` and `declaredAPIVersion` is absent
- **THEN** evaluation reports `declaredAPIVersion` as a required field that is not present

### Requirement: The gate covers all four catalog member kinds

The gate MUST accept `resources`, `traits`, `blueprints` and `transformers`, and MUST refuse any other kind.

#### Scenario: An unknown kind is refused

- **WHEN** `kind` is `"components"`
- **THEN** validation fails against the closed enum

### Requirement: The gate is not part of a member's own identity shape

`#CatalogMemberFQNGate` MUST NOT be embedded in `#Resource`, `#Trait`, `#Blueprint` or `#ComponentTransformer`. Expressing it there would re-derive `fqn` inside `core` and reinstate the derivation that was deliberately removed.

#### Scenario: A member's FQN is still authored

- **WHEN** a `#Resource` is evaluated on its own, without the gate
- **THEN** its `metadata.fqn` is whatever the catalog authored, with no derivation applied
