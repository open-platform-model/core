## MODIFIED Requirements

### Requirement: The inventory names the registry entries providing each contract

`#contracts.providedBy` MUST map every contract FQN that some transformer of an enabled entry's `#catalog` names in its `requiredResources` or `requiredTraits` with a requirement whose `fulfilment` is `"provider"` to the ascending-sorted list of registry keys (the catalog module path with its major, `path@vN`) of the enabled entries whose transformers do so. It is derived per registry entry, over the transformers of every enabled entry's `#catalog.#transformers`, and it MUST NOT depend on whether any enabled entry defines the contract. It MUST equal the fold, by registry key, of every enabled entry's `#catalog.provides` (catalog-contracts), so the platform and the catalog state one rule. A transformer written on the entry's own `#transformers` readout rather than in the catalog is outside that fold: the readout is not authored (core#119 tracks whether to refuse it). Fulfilment MUST be read from the transformer's own requirement value, never from the defining catalog's member. A key MUST be present exactly when at least one enabled entry provides the contract. Optional demands, required labels, catalog-fulfilled requirements, blueprints and disabled entries MUST NOT contribute. Each registry key MUST appear at most once per contract, however many of that entry's transformers require it.

Source: corrects the delivery of 0015:D2 (a refusal names both catalog paths) by exposing the paths it names. The fold over `#catalog.provides` follows library ADR-012.

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

#### Scenario: A provider-fulfilled resource requirement folds through the catalog's provides

- **WHEN** an enabled entry `opmodel.dev/catalogs/s3@v1` ships a transformer requiring the provider-fulfilled resource `opmodel.dev/catalogs/s3/resources/bucket@v1alpha1` under `requiredResources` and the provider-fulfilled `backup` trait under `requiredTraits`, so its `#catalog.provides` lists both
- **THEN** `providedBy` maps each of the two FQNs to `["opmodel.dev/catalogs/s3@v1"]`
