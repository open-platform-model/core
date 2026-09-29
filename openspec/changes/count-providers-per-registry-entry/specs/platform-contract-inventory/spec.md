## ADDED Requirements

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

## MODIFIED Requirements

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

### Requirement: An empty registry yields an empty inventory

A `#Platform` with no enabled entries MUST derive empty `defined`, `definedBy`, `requiredBy` and `providedBy`, empty `unfulfilled`, `overSubscribed` and `comparable`, and `fulfilled`, `routable` and `discriminated` all `true`. The definition itself MUST evaluate with no registry at all.

#### Scenario: A platform with no entries is trivially fulfilled and routable

- **WHEN** a platform declares `metadata` and `type` and no `#registry` entries
- **THEN** every inventory map and list is empty and all three booleans are `true`

## REMOVED Requirements

### Requirement: Over-subscription counts providing catalogs, not transformers

**Reason**: It counted only contracts an enabled catalog defines and keyed a provider by its transformers' stamped, major-free `metadata.modulePath`, so it disagreed with the render build on two majors of one provider catalog and on providers of a contract whose definer is disabled or absent.

**Migration**: Replaced by "Over-subscription counts providing registry entries, not transformers", which keeps both scenarios verbatim and counts per registry key over every enabled transformer. Consumers read the same `overSubscribed` and `routable` fields, and `providedBy` for the providing registry keys.
