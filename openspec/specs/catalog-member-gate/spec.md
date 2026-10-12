## Purpose

Defines what a catalog member — `#Resource`, `#Trait`, `#Blueprint` or `#ComponentTransformer` — must declare relative to its catalog's identity, expressed so that refusal comes from unification and the author reads CUE's own diagnostic rather than a comparison performed outside CUE. Covers the path a member may declare, the provenance it must name, how its key is built from a contract level for the three primitive kinds and from the build for an adapter, the conditional requirement on an API version that a transformer does not carry, and why the rule is stated here rather than embedded in the member definitions — where expressing it would reinstate the FQN derivation that was deliberately removed.

## Requirements

### Requirement: `core` ships the catalog-member gate shape

`core` MUST export `#CatalogMemberFQNGate`. It takes an `identity!`, a `kind!` (one of the four catalog member kinds), a `name!`, and the authored values `declaredFQN!`, `declaredModulePath!`, `declaredCatalogVersion!` and, for the three primitive kinds, `declaredAPIVersion`. It declares the first three twice, once as authored and once as implied by identity; nothing implies `declaredAPIVersion`. Refusal MUST come from unification, not from a comparison outside CUE.

#### Scenario: A conformant resource passes

- **WHEN** the gate is unified with an identity at `"opmodel.dev/catalogs/opm@v1"` version `"1.2.0"`, `kind: "resources"`, `name: "backup"`, `declaredModulePath: "opmodel.dev/catalogs/opm/resources/v1beta1"`, `declaredCatalogVersion: "1.2.0"`, `declaredAPIVersion: "v1beta1"`, `declaredFQN: "opmodel.dev/catalogs/opm/resources/backup@v1beta1"`
- **THEN** the unification succeeds

### Requirement: A member's declared path must sit under its catalog's

`declaredModulePath` MUST equal the kind prefix, `identity.kindPrefix[kind]`, for a transformer. For a resource, a trait or a blueprint it MUST equal that prefix, then `/`, then the member's own `declaredAPIVersion`. No other segment is admitted, and the check is an equality, not a prefix test. Enhancement 0010 chose this filing rule so that two API versions of one contract can coexist in disjoint packages; a transformer has no API version to file under.

#### Scenario: A member one segment too deep is refused

- **WHEN** `kind: "blueprints"`, `declaredAPIVersion: "v1beta1"`, `declaredModulePath` is `"opmodel.dev/catalogs/opm/blueprints/workload"` and `declaredFQN` is `"opmodel.dev/catalogs/opm/blueprints/workload/stateless-workload@v1beta1"`
- **THEN** unification fails on `declaredModulePath`, and on `declaredFQN` too, because the FQN is built from the kind prefix and the name, without the extra segment

#### Scenario: A member declaring another catalog's path is refused

- **WHEN** the identity is `"opmodel.dev/catalogs/opm@v1"`, `kind: "resources"`, `declaredAPIVersion: "v1beta1"` and `declaredModulePath` is `"example.com/catalogs/other/resources"`
- **THEN** unification fails on `declaredModulePath`

#### Scenario: A contract member filing flat is refused

- **WHEN** `kind: "resources"`, `declaredAPIVersion: "v1beta1"` and `declaredModulePath` is `"opmodel.dev/catalogs/opm/resources"`, the kind prefix alone
- **THEN** unification fails on `declaredModulePath`, which must be `"opmodel.dev/catalogs/opm/resources/v1beta1"`

#### Scenario: A contract member files under its own API version

- **WHEN** two resources of one catalog declare `declaredAPIVersion` `"v1beta1"` and `"v1"`
- **THEN** their `declaredModulePath` values are `"opmodel.dev/catalogs/opm/resources/v1beta1"` and `"opmodel.dev/catalogs/opm/resources/v1"`, and neither `declaredFQN` contains the version as a path segment

#### Scenario: A transformer files at the kind prefix

- **WHEN** `kind: "transformers"` and `declaredModulePath` is `"opmodel.dev/catalogs/opm/transformers"`
- **THEN** the unification succeeds, and a `declaredModulePath` of `"opmodel.dev/catalogs/opm/transformers/v1"` fails on `declaredModulePath`

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
