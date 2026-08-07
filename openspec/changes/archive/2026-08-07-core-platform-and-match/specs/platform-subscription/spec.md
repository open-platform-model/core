## ADDED Requirements

### Requirement: A subscription names exactly one catalog build

`#Subscription` MUST carry a required `version!` typed `#VersionType`, naming the single build that subscription materializes. `#SubscriptionFilter` MUST be removed, together with `range`, `allow`, `deny`, the prerelease flag and the empty-filter default.

#### Scenario: A subscription naming one build is accepted

- **WHEN** a `#Platform` declares a subscription with `version: "1.2.0"` for a catalog path
- **THEN** the value validates

#### Scenario: A subscription with no version is refused

- **WHEN** a `#Platform` declares a subscription with `enable: true` and no `version`
- **THEN** evaluation reports the required field as missing, rather than defaulting to a resolved highest published build

#### Scenario: The filter shape no longer exists

- **WHEN** a `#Platform` declares a subscription with `filter: {range: ">=1.0.0 <2.0.0"}`
- **THEN** validation fails, because neither `filter` nor `#SubscriptionFilter` exists

### Requirement: A prerelease is selected by being written down

A prerelease build MUST be selectable by naming it in `version`, with no opt-in flag and no maturity inference.

#### Scenario: A prerelease version is accepted like any other

- **WHEN** a subscription declares `version: "1.0.0-alpha.2"`
- **THEN** the value validates, with no additional flag required

### Requirement: Catalog selection is a pure function of committed source

Nothing in the subscription shape MUST require a resolution step against a registry to determine which build is selected. The declared value MUST be the selected value.

#### Scenario: Selection does not move when the registry does

- **WHEN** a platform declares `version: "1.2.0"` and a newer build `1.3.0` is published
- **THEN** the platform's selection is still `1.2.0`, with no lockfile consulted and no re-resolution performed

### Requirement: One subscription per catalog path

A `#Platform` MUST NOT be able to express two builds of one catalog. Two builds is two platforms.

#### Scenario: The map key enforces uniqueness

- **WHEN** a `#Platform` declares two subscriptions under the same catalog module path
- **THEN** CUE map semantics collapse them to one key, so two distinct builds of one catalog are not expressible
