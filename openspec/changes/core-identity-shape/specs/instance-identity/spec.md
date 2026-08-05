## ADDED Requirements

### Requirement: A module exposes its major-free registry path

`#Module.metadata` MUST expose `registryPath`, sourced from `#ArtifactRef`'s decomposition of `modulePath`. It MUST be the module path with the major suffix stripped, and it MUST be typed so that a value still carrying a major is refused.

#### Scenario: The registry path drops the major

- **WHEN** a `#Module` declares `modulePath: "opmodel.dev/modules/postgres@v2"`
- **THEN** `metadata.registryPath` is `"opmodel.dev/modules/postgres"`

#### Scenario: The registry path is stable across a major bump

- **WHEN** two `#Module` values differ only in their path's major — `@v2` and `@v3`
- **THEN** their `metadata.registryPath` values are equal

### Requirement: An instance declares its own FQN

`#ModuleInstance.metadata` MUST declare `fqn` as `"\(#moduleMetadata.registryPath):\(name):\(namespace)"`. It MUST derive from the module's `registryPath` and MUST NOT derive from the module's `fqn`, `uuid`, `version`, or major.

#### Scenario: The instance FQN composes the registry path, name and namespace

- **WHEN** a `#ModuleInstance` named `postgres-prod` in namespace `prod` references a module whose `registryPath` is `"opmodel.dev/modules/postgres"`
- **THEN** `metadata.fqn` is `"opmodel.dev/modules/postgres:postgres-prod:prod"`

### Requirement: Instance identity derives from the instance FQN

`#ModuleInstance.metadata.uuid` MUST be `SHA1(OPMNamespace, fqn)` over the instance's own `fqn`. It MUST NOT interpolate `#moduleMetadata.uuid`.

#### Scenario: The instance UUID hashes the instance FQN

- **WHEN** a `#ModuleInstance` is evaluated
- **THEN** `metadata.uuid` equals `SHA1(OPMNamespace, metadata.fqn)`, and `metadata.labels["module-instance.opmodel.dev/uuid"]` carries that value

### Requirement: Instance identity survives every upgrade of the module it deploys

For one `{module registry path, name, namespace}` triple, `#ModuleInstance.metadata.uuid` MUST NOT change when the module's `version` changes, and MUST NOT change when the module path's **major** changes.

This is the requirement the ownership label depends on: the operator skips deleting any live object whose owner label disagrees with the instance UUID it recorded, so an instance UUID that moves on upgrade orphans whatever the new render stopped emitting, while reporting success.

#### Scenario: A patch release does not move the instance UUID

- **WHEN** the referenced module's `version` changes from `"2.4.1"` to `"2.9.9"` with `name` and `namespace` unchanged
- **THEN** `metadata.fqn` and `metadata.uuid` are unchanged

#### Scenario: A major bump does not move the instance UUID

- **WHEN** the referenced module's path changes from `"opmodel.dev/modules/postgres@v2"` to `"opmodel.dev/modules/postgres@v3"` with `name` and `namespace` unchanged
- **THEN** `metadata.fqn` and `metadata.uuid` are unchanged, while the module's own `metadata.uuid` changes

### Requirement: Instance identity still separates modules and namespaces

`#ModuleInstance.metadata.uuid` MUST differ for two modules whose registry paths differ, and MUST differ for one module deployed into two namespaces or under two instance names.

Without this, the survival requirement above is satisfiable by an identity that has stopped distinguishing anything.

#### Scenario: Two modules sharing a leaf name stay distinct

- **WHEN** two instances share `name` and `namespace` but reference modules at `"opmodel.dev/modules/postgres"` and `"example.com/postgres"`
- **THEN** their `metadata.uuid` values differ

#### Scenario: One module in two namespaces stays distinct

- **WHEN** two instances share `name` and reference the same module but declare namespaces `prod` and `staging`
- **THEN** their `metadata.uuid` values differ

#### Scenario: Two instance names in one namespace stay distinct

- **WHEN** two instances share `namespace` and reference the same module but declare names `postgres-prod` and `postgres-replica`
- **THEN** their `metadata.uuid` values differ

### Requirement: An instance FQN cannot be built from a module path

The field that `#ModuleInstance.metadata.fqn` derives from MUST be the major-free registry path. Substituting a full module path MUST be refused structurally rather than silently producing a third identity.

`#Module.metadata.registryPath` is derived from `#ArtifactRef` rather than authored, so the refusal is a conflict against the already-computed value. Its `#PackagePathType` is a backstop that cannot fire on its own: `strings.SplitN(modulePath, "@", 2)[0]` carries no `@` by construction under `#ModulePathType`. Both refusals are structural; only the reported error differs.

#### Scenario: A module path in the registry-path position is refused

- **WHEN** the value supplied as the module's `registryPath` is `"opmodel.dev/modules/postgres@v2"`
- **THEN** validation fails with a conflict between `"opmodel.dev/modules/postgres"` and `"opmodel.dev/modules/postgres@v2"`, rather than yielding an `fqn` of `"opmodel.dev/modules/postgres@v2:postgres-prod:prod"`
