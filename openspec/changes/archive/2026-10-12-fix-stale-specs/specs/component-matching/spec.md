## MODIFIED Requirements

### Requirement: A component's matching identity is exactly what it attaches

A `#Component` MUST NOT add a `matchLabels` key that its attached resources, traits and blueprints do not already give. The check compares the number of keys in `matchLabels` with the number in the union of the attached ones. A required key that no primitive has answered is not counted. The rule binds every `#Component`, a catalog fragment or a module author's own, because the schema cannot tell them apart. A required key MUST be answered by attaching a primitive or blueprint that supplies it.

#### Scenario: A fragment's matching identity comes only from what it attaches

- **WHEN** a fragment attaches a set of primitives
- **THEN** the resulting component's `matchLabels` is exactly the unification of those primitives', with nothing contributed by the fragment

#### Scenario: An invented key is refused

- **WHEN** a component declares a `matchLabels` key that no attached primitive declares
- **THEN** evaluation fails, because the component's matching identity is derived rather than authored

#### Scenario: Answering a required key inline is refused

- **WHEN** a component attaches a primitive declaring a required matching key and answers that key on the component itself
- **THEN** evaluation fails; the key is answered by attaching a blueprint that supplies it

#### Scenario: Restating a derived key with its value passes

- **WHEN** a component attaches a primitive whose `matchLabels` holds `"x.example/k": "a"` and the component declares the same pair
- **THEN** evaluation succeeds and the component's `matchLabels` is `{"x.example/k": "a"}`

#### Scenario: Restating a derived key with another value is refused

- **WHEN** a component attaches a primitive whose `matchLabels` holds `"x.example/k": "a"` and the component declares `"x.example/k": "b"`
- **THEN** evaluation fails with a conflicting-values error naming that key
