## MODIFIED Requirements

### Requirement: An instance FQN cannot be built from a module path

The field that `#ModuleInstance.metadata.fqn` derives from MUST be the major-free registry path. Substituting a full module path MUST be refused structurally rather than silently producing a third identity.

`#Module.metadata.registryPath` is derived from `#ArtifactRef` rather than authored, so the refusal is a conflict against the already-computed value. The `#PackagePathType` backstop is also structural; only the reported error differs.

#### Scenario: A module path in the registry-path position is refused

- **WHEN** the value supplied as the module's `registryPath` is `"opmodel.dev/modules/postgres@v2"`
- **THEN** validation fails with a conflict between `"opmodel.dev/modules/postgres"` and `"opmodel.dev/modules/postgres@v2"`, rather than yielding an `fqn` of `"opmodel.dev/modules/postgres@v2:postgres-prod:prod"`

#### Scenario: The package path backstop cannot fire on its own

- **WHEN** a `modulePath` satisfies `#ModulePathType`
- **THEN** `strings.SplitN(modulePath, "@", 2)[0]` carries no `@` by construction, so the `#PackagePathType` backstop of `#Module.metadata.registryPath` cannot fire on its own

