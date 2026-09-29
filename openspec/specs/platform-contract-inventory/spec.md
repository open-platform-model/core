## Purpose

Defines what a `#Platform` derives about the contracts its enabled catalogs define and its enabled transformers require: which contracts exist, which catalog lists each, which implementations require each, which provider-fulfilled contracts nothing implements, which have more than one provider, and which pairs of transformers are not discriminated from one another over a contract their own catalogs fulfil. The inventory is a report a platform carries with no module in hand (enhancement 0015 D1, D2, D5, D18).

## Requirements

### Requirement: A platform derives its contract inventory from its enabled entries

`#Platform` MUST derive `#contracts: #ContractInventory`. `defined` MUST hold every member of every enabled registry entry's `#resources`, `#traits` and `#blueprints`, keyed by the member's contract FQN and carrying the member value as the catalog lists it; `definedBy` MUST map each such FQN to the registry key (the catalog's module path) of the entry listing it. A disabled entry MUST contribute nothing. The inventory MUST NOT be authorable and no runtime MUST fill it.

#### Scenario: Listed members of an enabled catalog are defined

- **WHEN** a platform's enabled entry embeds a catalog listing a resource, two traits and a blueprint
- **THEN** `#contracts.defined` holds exactly those four keys, and `#contracts.definedBy` maps each to that entry's registry key

#### Scenario: A disabled entry defines nothing

- **WHEN** a platform declares an entry with `enable: false` whose catalog lists members
- **THEN** none of that catalog's contracts appear in `defined` or `definedBy`, and none of its transformers appear in any `requiredBy` list

### Requirement: Required demands are counted per contract across enabled transformers

`#contracts.requiredBy` MUST map every defined contract FQN to the list of implementation FQNs, drawn from `#composedTransformers`, whose `requiredResources` or `requiredTraits` name that contract. Optional demands MUST NOT count (0010 D32: tolerance, not fulfilment). A transformer declaring no demand map of a kind MUST be treated as demanding nothing of that kind. A defined contract nothing requires MUST map to an empty list.

#### Scenario: A contract required by transformers from two catalogs lists both

- **WHEN** an enabled catalog's transformer and a second enabled catalog's transformer both require the same resource
- **THEN** `requiredBy` for that resource lists both implementation FQNs

#### Scenario: A transformer without a traits map demands no trait

- **WHEN** an enabled transformer declares `requiredResources` and no `requiredTraits`
- **THEN** the inventory evaluates, and no trait's `requiredBy` list names that transformer

### Requirement: Unfulfilled contracts are the provider-fulfilled ones nothing requires

`#contracts.unfulfilled` MUST list every defined resource or trait whose `fulfilment` is `"provider"` and which has no key in `providedBy`. Blueprints MUST never appear: a blueprint carries no fulfilment. A contract no enabled catalog defines MUST NOT appear, whether or not anything provides it: nothing on the platform declares it, and a component demand for it is the render's unresolved demand, not an inventory fact. `#contracts.fulfilled` MUST be true exactly when `unfulfilled` is empty.

#### Scenario: A provider-fulfilled trait with no adapter is unfulfilled

- **WHEN** an enabled catalog lists a trait declaring `fulfilment: "provider"` and no enabled transformer requires it
- **THEN** `unfulfilled` is `[<that trait's FQN>]` and `fulfilled` is `false`

#### Scenario: A catalog-fulfilled trait nothing requires is not unfulfilled

- **WHEN** an enabled catalog lists a trait with the default `fulfilment` and no transformer requires it
- **THEN** `unfulfilled` is empty and `fulfilled` is `true`

#### Scenario: A provided contract no enabled catalog defines is not unfulfilled

- **WHEN** the catalog defining a provider-fulfilled trait is disabled and an enabled entry's transformer requires the trait
- **THEN** `unfulfilled` is empty and `fulfilled` is `true`

### Requirement: A transformer's match predicate is every required demand it declares

An enabled transformer's match predicate MUST be the union of three demand kinds: every FQN in `requiredResources`, every FQN in `requiredTraits`, and every key-and-value pair in `requiredLabels`. A required label MUST contribute its key and its value together, so two transformers requiring the same label key with different values declare different demands. Optional demands MUST NOT contribute (0010 D32: tolerance is not fulfilment). A transformer declaring no map of a kind MUST be treated as declaring no demand of that kind.

#### Scenario: A required trait is part of the predicate, not only labels

- **WHEN** two enabled transformers require the same resource, one additionally requiring a trait and the other additionally requiring a label
- **THEN** neither transformer's predicate contains the other's, because the trait demand and the label demand are each part of their declaring transformer's predicate

#### Scenario: An optional demand does not widen the predicate

- **WHEN** an enabled transformer declares a resource in `requiredResources` and a trait in `optionalTraits`
- **THEN** its predicate is that resource alone

### Requirement: Comparable predicates over a shared catalog-fulfilled contract are reported

`#contracts.comparable` MUST list every unordered pair of enabled transformers that satisfies both conditions: one transformer's predicate is a subset of the other's, and the two require at least one defined contract in common whose `fulfilment` is `"catalog"`. Each row MUST name both implementation FQNs — distinguishing the transformer with the smaller predicate, which matches every component the other matches, from the one with the larger predicate — and MUST name the shared catalog-fulfilled contracts. Two transformers with equal predicates MUST be reported as one row, not two. A pair whose predicates are incomparable MUST NOT appear.

#### Scenario: Two catalogs shipping the same adapter are comparable

- **WHEN** transformers from two enabled catalogs declare identical `requiredResources`, no required traits and no required labels, over a catalog-fulfilled resource
- **THEN** `comparable` holds exactly one row naming both implementation FQNs and that resource

#### Scenario: A strictly narrower predicate is comparable

- **WHEN** one enabled transformer requires a catalog-fulfilled resource and a second requires that resource plus a label
- **THEN** `comparable` holds one row naming both, identifying the first as the one matching every component the second matches

#### Scenario: Differing required label values are not comparable

- **WHEN** two enabled transformers require the same catalog-fulfilled resource and each requires the same label key with a different value
- **THEN** `comparable` is empty

#### Scenario: A distinct required trait is not comparable

- **WHEN** two enabled transformers require the same catalog-fulfilled resource, one additionally requiring a trait the other does not require and the other additionally requiring a label
- **THEN** `comparable` is empty

#### Scenario: A disabled entry's transformer is never paired

- **WHEN** a platform declares an entry with `enable: false` whose transformer has a predicate identical to an enabled transformer's
- **THEN** `comparable` is empty

### Requirement: The comparability report covers catalog-fulfilled contracts only

A pair whose only shared required contracts are provider-fulfilled MUST NOT appear in `comparable`, whichever catalogs the two transformers come from. Over-subscription of provider-fulfilled contracts remains reported by `overSubscribed` alone. Blueprints MUST never be the shared contract that qualifies a pair: a blueprint carries no fulfilment.

#### Scenario: Two adapters of one provider catalog are not comparable

- **WHEN** two transformers of one enabled catalog both require the same provider-fulfilled trait and nothing else
- **THEN** `comparable` is empty and `overSubscribed` is empty

#### Scenario: A provider-fulfilled bucket shared by two catalogs reports over-subscription only

- **WHEN** transformers from two enabled catalogs both require the same provider-fulfilled trait and nothing else
- **THEN** `overSubscribed` names that trait and `comparable` is empty

### Requirement: Discriminated is true exactly when no pair is comparable

`#contracts.discriminated` MUST be true exactly when `comparable` is empty. It is the value the generation step (operator, CLI) refuses on, in the same way it already refuses on `routable`; `core` itself MUST refuse nothing on it.

#### Scenario: A platform with one comparable pair is not discriminated

- **WHEN** a platform's inventory reports one comparable pair
- **THEN** `discriminated` is `false`

### Requirement: The inventory reports and never refuses

Neither report MUST make the platform value fail to evaluate: an over-subscribed, unfulfilled or undiscriminated platform MUST still evaluate, with the offending contracts and transformer pairs named in the lists (enhancement 0015 D18). Whether `routable: false` or `discriminated: false` withholds a generated platform package is the generation step's decision, outside `core`; `fulfilled: false` MUST NOT gate anything.

#### Scenario: An over-subscribed platform still evaluates

- **WHEN** a platform is over-subscribed on one contract
- **THEN** the platform value evaluates, `#composedTransformers` is intact, and `overSubscribed` names the contract

#### Scenario: A platform with comparable predicates still evaluates

- **WHEN** two enabled catalogs ship transformers with identical predicates over one catalog-fulfilled resource
- **THEN** the platform value evaluates, `#composedTransformers` holds both transformers, and `comparable` names the pair

### Requirement: An empty registry yields an empty inventory

A `#Platform` with no enabled entries MUST derive empty `defined`, `definedBy`, `requiredBy` and `providedBy`, empty `unfulfilled`, `overSubscribed` and `comparable`, and `fulfilled`, `routable` and `discriminated` all `true`. The definition itself MUST evaluate with no registry at all.

#### Scenario: A platform with no entries is trivially fulfilled and routable

- **WHEN** a platform declares `metadata` and `type` and no `#registry` entries
- **THEN** every inventory map and list is empty and all three booleans are `true`

### Requirement: The inventory names the registry entries providing each contract

`#contracts.providedBy` MUST map every contract FQN that some enabled transformer names in its `requiredResources` or `requiredTraits` with a requirement whose `fulfilment` is `"provider"` to the ascending-sorted list of registry keys (the catalog module path with its major, `path@vN`) of the enabled entries whose transformers do so. It is derived per registry entry, over every transformer of every enabled entry, and it MUST NOT depend on whether any enabled entry defines the contract. Fulfilment MUST be read from the transformer's own requirement value, never from the defining catalog's member. A key MUST be present exactly when at least one enabled entry provides the contract. Optional demands, required labels, catalog-fulfilled requirements, blueprints and disabled entries MUST NOT contribute. Each registry key MUST appear at most once per contract, however many of that entry's transformers require it.

Source: corrects the delivery of 0015:D2 (a refusal names both catalog paths) by exposing the paths it names.

#### Scenario: One provider entry through two adapters is one key

- **WHEN** an enabled entry `opmodel.dev/catalogs/k8up@v2` ships two transformers that both require the provider-fulfilled `backup` trait, and no other entry requires it
- **THEN** `providedBy` maps `backup` to `["opmodel.dev/catalogs/k8up@v2"]`

#### Scenario: Two majors of one catalog are two keys

- **WHEN** entries `opmodel.dev/catalogs/k8up@v2` and `opmodel.dev/catalogs/k8up@v3` are both enabled and each has a transformer requiring the provider-fulfilled `backup` trait
- **THEN** `providedBy` maps `backup` to `["opmodel.dev/catalogs/k8up@v2", "opmodel.dev/catalogs/k8up@v3"]`

#### Scenario: Providers of a contract no enabled entry defines are listed

- **WHEN** the entry that defines the provider-fulfilled `backup` trait is disabled or absent, and enabled entries `opmodel.dev/catalogs/k8up@v2` and `opmodel.dev/catalogs/velero@v1` each have a transformer requiring it
- **THEN** `providedBy` maps `backup` to `["opmodel.dev/catalogs/k8up@v2", "opmodel.dev/catalogs/velero@v1"]`, while `defined`, `definedBy` and `requiredBy` hold no key for it

#### Scenario: A contract nobody provides has no key

- **WHEN** an enabled catalog defines the provider-fulfilled `backup` trait and no enabled transformer requires it
- **THEN** `providedBy` has no `backup` key, and on a platform where no enabled transformer requires any provider-fulfilled contract `providedBy` is empty

#### Scenario: A disabled entry provides nothing

- **WHEN** an entry with `enable: false` has a transformer requiring a provider-fulfilled trait
- **THEN** that entry's registry key appears in no `providedBy` list

### Requirement: Over-subscription counts providing registry entries, not transformers

`#contracts.overSubscribed` MUST list every key of `providedBy` whose list holds more than one registry key, including a contract no enabled entry defines. The counting key is the registry key, so two majors of one catalog MUST count as two providers, and two transformers of one entry requiring one contract MUST count as one provider. `#contracts.routable` MUST be true exactly when `overSubscribed` is empty.

Source: corrects the delivery of 0015:D2 and 0015:D18; 0010:D37 is the rule counted.

#### Scenario: Two catalogs providing one contract is over-subscription

- **WHEN** transformers from two enabled catalogs each require a provider-fulfilled trait
- **THEN** `overSubscribed` is `[<that trait's FQN>]` and `routable` is `false`

#### Scenario: One catalog providing through two transformers is one provider

- **WHEN** two transformers of one enabled catalog require the same provider-fulfilled trait and no other catalog does
- **THEN** `overSubscribed` is empty and `routable` is `true`

#### Scenario: Two majors of one provider catalog are over-subscription

- **WHEN** a platform enables the defining catalog plus `opmodel.dev/catalogs/k8up@v2` and `opmodel.dev/catalogs/k8up@v3`, each shipping a transformer that requires only the provider-fulfilled `backup` trait
- **THEN** `overSubscribed` is `[<backup's FQN>]`, `routable` is `false`, `unfulfilled` is empty and `fulfilled` is `true`

#### Scenario: Two providers of an undefined contract are over-subscription

- **WHEN** the defining catalog's entry is disabled or absent and two enabled entries each have a transformer requiring the provider-fulfilled `backup` trait
- **THEN** `overSubscribed` is `[<backup's FQN>]` and `routable` is `false`, although `defined` is empty
