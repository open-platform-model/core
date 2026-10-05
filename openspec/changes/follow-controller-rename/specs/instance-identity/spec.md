## MODIFIED Requirements

### Requirement: Instance identity survives every upgrade of the module it deploys

For one `{module registry path, name, namespace}` triple, `#ModuleInstance.metadata.uuid` MUST NOT change when the module's `version` changes, and MUST NOT change when the module path's **major** changes.

This is the requirement the ownership label depends on: the controller skips deleting any live object whose owner label disagrees with the instance UUID it recorded, so an instance UUID that moves on upgrade orphans whatever the new render stopped emitting, while reporting success.

#### Scenario: A patch release does not move the instance UUID

- **WHEN** the referenced module's `version` changes from `"2.4.1"` to `"2.9.9"` with `name` and `namespace` unchanged
- **THEN** `metadata.fqn` and `metadata.uuid` are unchanged

#### Scenario: A major bump does not move the instance UUID

- **WHEN** the referenced module's path changes from `"opmodel.dev/modules/postgres@v2"` to `"opmodel.dev/modules/postgres@v3"` with `name` and `namespace` unchanged
- **THEN** `metadata.fqn` and `metadata.uuid` are unchanged, while the module's own `metadata.uuid` changes

