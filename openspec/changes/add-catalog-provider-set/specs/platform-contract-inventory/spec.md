## ADDED Requirements

### Requirement: The platform's provider count folds the enabled catalogs' provider sets

`#contracts.providedBy` MUST equal the fold of every enabled registry entry's `#catalog.provides`: for each contract FQN in some enabled entry's `provides`, the ascending-sorted registry keys (`path@vN`) of the enabled entries whose `provides` lists it. A disabled entry's `provides` MUST NOT contribute. The fold MUST NOT change any value of `providedBy`, `overSubscribed`, `unfulfilled`, `fulfilled` or `routable` that the existing per-transformer rule derives, so the platform and the catalog state one rule.

Source: owner decision h2 of the beta.1 kernel plan walkthrough (one rule, now readable per catalog).

#### Scenario: One provider entry folds to one key

- **WHEN** a platform enables the defining catalog and one provider catalog `opmodel.dev/catalogs/k8up@v2` whose `provides` is `["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"]`
- **THEN** `providedBy` maps that FQN to `["opmodel.dev/catalogs/k8up@v2"]`, the same value the fold of the enabled entries' `provides` gives

#### Scenario: Two provider entries fold to two keys

- **WHEN** a platform enables `opmodel.dev/catalogs/k8up@v2` and `opmodel.dev/catalogs/velero@v1`, each with `backup` in its `provides`
- **THEN** `providedBy` maps `backup` to `["opmodel.dev/catalogs/k8up@v2", "opmodel.dev/catalogs/velero@v1"]` and `overSubscribed` lists `backup`

#### Scenario: A disabled provider entry contributes nothing

- **WHEN** the only entry whose `provides` lists `backup` has `enable: false`
- **THEN** `providedBy` has no `backup` key, although that catalog's own `provides` still lists it

#### Scenario: Two majors of one provider are two keys

- **WHEN** a platform enables `opmodel.dev/catalogs/k8up@v2` and `opmodel.dev/catalogs/k8up@v3`, each with `backup` in its `provides`
- **THEN** `providedBy` maps `backup` to both registry keys and `routable` is `false`
