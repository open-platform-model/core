## ADDED Requirements

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

`#LabelWorkloadType` MUST be removed from `core`. No `core` construct MUST name a matching label key. The workload-type key MUST be owned by the catalog that defines the vocabulary.

#### Scenario: The workload-type constant is gone

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

### Requirement: A component fragment declares no matching identity of its own

Component fragments MUST be pure wrappers that attach primitives. A fragment MUST NOT declare `matchLabels` directly.

#### Scenario: A fragment's matching identity comes only from what it attaches

- **WHEN** a fragment attaches a set of primitives
- **THEN** the resulting component's `matchLabels` is exactly the unification of those primitives', with nothing contributed by the fragment
