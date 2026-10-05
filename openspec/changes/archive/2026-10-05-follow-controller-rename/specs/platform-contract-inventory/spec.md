## MODIFIED Requirements

### Requirement: Discriminated is true exactly when no pair is comparable

`#contracts.discriminated` MUST be true exactly when `comparable` is empty. It is the value the generation step (controller, CLI) refuses on, in the same way it already refuses on `routable`; `core` itself MUST refuse nothing on it.

#### Scenario: A platform with one comparable pair is not discriminated

- **WHEN** a platform's inventory reports one comparable pair
- **THEN** `discriminated` is `false`

