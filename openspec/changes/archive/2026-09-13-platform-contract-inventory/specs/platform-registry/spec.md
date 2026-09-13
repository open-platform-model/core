## MODIFIED Requirements

### Requirement: A platform carries no reverse index

`#Platform` MUST NOT declare `#matchers`. A platform value declaring one is inert: nothing in `core` or in the render build's matching glue reads it (closedness does not refuse an undeclared definition field, measured 2026-09-13 on cue v0.17.1). Consumers that want a contract-to-transformers index for matching MUST derive it from `#composedTransformers`. `#contracts.requiredBy` is a derived readiness index (contract FQN to the implementation FQNs requiring it), not a matcher bucket: the matching glue MUST NOT read it, and it carries no primitive values.

#### Scenario: A declared reverse index is refused

- **WHEN** a platform value declares `#matchers: {...}` in any shape
- **THEN** it is refused as an input: no derived field of `#Platform` and no matching step consults it, and the render's buckets come from `#composedTransformers` alone (closedness itself does not reject the field, measured 2026-09-13)

#### Scenario: The readiness index is not a matcher bucket

- **WHEN** a platform derives `#contracts.requiredBy` for a contract two transformers require
- **THEN** the entry lists two implementation FQNs and no transformer or primitive value, and `#composedTransformers` is unchanged by it
