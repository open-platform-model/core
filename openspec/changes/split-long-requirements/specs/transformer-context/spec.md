## MODIFIED Requirements

### Requirement: The context's metadata blocks are projections of the other two inputs

At the `#transform` site, `#context.#moduleInstanceMetadata` MUST be computed from `#moduleInstance` (`name`, `namespace`, `fqn`, `uuid` from the instance's metadata; `version` from the instance's module metadata) and `#context.#componentMetadata` MUST be computed from `#component` (`name` from the component's metadata). A runtime MUST NOT be required to supply either block. Field names and value shapes are unchanged from the pre-projection context.

#### Scenario: The context computes from filled inputs

- **WHEN** a `#transform` has `#moduleInstance` and `#component` filled concretely and `#runtimeName` supplied
- **THEN** every `#context` metadata field evaluates concretely from those inputs with nothing else supplied, and the label and annotation folds resolve from the projected blocks

#### Scenario: Transformer-visible values are unchanged

- **WHEN** a transformer reads `#context.#moduleInstanceMetadata.namespace` or `#context.controllerLabels` on a render whose inputs match a pre-projection render
- **THEN** the values are identical to what the runtime-assembled context carried

