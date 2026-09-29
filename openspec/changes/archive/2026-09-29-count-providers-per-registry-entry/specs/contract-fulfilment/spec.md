## MODIFIED Requirements

### Requirement: A provider-fulfilled contract admits exactly one provider

For a contract declaring `fulfilment: "provider"`, a platform MUST carry exactly one provider of that contract, a provider being an enabled registry entry whose transformers *require* the contract. The count is of registry entries, keyed by registry key (the catalog module path with its major): two transformers of one entry requiring the contract are one provider, and two enabled majors of one catalog are two. A provider counts whether or not any enabled entry defines the contract. Two providers MUST be refused, naming both registry keys and the contract key. Zero is an unresolved demand, which fails the render unless the render's caller asked to skip unprovided provider-fulfilled demands (see "A render's caller may skip unprovided provider-fulfilled demands"). Two remain refused under that request.

This is enforced outside the schema: `core` declares the intent and computes the count once, as the platform's contract inventory (`#Platform.#contracts.providedBy`, `overSubscribed` and `routable`), which reports it without refusing on it. The kernel's render build and the generation step (operator, CLI) refuse on that one count; none of them keeps a count of its own. The requirement is stated here because it is what `fulfilment: "provider"` means.

#### Scenario: Two providers for one contract are refused

- **WHEN** a platform enables two catalogs whose transformers both declare the same provider-fulfilled contract in `requiredResources`
- **THEN** the render build refuses, naming both catalog paths and the contract key, with no arbitration between them

#### Scenario: One provider is accepted

- **WHEN** exactly one enabled catalog carries transformers requiring the provider-fulfilled contract, whether one transformer or several
- **THEN** the render build does not refuse on the provider count

#### Scenario: Optional demands do not count as provision

- **WHEN** a transformer names a provider-fulfilled contract among its optional demands rather than its required ones
- **THEN** it is not counted as a provider of that contract

#### Scenario: Two majors of one provider catalog are two providers

- **WHEN** a platform enables `opmodel.dev/catalogs/k8up@v2` and `opmodel.dev/catalogs/k8up@v3`, and a transformer of each requires the same provider-fulfilled contract
- **THEN** the platform's contract inventory reports the contract over-subscribed and not routable, naming both registry keys, and the render build refuses on that same count

#### Scenario: Providers count when the defining catalog is not enabled

- **WHEN** the catalog defining a provider-fulfilled contract is disabled or absent, and two enabled entries have transformers requiring it
- **THEN** the platform's contract inventory reports the contract over-subscribed and not routable, and the render build refuses on that same count
