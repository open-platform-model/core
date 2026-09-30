## ADDED Requirements

### Requirement: Contract keys defined by more than one enabled entry are reported as collisions

A *definer* of a contract key MUST be an enabled registry entry whose catalog lists that key in `#resources`, `#traits` or `#blueprints`; a disabled entry MUST never count as a definer. `#contracts.collisions` MUST list, sorted ascending, every contract key with more than one definer. `#contracts.collidingEntries` MUST map each such key, and no other, to the ascending-sorted registry keys (the catalog module path with its major, `path@vN`) of its definers. A colliding key MUST be absent from `defined`, `definedBy` and `requiredBy`, and MUST NOT appear in `unfulfilled` or in any `comparable` row. `providedBy` and `overSubscribed` MUST be unaffected by collisions, so a collision and an over-subscription MAY be reported together. `#contracts.routable` MUST be `false` while `collisions` is non-empty. A platform with no key defined by more than one enabled entry MUST derive empty `collisions` and `collidingEntries` and every other inventory field exactly as before this requirement.

Because a colliding key leaves `defined`, `fulfilled` and `discriminated` MAY read `true` on a colliding platform whose single-major equivalent reads them `false`. This is a known limitation: a consumer MUST treat a non-empty `collisions` as overriding both, and `routable` is `false` on every such platform.

Source: enhancement 0026 OQ17 recommends this fold as an interim core fix ahead of 0026 D9; it delivers no 0026 decision.

#### Scenario: Two majors sharing keys report every shared key as a collision

- **WHEN** a platform enables `opmodel.dev/catalogs/opm@v1` and `opmodel.dev/catalogs/opm@v2`, both listing the same container resource, scaling and backup traits and stateless blueprint, and each shipping its own transformer requiring the container
- **THEN** the platform evaluates, `collisions` lists those four keys ascending, `collidingEntries` maps each to `["opmodel.dev/catalogs/opm@v1", "opmodel.dev/catalogs/opm@v2"]`, `routable` is `false`, `overSubscribed` is empty, and `#composedTransformers` holds both transformers

#### Scenario: A key only one major lists is folded as before

- **WHEN** a platform enables three majors of one catalog, two keys are listed by all three, two more by the first two only, and a volume resource by the second major alone
- **THEN** `collisions` holds the four shared keys, `collidingEntries` names all three registry keys for the first two and two registry keys for the other two, and `defined` and `definedBy` hold the volume resource alone, `definedBy` naming the second major's registry key

#### Scenario: A platform with one enabled major is unchanged

- **WHEN** a platform enables one major of a catalog and no other entry lists any of its keys
- **THEN** `collisions` and `collidingEntries` are empty, and every other inventory field reads as it did before collisions were reported

#### Scenario: A disabled second major defines nothing

- **WHEN** a platform enables `opmodel.dev/catalogs/opm@v1` and declares `opmodel.dev/catalogs/opm@v2`, listing the same keys, with `enable: false`
- **THEN** `collisions` and `collidingEntries` are empty and the inventory reads exactly as for `opmodel.dev/catalogs/opm@v1` alone

#### Scenario: A collision and an over-subscription are reported together

- **WHEN** a platform enables two majors of the base catalog sharing keys, plus two provider entries each requiring the provider-fulfilled `backup` trait
- **THEN** `collisions` names the shared keys including `backup`, `overSubscribed` is `[<backup's FQN>]`, `providedBy` names both provider registry keys for `backup`, and `routable` is `false`

#### Scenario: Fulfilled and discriminated can read true while a collision exists

- **WHEN** two enabled majors of one catalog both list the provider-fulfilled `backup` trait with no provider on the platform, and each ships a transformer requiring only the colliding container resource, with equal predicates
- **THEN** `requiredBy` has no key for the container or for `backup`, `unfulfilled` is empty, `fulfilled` is `true`, `comparable` is empty, `discriminated` is `true`, and `routable` is `false`

## MODIFIED Requirements

### Requirement: A platform derives its contract inventory from its enabled entries

`#Platform` MUST derive `#contracts: #ContractInventory`. `defined` MUST hold every member of every enabled registry entry's `#resources`, `#traits` and `#blueprints` whose contract FQN exactly one enabled entry lists, keyed by the member's contract FQN and carrying the member value as the catalog lists it; `definedBy` MUST map each such FQN to the registry key (the catalog's module path) of the entry listing it. A contract FQN more than one enabled entry lists MUST be in neither map; it is reported as a collision. A disabled entry MUST contribute nothing. The inventory MUST NOT be authorable and no runtime MUST fill it.

#### Scenario: Listed members of an enabled catalog are defined

- **WHEN** a platform's enabled entry embeds a catalog listing a resource, two traits and a blueprint
- **THEN** `#contracts.defined` holds exactly those four keys, and `#contracts.definedBy` maps each to that entry's registry key

#### Scenario: A disabled entry defines nothing

- **WHEN** a platform declares an entry with `enable: false` whose catalog lists members
- **THEN** none of that catalog's contracts appear in `defined` or `definedBy`, and none of its transformers appear in any `requiredBy` list

### Requirement: Over-subscription counts providing registry entries, not transformers

`#contracts.overSubscribed` MUST list every key of `providedBy` whose list holds more than one registry key, including a contract no enabled entry defines. The counting key is the registry key, so two majors of one catalog MUST count as two providers, and two transformers of one entry requiring one contract MUST count as one provider. `#contracts.routable` MUST be true exactly when `overSubscribed` is empty and `collisions` is empty.

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

### Requirement: The inventory reports and never refuses

Neither report MUST make the platform value fail to evaluate: an over-subscribed, unfulfilled, undiscriminated or colliding platform MUST still evaluate, with the offending contracts, transformer pairs and registry entries named in the lists (enhancement 0015 D18). In particular, a platform whose enabled entries list the same contract key MUST evaluate, with that key in `collisions` rather than a conflict in `defined` or `definedBy`. Whether `routable: false` or `discriminated: false` withholds a generated platform package is the generation step's decision, outside `core`; `fulfilled: false` MUST NOT gate anything.

#### Scenario: An over-subscribed platform still evaluates

- **WHEN** a platform is over-subscribed on one contract
- **THEN** the platform value evaluates, `#composedTransformers` is intact, and `overSubscribed` names the contract

#### Scenario: A platform with comparable predicates still evaluates

- **WHEN** two enabled catalogs ship transformers with identical predicates over one catalog-fulfilled resource
- **THEN** the platform value evaluates, `#composedTransformers` holds both transformers, and `comparable` names the pair

#### Scenario: Two majors with shared keys still evaluate

- **WHEN** a platform enables two majors of one catalog whose catalogs list the same contract keys at different catalog versions
- **THEN** the platform value evaluates instead of conflicting on `metadata.catalogVersion` or `definedBy`, `#composedTransformers` holds both majors' transformers, `collisions` names the shared keys, and `routable` is `false`

### Requirement: An empty registry yields an empty inventory

A `#Platform` with no enabled entries MUST derive empty `defined`, `definedBy`, `requiredBy` and `providedBy`, empty `unfulfilled`, `overSubscribed`, `comparable`, `collisions` and `collidingEntries`, and `fulfilled`, `routable` and `discriminated` all `true`. The definition itself MUST evaluate with no registry at all.

#### Scenario: A platform with no entries is trivially fulfilled and routable

- **WHEN** a platform declares `metadata` and `type` and no `#registry` entries
- **THEN** every inventory map and list is empty and all three booleans are `true`
