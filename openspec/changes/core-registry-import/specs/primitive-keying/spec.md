## ADDED Requirements

### Requirement: FQN map keys are typed by the role they hold

No map declared by `core` takes `#FQNType`. A map whose keys name contracts MUST be keyed `#ContractFQNType`: `#ComponentTransformer.requiredResources`, `optionalResources`, `requiredTraits` and `optionalTraits`. A map whose keys name implementations MUST be keyed `#ImplFQNType`: `#TransformerMap` and `#Catalog.#transformers`.

A wrong-form key MUST be refused rather than merely failing to match, since an unmatched key surfaces as a transformer that renders nothing rather than as an error naming the key.

What `core` enforces is the key's **form**, not its agreement with anything. That a demand map's key equals its own value's `metadata.fqn` is an invariant of whichever runtime writes it; `core` declares no constraint tying a key to its value.

#### Scenario: A build-shaped key is refused in a demand map

- **WHEN** a `#ComponentTransformer` declares `requiredResources` with the key `"opmodel.dev/catalogs/opm/resources/backup@1.2.0"`
- **THEN** validation fails with a field-not-allowed error, because no `#Resource` can carry a key in that form

#### Scenario: A contract-shaped key is refused in a transformer map

- **WHEN** a `#TransformerMap` is keyed `"opmodel.dev/catalogs/opm/transformers/backup-transformer@v1"`
- **THEN** validation fails with a field-not-allowed error

## REMOVED Requirements

### Requirement: Every FQN map key is typed by the role it holds

**Reason**: not removed as a capability; restated as the ADDED requirement "FQN map keys are typed by the role they hold" above. The prior text enumerated `#Platform.#matchers.resources` / `traits` among the contract-keyed maps, stated the matcher-bucket key/value invariant, and carried a matcher-bucket scenario; `#matchers` is removed outright by this change (enhancement 0019 D17), so those clauses name a map that no longer exists. Every other clause and scenario is carried forward verbatim. Stated as REMOVED + ADDED (with a retitle) because a MODIFIED delta cannot drop a scenario.

**Migration**: none for the surviving clauses. A runtime that filled `#Platform.#matchers` buckets stops; consumers wanting a contract-to-transformers index derive it from `#composedTransformers` (see the platform-subscription deltas in this change).
