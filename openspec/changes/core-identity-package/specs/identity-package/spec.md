## ADDED Requirements

### Requirement: `core` ships the conformant identity-package shape

`core` MUST export `#IdentityPackage`, the shape an artifact's committed `identity/identity.cue` must match. It MUST be reachable by both modules and catalogs, and MUST NOT require the artifact to depend on any catalog.

#### Scenario: A conformant identity package validates

- **WHEN** a value declaring `ModulePath: "opmodel.dev/catalogs/opm@v1"` and `Version: "1.2.0"` is unified with `#IdentityPackage`
- **THEN** the unification succeeds

### Requirement: Exactly two fields are authored; the rest derive

`#IdentityPackage` MUST require `ModulePath!` typed `#ModulePathType` and `Version!` typed `#VersionType`. `RegistryPath`, `Major`, `VersionMajor` and `kindPrefix` MUST be derived and MUST NOT be authored.

#### Scenario: The derived values follow from the two authored ones

- **WHEN** `#IdentityPackage` is unified with `ModulePath: "opmodel.dev/catalogs/opm@v1"` and `Version: "1.2.0"`
- **THEN** `RegistryPath` is `"opmodel.dev/catalogs/opm"`, `Major` is `"v1"`, and `VersionMajor` is `"v1"`

#### Scenario: A module path with no major is refused

- **WHEN** `ModulePath` is `"opmodel.dev/catalogs/opm"`
- **THEN** validation fails against `#ModulePathType`

#### Scenario: A missing authored field is reported by name

- **WHEN** a value declaring only `ModulePath` is unified with `#IdentityPackage`
- **THEN** evaluation reports `Version` as a required field that is not present

### Requirement: The declared version's major must equal the path's

`#IdentityPackage` MUST derive `VersionMajor` from `Version` and MUST assert it equal to `Major`. This is the only assertion of that relation in the system — neither `#Module.metadata` nor `#Catalog.metadata` asserts it.

#### Scenario: An agreeing pair validates

- **WHEN** `ModulePath` is `"opmodel.dev/modules/postgres@v2"` and `Version` is `"2.4.1"`
- **THEN** the unification succeeds and `VersionMajor` is `"v2"`

#### Scenario: A disagreeing pair is refused, naming the derived field

- **WHEN** `ModulePath` is `"opmodel.dev/modules/postgres@v2"` and `Version` is `"3.0.0"`
- **THEN** unification fails with conflicting values `"v2"` and `"v3"` on `VersionMajor`

### Requirement: The identity package carries no intra-module import

`#IdentityPackage` MUST be expressible using only CUE builtins, so that an artifact's `identity/identity.cue` can stay at the bottom of its module's import graph.

`core` MUST NOT require an identity file to import `core`. Validation is performed externally by a consumer unifying the loaded value against this definition.

#### Scenario: An identity file conforms without importing the schema

- **WHEN** an `identity/identity.cue` declares `ModulePath` and `Version` and imports nothing within its module
- **THEN** a consumer loading that package and unifying it against `#IdentityPackage` succeeds, and the file's import set is unchanged

### Requirement: One path prefix per catalog member kind

`#IdentityPackage` MUST expose `kindPrefix` enumerating exactly four keys — `resources`, `traits`, `blueprints`, `transformers` — each derived as `RegistryPath` plus one segment. It MUST be an enumerated struct rather than a pattern constraint, so each key is reachable by field selection.

The major MUST NOT be re-appended: a catalog member declares a package path.

#### Scenario: Each prefix is reachable by name

- **WHEN** `#IdentityPackage` is unified with `ModulePath: "opmodel.dev/catalogs/opm@v1"`
- **THEN** `kindPrefix.resources` is `"opmodel.dev/catalogs/opm/resources"` and `kindPrefix.blueprints` is `"opmodel.dev/catalogs/opm/blueprints"`, with no `@v1` in either

#### Scenario: No grouping segment is admitted

- **WHEN** a catalog places a blueprint at `"opmodel.dev/catalogs/opm/blueprints/workload"`
- **THEN** that path is not equal to `kindPrefix.blueprints`, and the member gate refuses it
