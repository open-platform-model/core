## MODIFIED Requirements

### Requirement: An artifact declares its complete CUE module path

`#Module.metadata.modulePath` and `#Catalog.metadata.modulePath` MUST be typed `#ModulePathType`, which MUST require a terminal `@vN` major suffix. The value MUST be the string that `cue.mod/module.cue`'s `module:` field, the registry coordinate and an `import` statement carry.

`#ModulePathType` MUST admit underscores in path segments (a leaf is the module's own snake_case name) and hyphens in non-leaf segments (so `github.com/open-platform-model` stays expressible).

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

