## MODIFIED Requirements

### Requirement: `core` ships the catalog-member gate shape

`core` MUST export `#CatalogMemberFQNGate`. It takes an `identity!` (`#IdentityPackage`), a `kind!` (one of the four catalog member kinds), a `name!`, and the authored values `declaredFQN!`, `declaredModulePath!`, `declaredCatalogVersion!` and, for the three primitive kinds, `declaredAPIVersion`. It declares each `declared*` field twice, once as authored and once as implied by identity. Refusal MUST come from unification, not from a comparison outside CUE.

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
