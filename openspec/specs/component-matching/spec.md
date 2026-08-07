## Purpose

Defines what a component and its attached primitives declare that a `#ComponentTransformer` selects on. Matching identity lives in its own field, `matchLabels`, structurally separate from the `metadata.labels` that carry categorisation — so a genuine disagreement between two primitives is a conflict and an unrelated one is not. Covers the wholesale upward unification and why it embeds structs rather than iterating them, the survival of a required matching key, `core`'s absence from the matching vocabulary, why match labels reach no rendered object, and the rule that a component contributes no matching identity of its own.

## Requirements

### Requirement: Matching identity lives in its own field

`#Resource`, `#Trait`, `#Blueprint` and `#Component` MUST each carry a `matchLabels` field. `#ComponentTransformer.requiredLabels` MUST select on `matchLabels`.

`metadata.labels` MUST keep its current meaning and MUST NOT be unified upward from primitives to components.

#### Scenario: A transformer selects on matchLabels

- **WHEN** a transformer declares `requiredLabels: {"opm.opmodel.dev/workload-type": "stateless"}` and a component's `matchLabels` carries that pair
- **THEN** the component satisfies the transformer's label predicate

#### Scenario: Categorisation labels do not participate in matching

- **WHEN** a component's attached primitives carry differing `metadata.labels["resource.opmodel.dev/category"]` values — `workload`, `storage` and `config`
- **THEN** the component evaluates without conflict, because `metadata.labels` is not unified upward

### Requirement: A component's matchLabels is the wholesale unification of its primitives'

`#Component.matchLabels` MUST be the unification of the `matchLabels` of every attached resource, trait and blueprint, with no filter, no key prefix rule and no key list.

#### Scenario: Match labels combine across attached primitives

- **WHEN** a component attaches one primitive declaring `{a: "1"}` and another declaring `{b: "2"}` in `matchLabels`
- **THEN** the component's `matchLabels` is `{a: "1", b: "2"}`

#### Scenario: A genuine disagreement is a conflict

- **WHEN** a component attaches two primitives whose `matchLabels` declare the same key with different values — `"daemon"` and `"stateful"`
- **THEN** unification fails with a conflicting-values error naming that key

### Requirement: A required matching field survives the unification

Because `matchLabels` unifies wholesale rather than by iteration, a primitive MUST be able to declare a matching label as a required field, and that requirement MUST survive into the component.

#### Scenario: An unset required match label is reported

- **WHEN** a primitive declares a required workload-type match label and a component attaches it without supplying a value
- **THEN** evaluation reports the required field as missing, rather than yielding an incomplete value silently

### Requirement: `core` does not name the matching vocabulary

`core` MUST NOT name a matching label key, and MUST NOT export a constant holding one. The workload-type key MUST be owned by the catalog that defines the vocabulary.

#### Scenario: `core` exports no matching-key constant

- **WHEN** the `core` package is evaluated
- **THEN** `#LabelWorkloadType` is not a member of it

#### Scenario: A catalog introduces a matching key without a `core` release

- **WHEN** a catalog defines a new matching label key on one of its primitives
- **THEN** the key participates in matching with no change to `core`

### Requirement: Match labels are not rendered

`matchLabels` MUST NOT reach `#TransformerContext.componentLabels` and MUST NOT appear on any rendered object.

#### Scenario: A rendered object carries no match labels

- **WHEN** a component with non-empty `matchLabels` is rendered
- **THEN** no rendered object carries those keys, and `componentLabels` is unchanged by them

### Requirement: A component's matching identity is exactly what it attaches

A `#Component` MUST NOT contribute a `matchLabels` key of its own, and declaring one MUST fail. This binds every `#Component` — both the wrapper *fragments* a catalog ships and a module author's own components. The schema cannot distinguish the two, and does not try: a fragment and a component are the same type.

A required matching key MUST be answered by attaching a primitive or blueprint that supplies it, not by declaring it on the component.

#### Scenario: A fragment's matching identity comes only from what it attaches

- **WHEN** a fragment attaches a set of primitives
- **THEN** the resulting component's `matchLabels` is exactly the unification of those primitives', with nothing contributed by the fragment

#### Scenario: An invented key is refused

- **WHEN** a component declares a `matchLabels` key that no attached primitive declares
- **THEN** evaluation fails, because the component's matching identity is derived rather than authored

#### Scenario: Answering a required key inline is refused

- **WHEN** a component attaches a primitive declaring a required matching key and answers that key on the component itself
- **THEN** evaluation fails; the key is answered by attaching a blueprint that supplies it
