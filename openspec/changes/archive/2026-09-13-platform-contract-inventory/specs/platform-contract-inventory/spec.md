## Purpose

Defines what a `#Platform` derives about the contracts its enabled catalogs define and its enabled transformers require: which contracts exist, which catalog lists each, which implementations require each, which provider-fulfilled contracts nothing implements, and which have more than one provider. The inventory is a report a platform carries with no module in hand (enhancement 0015 D1, D2, D18).

## ADDED Requirements

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

`#contracts.unfulfilled` MUST list every defined resource or trait whose `fulfilment` is `"provider"` and whose `requiredBy` list is empty. Blueprints MUST never appear: a blueprint carries no fulfilment. `#contracts.fulfilled` MUST be true exactly when `unfulfilled` is empty.

#### Scenario: A provider-fulfilled trait with no adapter is unfulfilled

- **WHEN** an enabled catalog lists a trait declaring `fulfilment: "provider"` and no enabled transformer requires it
- **THEN** `unfulfilled` is `[<that trait's FQN>]` and `fulfilled` is `false`

#### Scenario: A catalog-fulfilled trait nothing requires is not unfulfilled

- **WHEN** an enabled catalog lists a trait with the default `fulfilment` and no transformer requires it
- **THEN** `unfulfilled` is empty and `fulfilled` is `true`

### Requirement: Over-subscription counts providing catalogs, not transformers

`#contracts.overSubscribed` MUST list every defined resource or trait whose `fulfilment` is `"provider"` and whose requiring transformers come from more than one catalog, a transformer's catalog being the stamped `metadata.modulePath` it carries. Two transformers of one catalog requiring one contract MUST count as one provider. `#contracts.routable` MUST be true exactly when `overSubscribed` is empty.

#### Scenario: Two catalogs providing one contract is over-subscription

- **WHEN** transformers from two enabled catalogs each require a provider-fulfilled trait
- **THEN** `overSubscribed` is `[<that trait's FQN>]` and `routable` is `false`

#### Scenario: One catalog providing through two transformers is one provider

- **WHEN** two transformers of one enabled catalog require the same provider-fulfilled trait and no other catalog does
- **THEN** `overSubscribed` is empty and `routable` is `true`

### Requirement: The inventory reports and never refuses

Neither report MUST make the platform value fail to evaluate: an over-subscribed or unfulfilled platform MUST still evaluate, with the offending contracts named in the lists (enhancement 0015 D18). Whether `routable: false` withholds a generated platform package is the generation step's decision, outside `core`; `fulfilled: false` MUST NOT gate anything.

#### Scenario: An over-subscribed platform still evaluates

- **WHEN** a platform is over-subscribed on one contract
- **THEN** the platform value evaluates, `#composedTransformers` is intact, and `overSubscribed` names the contract

### Requirement: An empty registry yields an empty inventory

A `#Platform` with no enabled entries MUST derive empty `defined`, `definedBy` and `requiredBy`, empty `unfulfilled` and `overSubscribed`, and `fulfilled` and `routable` both `true`. The definition itself MUST evaluate with no registry at all.

#### Scenario: A platform with no entries is trivially fulfilled and routable

- **WHEN** a platform declares `metadata` and `type` and no `#registry` entries
- **THEN** every inventory map and list is empty and both booleans are `true`
