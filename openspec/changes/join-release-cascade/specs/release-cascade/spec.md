## Purpose

Defines how a published core release takes part in the cross-repo release cascade: once the module is public, core notifies its downstream repos through the shared notify workflow and the `opm-cascade` App, and core itself receives nothing.

## ADDED Requirements

### Requirement: A published core release notifies its cascade downstreams

After a release of `opmodel.dev/core@v2` is published from `main`, core's release run MUST send an `upstream-released` notification naming core and the release tag to each of its cascade downstreams, catalog_opm and library, and to no other repo: at least one per published release, one per run attempt. A repeat is harmless, because a receiver re-resolves the newest published version itself. A maintenance release of `opmodel.dev/core@v1` from the `v1` branch MUST NOT notify: every downstream pins `@v2`. The notification MUST start only after the module publish for that tag has succeeded, so a downstream is never told about a version GHCR does not serve. A failed or skipped module publish MUST NOT notify. The docs bundle publish MUST NOT gate the notification, and the notification MUST NOT gate the docs bundle publish.

The tag is the release tag release-please created, for example `v2.0.0-beta.3`. The payload carries only the source and the tag; which repos are notified is fixed by the shared notify workflow, not chosen by core.

core has no receiver: no notification from any repo moves a pin in core, and core runs no cascade gates.

Source: workspace `RELEASING.md`, "Notify after publish" and "repository_dispatch".

#### Scenario: A release whose module is published notifies catalog_opm and library

- **WHEN** the release PR for `v2.0.0-beta.3` is merged and the module publish for `v2.0.0-beta.3` succeeds
- **THEN** catalog_opm and library each receive an `upstream-released` dispatch with source `core` and tags `["v2.0.0-beta.3"]`, and cli and opm-operator receive none

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

### Requirement: The notification runs with the cascade App only, and can be switched off

The notification MUST authenticate with a token from the `opm-cascade` App, minted inside a job that runs in core's `cascade` Environment, whose deployments are limited to `main`. core's release job that starts it MUST grant the built-in token no more than read access to contents, and MUST NOT pass any secret to the shared workflow. The release App's key MUST NOT be used for the notification.

The repo variable `CASCADE_NOTIFY` set to exactly `off` MUST stop core's releases from notifying. Any other value, or no variable, MUST leave the notification on. The switch MUST NOT affect the release or the publish.

A notification that fails after its retries MUST fail the release run visibly. Re-sending it MUST NOT re-publish the module; re-running the failed job sends the notification again for the same tag.

Source: workspace `RELEASING.md`, "repository_dispatch", "Stop switches" and "Owner settings", "The opm-cascade App". "Stop switches" lists `CASCADE_NOTIFY` once the Phase 3 wiring contract's §14 amendment lands, which happens before this change merges.

#### Scenario: Notify is switched off

- **WHEN** `CASCADE_NOTIFY` is `off` in core and a release is published
- **THEN** the module and the docs bundle are published as usual, and no downstream is notified

#### Scenario: An unset switch leaves notify on

- **WHEN** core has no `CASCADE_NOTIFY` variable, or it holds any value other than `off`, and a release is published
- **THEN** catalog_opm and library are notified

#### Scenario: A lost dispatch is recovered without a re-publish

- **WHEN** the notification to library fails after its retries, while the module is already published
- **THEN** the release run is red, catalog_opm has still been notified, and re-running the failed job re-sends the notification for the same tag to both catalog_opm and library without running the module publish again

#### Scenario: The notification never uses the release credentials

- **WHEN** the notification runs
- **THEN** it uses only a token minted from the `opm-cascade` App in the `cascade` Environment, and the job that starts it in core holds read-only contents access and no secret
