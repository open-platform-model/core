## MODIFIED Requirements

### Requirement: A published core release notifies its cascade downstreams

After a release of `opmodel.dev/core@v2` is published from `main`, core's release run MUST send an `upstream-released` notification naming core and the release tag to each of its cascade downstreams, catalog_opm and library, and to no other repo: at least one per published release, one per run attempt. A repeat is harmless, because a receiver re-resolves the newest published version itself. A maintenance release of `opmodel.dev/core@v1` from the `v1` branch MUST NOT notify: every downstream pins `@v2`. The notification MUST start only after the module publish for that tag has succeeded, so a downstream is never told about a version GHCR does not serve. A failed or skipped module publish MUST NOT notify. The docs bundle publish MUST NOT gate the notification, and the notification MUST NOT gate the docs bundle publish.

The tag is the release tag release-please created, for example `v2.0.0-beta.3`. The payload carries only the source and the tag; which repos are notified is fixed by the shared `cascade-notify` action, not chosen by core.

core has no receiver: no notification from any repo moves a pin in core, and core runs no cascade gates.

Source: workspace `RELEASING.md`, "Notify after publish" and "repository_dispatch"; Phase 3 wiring contract (version 3.1) §4.5 and §4.6.

#### Scenario: A release whose module is published notifies catalog_opm and library

- **WHEN** the release PR for `v2.0.0-beta.3` is merged and the module publish for `v2.0.0-beta.3` succeeds
- **THEN** catalog_opm and library each receive an `upstream-released` dispatch with source `core` and tags `["v2.0.0-beta.3"]`, and cli and opm-controller receive none

#### Scenario: A failed module publish notifies nobody

- **WHEN** the module publish for a release fails, for example because GHCR already holds the version
- **THEN** no downstream is notified in that run

#### Scenario: A push to main that cuts no release notifies nobody

- **WHEN** a commit lands on `main` and release-please only opens or updates the release PR
- **THEN** no module is published and no downstream is notified

#### Scenario: A failed docs bundle publish does not stop the notification

- **WHEN** the module publish succeeds and the docs bundle publish for the same release fails
- **THEN** catalog_opm and library are still notified

#### Scenario: A v1 maintenance release notifies nobody

- **WHEN** the release PR on the `v1` branch is merged and a `v1.1.x` patch of `opmodel.dev/core@v1` is published
- **THEN** no downstream is notified, and the `@v2` line's notification is unaffected

