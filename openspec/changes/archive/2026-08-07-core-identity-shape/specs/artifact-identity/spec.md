## ADDED Requirements

### Requirement: An artifact declares its complete CUE module path

`#Module.metadata.modulePath` and `#Catalog.metadata.modulePath` MUST be typed `#ModulePathType`, which MUST require a terminal `@vN` major suffix. The value MUST be the same string that `cue.mod/module.cue`'s `module:` field, the registry coordinate, and an `import` statement carry.

`#ModulePathType` MUST admit underscores in path segments, because a module path's leaf is the module's own snake_case name. It MUST admit hyphens in non-leaf segments, so that an organisation such as `github.com/open-platform-model` remains expressible.

#### Scenario: A module path with a major suffix is accepted

- **WHEN** `#Module.metadata.modulePath` is `"opmodel.dev/modules/postgres@v2"`
- **THEN** the value validates

#### Scenario: A module path without a major suffix is refused

- **WHEN** `#Module.metadata.modulePath` is `"opmodel.dev/modules/postgres"`
- **THEN** validation fails against `#ModulePathType`

#### Scenario: Underscores are legal in a module path leaf

- **WHEN** `#Module.metadata.modulePath` is `"opmodel.dev/modules/cert_manager@v1"`
- **THEN** the value validates

#### Scenario: Hyphens remain legal in non-leaf segments

- **WHEN** `#Catalog.metadata.modulePath` is `"github.com/open-platform-model/catalogs/opm@v1"`
- **THEN** the value validates

### Requirement: A primitive declares a package path, not a module path

`#Resource`, `#Trait`, `#Blueprint` and `#ComponentTransformer` MUST type `metadata.modulePath` as `#PackagePathType`, which MUST NOT accept a `@vN` suffix. `#PackagePathType` MUST accept exactly the values `#ModulePathType` accepted before this change, so no primitive value shipped by any catalog changes.

#### Scenario: A primitive path without a suffix is accepted

- **WHEN** `#Resource.metadata.modulePath` is `"opmodel.dev/catalogs/opm/resources"`
- **THEN** the value validates

#### Scenario: A primitive path carrying a major is refused

- **WHEN** `#Resource.metadata.modulePath` is `"opmodel.dev/catalogs/opm/resources@v1"`
- **THEN** validation fails against `#PackagePathType`

### Requirement: A module path decomposes in exactly one place

`core` MUST provide `#ArtifactRef`, which takes a `modulePath!: #ModulePathType` and exposes `registryPath` (the path with the major stripped), `major` (typed `#MajorVersionType`), and `importPath` (the module path verbatim). No other construct MUST split a module path.

#### Scenario: A module path splits into repository and major

- **WHEN** `#ArtifactRef` is unified with `modulePath: "opmodel.dev/modules/postgres@v2"`
- **THEN** `registryPath` is `"opmodel.dev/modules/postgres"`, `major` is `"v2"`, and `importPath` is `"opmodel.dev/modules/postgres@v2"`

#### Scenario: A malformed major is refused by the major type

- **WHEN** `#ArtifactRef` is unified with a `modulePath` whose suffix is not `v` followed by digits
- **THEN** validation fails, against `#ModulePathType` or `#MajorVersionType`

### Requirement: An artifact's FQN is its module path

`#Module.metadata.fqn` and `#Catalog.metadata.fqn` MUST equal `modulePath` and MUST be typed `#ModulePathType`. Neither MUST interpolate `name` or `version`. `#ModuleFQNType` and `#CatalogFQNType` MUST be removed.

#### Scenario: A module's FQN is its path verbatim

- **WHEN** a `#Module` declares `modulePath: "opmodel.dev/modules/postgres@v2"`, `name: "postgres"` and `version: "2.4.1"`
- **THEN** `metadata.fqn` is `"opmodel.dev/modules/postgres@v2"`, containing neither the name segment nor the version

### Requirement: Module artifact identity distinguishes majors and nothing finer

`#Module.metadata.uuid` MUST remain `SHA1(OPMNamespace, fqn)`. Because `fqn` is the module path, `uuid` MUST be unchanged when only `version` changes, and MUST change when the path's major changes.

#### Scenario: A release does not move the module UUID

- **WHEN** two `#Module` values differ only in `version` — `"2.4.1"` and `"2.9.9"` — under one `modulePath`
- **THEN** their `metadata.fqn` values are equal and their `metadata.uuid` values are equal

#### Scenario: A major bump moves the module UUID

- **WHEN** two `#Module` values differ only in their path's major — `@v2` and `@v3`
- **THEN** their `metadata.uuid` values differ

### Requirement: A module's name has one spelling, and the path's leaf equals it

`#Module.metadata.name` MUST be typed `#SnakeNameType`. The module path's `registryPath` MUST end in `/` followed by `name`, enforced by a hidden constraint on `#Module.metadata`. `nameSnakeCase` and `#KebabToSnake` MUST be removed.

`#Resource`, `#Trait` and `#Blueprint` MUST keep kebab-case `#NameType` names; `#KebabToPascal` and `#KebabToCamel` MUST be retained for the `spec!` keys built from them.

#### Scenario: A snake_case name matching the path leaf is accepted

- **WHEN** a `#Module` declares `name: "cert_manager"` and `modulePath: "opmodel.dev/modules/cert_manager@v1"`
- **THEN** the value validates

#### Scenario: A name disagreeing with the path leaf is refused

- **WHEN** a `#Module` declares `name: "postgres"` and `modulePath: "opmodel.dev/modules/mysql@v1"`
- **THEN** validation fails on the leaf constraint

#### Scenario: A kebab-case module name is refused

- **WHEN** a `#Module` declares `name: "cert-manager"`
- **THEN** validation fails against `#SnakeNameType`

#### Scenario: The snake_case projection is gone

- **WHEN** a `#Module` value is evaluated
- **THEN** `metadata.nameSnakeCase` does not exist, and `#KebabToSnake` is not a member of the `core` package

### Requirement: A module declares a version that reaches no key

`#Module.metadata.version!` MUST be retained, typed `#VersionType`. It MUST NOT be an input to `fqn` or to `uuid`. It MUST remain the source of the `module.opmodel.dev/version` label.

#### Scenario: The declared version is present and keyless

- **WHEN** a `#Module` declares `version: "2.4.1"`
- **THEN** `metadata.labels["module.opmodel.dev/version"]` is `"2.4.1"`, and neither `metadata.fqn` nor `metadata.uuid` contains or depends on it

### Requirement: `core` asserts no agreement between a declared version's major and its path's

Neither `#Module.metadata` nor `#Catalog.metadata` MUST assert that `version`'s major equals `modulePath`'s major. That relation is asserted in the artifact's `identity/identity.cue` alone, where both values are written.

This requirement pins an **accepting** behaviour deliberately: an earlier revision of the design asserted the relation in `core`, and the assertion was removed by decision. It is specified so that restoring it reads as a change rather than as a fix.

#### Scenario: A version whose major disagrees with the path is accepted by `core`

- **WHEN** a `#Module` declares `modulePath: "opmodel.dev/modules/postgres@v2"` and `version: "3.0.0"`
- **THEN** the value validates, and no `versionMajor` field exists on `metadata`

#### Scenario: The same skew is accepted for a catalog

- **WHEN** a `#Catalog` declares `modulePath: "opmodel.dev/catalogs/opm@v1"` and `version: "2.0.0"`
- **THEN** the value validates

### Requirement: A catalog declares a concrete version with no development default

`#Catalog.metadata.version!` MUST be typed `#VersionType` with no default. The `*"0.0.0-dev"` default MUST be removed, so that a catalog with no declared version is an incomplete value naming the field rather than a value that renders successfully while being wrong.

#### Scenario: An unfilled catalog version is incomplete

- **WHEN** a `#Catalog` is evaluated with `metadata.version` unset
- **THEN** evaluation reports an incomplete value at `metadata.version` rather than defaulting to `"0.0.0-dev"`

### Requirement: A catalog stamps a package path onto its transformers

`#Catalog`'s `#transformers` pattern constraint MUST stamp `metadata.modulePath` as `"\(registryPath)/transformers"`, using the major-free path. It MUST NOT re-append the major, because a primitive declares a package path.

#### Scenario: The stamped transformer path carries no major

- **WHEN** a `#Catalog` declares `modulePath: "opmodel.dev/catalogs/opm@v1"` and holds an entry in `#transformers`
- **THEN** that entry's `metadata.modulePath` is `"opmodel.dev/catalogs/opm/transformers"`
