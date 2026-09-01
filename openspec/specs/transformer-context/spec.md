## Purpose

The projection contract for `#transform.#context`: the transformer context's metadata blocks are computed from the other two `#transform` inputs rather than assembled by the runtime, whose obligation narrows to the one runtime-owned field, `#runtimeName`.

## Requirements

### Requirement: The context's metadata blocks are projections of the other two inputs

At the `#transform` site, `#context.#moduleInstanceMetadata` MUST be computed from `#moduleInstance` (`name`, `namespace`, `fqn`, `uuid` from the instance's metadata; `version` from the instance's module metadata) and `#context.#componentMetadata` MUST be computed from `#component` (`name` from the component's metadata). A runtime MUST NOT be required to supply either block. Field names and value shapes are unchanged from the pre-projection context, so a transformer reading any context field observes the same value as before.

#### Scenario: The context computes from filled inputs

- **WHEN** a `#transform` has `#moduleInstance` and `#component` filled concretely and `#runtimeName` supplied
- **THEN** every `#context` metadata field evaluates concretely from those inputs with nothing else supplied, and the label and annotation folds resolve from the projected blocks

#### Scenario: Transformer-visible values are unchanged

- **WHEN** a transformer reads `#context.#moduleInstanceMetadata.namespace` or `#context.controllerLabels` on a render whose inputs match a pre-projection render
- **THEN** the values are identical to what the runtime-assembled context carried

### Requirement: Absent optional sources project as absent

An optional source field that is absent on the input MUST project as absent on the context, not as an error and not as an empty struct. `labels` and `annotations` on both metadata blocks are the covered cases.

#### Scenario: An instance without labels projects no labels

- **WHEN** `#moduleInstance.metadata` carries no `annotations` field
- **THEN** `#context.#moduleInstanceMetadata.annotations` is absent, the annotation fold contributes nothing for it, and evaluation reports no error

### Requirement: The runtime's only obligation is the runtime name

`#context.#runtimeName` MUST remain required and runtime-supplied; it is the only context field a runtime is obligated to fill. It remains stamped verbatim onto every rendered object as `app.kubernetes.io/managed-by`.

#### Scenario: A render without a runtime name refuses

- **WHEN** a `#transform` has both inputs filled and no `#runtimeName` supplied
- **THEN** concrete evaluation of the context fails on the missing required field

### Requirement: A staged runtime may fill identical values, and only identical values

During the staged migration a runtime MAY continue to fill the projected context fields, provided every value it fills is identical to what the projection computes; unification then agrees and behavior is unchanged. A runtime filling a value DIVERGENT from the projection MUST get a unification conflict at that field rather than silently winning. A runtime MUST stop filling the projected fields once the differential parity harness reports agreement on every case.

#### Scenario: An identical fill agrees

- **WHEN** a runtime fills `#context.#moduleInstanceMetadata.name` with the same value the projection computes from `#moduleInstance`
- **THEN** evaluation succeeds with that value, exactly as if the runtime had filled nothing

#### Scenario: A divergent fill conflicts

- **WHEN** a runtime fills `#context.#moduleInstanceMetadata.name` with a value different from `#moduleInstance.metadata.name`
- **THEN** evaluation fails with a conflict at that field

### Requirement: A standalone context value remains constructible

`#TransformerContext` itself MUST remain a definition a caller can instantiate directly by supplying the two metadata blocks and `#runtimeName`; the projection lives at the `#transform` site, not on the definition. Existing standalone uses (tests, pins, tooling) MUST keep validating unchanged.

#### Scenario: A directly-built context still validates

- **WHEN** a caller unifies `#TransformerContext` with explicit metadata blocks and a runtime name, outside any `#transform`
- **THEN** the value validates and its folds compute exactly as before this change
