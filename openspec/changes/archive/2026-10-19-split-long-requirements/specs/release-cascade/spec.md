## REMOVED Requirements

### Requirement: A published core release notifies its cascade downstreams
**Reason**: Split into requirements that each state one behavior.
**Migration**: See "A published core release notifies catalog_opm and library", "A v1 maintenance release notifies nobody", "The notification starts only after the module publish succeeds", "The docs bundle publish and the notification do not gate each other", "The notification payload carries only the source and the release tag", "core receives no cascade notification".

### Requirement: The notification runs with the cascade App only, and can be switched off
**Reason**: Split into requirements that each state one behavior.
**Migration**: See "The cascade App key is read only in the notify-downstream job", "The notify job runs in the cascade Environment with a read-only token and never the release key", "CASCADE_NOTIFY set to off stops the notification", "A failed notification fails the release run and is re-sent without a re-publish".

### Requirement: The cascade reference is pinned to one `.github` `main` SHA and checked on every PR
**Reason**: Split into requirements that each state one behavior.
**Migration**: See "The cascade reference names one full SHA on .github main", "The cascade reference moves only through a pin PR", "wiring-check.sh is a byte-identical copy that changes only with the pin", "The values of core's wiring check live in wiring-check.yaml", "The required CI job and an offline task run the wiring check", "No earlier step or setting of the CI job can reach the wiring step", "The wiring check fails when the notify job differs from the contract shape", "The wiring check fails when a key is read outside its job or Environment", "The wiring check fails on a publish workflow cache or a secrets pass into .github", "The wiring check fails on a loose .github reference or a startup-code variable", "The wiring check fails when a checkout of .github is not pinned", "The wiring check fails in CI when the pinned SHA is off main or the copy differs".

## ADDED Requirements

### Requirement: A published core release notifies catalog_opm and library

After a release of `opmodel.dev/core@v2` is published from `main`, core's release run MUST send an `upstream-released` notification naming core and the release tag to each of its cascade downstreams, catalog_opm and library, and to no other repo: at least one per published release, one per run attempt. A repeat is harmless, because a receiver re-resolves the newest published version itself.

Source: workspace `RELEASING.md`, "Notify after publish"; Phase 3 wiring contract (version 3.1) §4.5.

#### Scenario: A release whose module is published notifies catalog_opm and library

- **WHEN** the release PR for `v2.0.0-beta.3` is merged and the module publish for `v2.0.0-beta.3` succeeds
- **THEN** catalog_opm and library each receive an `upstream-released` dispatch with source `core` and tags `["v2.0.0-beta.3"]`, and cli and opm-operator receive none

#### Scenario: A push to main that cuts no release notifies nobody

- **WHEN** a commit lands on `main` and release-please only opens or updates the release PR
- **THEN** no module is published and no downstream is notified

### Requirement: A v1 maintenance release notifies nobody

A maintenance release of `opmodel.dev/core@v1` from the `v1` branch MUST NOT notify: every downstream pins `@v2`.

Source: workspace `RELEASING.md`, "Notify after publish" and "repository_dispatch"; Phase 3 wiring contract (version 3.1) §4.5 and §4.6.

#### Scenario: A v1 maintenance release notifies nobody

- **WHEN** the release PR on the `v1` branch is merged and a `v1.1.x` patch of `opmodel.dev/core@v1` is published
- **THEN** no downstream is notified, and the `@v2` line's notification is unaffected

### Requirement: The notification starts only after the module publish succeeds

The tag is the release tag release-please created, for example `v2.0.0-beta.3`. The notification MUST start only after the module publish for that tag has succeeded, so a downstream is never told about a version GHCR does not serve. A failed or skipped module publish MUST NOT notify.

Source: workspace `RELEASING.md`, "Notify after publish" and "repository_dispatch"; Phase 3 wiring contract (version 3.1) §4.5 and §4.6.

#### Scenario: A failed module publish notifies nobody

- **WHEN** the module publish for a release fails, for example because GHCR already holds the version
- **THEN** no downstream is notified in that run

### Requirement: The docs bundle publish and the notification do not gate each other

The docs bundle publish MUST NOT gate the notification, and the notification MUST NOT gate the docs bundle publish.

Source: workspace `RELEASING.md`, "Notify after publish" and "repository_dispatch"; Phase 3 wiring contract (version 3.1) §4.5 and §4.6.

#### Scenario: A failed docs bundle publish does not stop the notification

- **WHEN** the module publish succeeds and the docs bundle publish for the same release fails
- **THEN** catalog_opm and library are still notified

### Requirement: The notification payload carries only the source and the release tag

The tag is the release tag release-please created, for example `v2.0.0-beta.3`. The payload MUST carry only the source and the tag; which repos are notified is fixed by the shared `cascade-notify` action, not chosen by core.

Source: workspace `RELEASING.md`, "Notify after publish" and "repository_dispatch"; Phase 3 wiring contract (version 3.1) §4.5 and §4.6.

#### Scenario: The payload names only the source and the tag

- **WHEN** core sends the `upstream-released` notification for the release tag `v2.0.0-beta.3`
- **THEN** the payload carries only the source `core` and the tag, and the shared `cascade-notify` action, not core, fixes which repos are notified

### Requirement: core receives no cascade notification

core MUST have no receiver: no notification from any repo moves a pin in core, and core runs no cascade gates.

Source: workspace `RELEASING.md`, "Notify after publish" and "repository_dispatch"; Phase 3 wiring contract (version 3.1) §4.5 and §4.6.

#### Scenario: A notification from another repo moves no pin in core

- **WHEN** another repo sends a notification to core
- **THEN** no pin in core moves and core runs no cascade gates

### Requirement: The cascade App key is read only in the notify-downstream job

The `opm-cascade` App key MUST be read only in the caller-owned `notify-downstream` job, which MUST declare `environment: cascade` and MUST pass `secrets.CASCADE_APP_PRIVATE_KEY` only as the `private-key` input of the SHA-pinned `cascade-notify` action; that job MUST NOT have a checkout or `run:` of its own, nor `env:`, `container:` or `services:`; a reusable call MUST NOT pass `secrets:` or `secrets: inherit`.

Source: workspace `RELEASING.md`, "The opm-cascade App".

#### Scenario: The cascade key is read in the key-holding job only

- **WHEN** the `opm-cascade` App key is read in core's release workflow
- **THEN** it is read only in the `notify-downstream` job, which declares `environment: cascade` and passes `secrets.CASCADE_APP_PRIVATE_KEY` only as the `private-key` input of the SHA-pinned `cascade-notify` action

#### Scenario: A key-holding job with code of its own does not meet the rule

- **WHEN** the `notify-downstream` job has a checkout or a `run:` of its own, or an `env:`, `container:` or `services:`, or a reusable call passes `secrets:` or `secrets: inherit`
- **THEN** the job does not meet this requirement

### Requirement: The notify job runs in the cascade Environment with a read-only token and never the release key

core's `cascade` Environment MUST limit deployments to `main`. The `notify-downstream` job MUST grant the built-in token no more than read access to contents. The release App's key MUST NOT be used for the notification.

Source: workspace `RELEASING.md`, "Notify after publish", "repository_dispatch", "Stop switches" and "Owner settings", "The opm-cascade App"; Phase 3 wiring contract (version 3.1) §2.2, §2.3, §4.3 and §10.1 item 9.

#### Scenario: The notification never uses the release credentials

- **WHEN** the notification runs
- **THEN** it uses only a token the `cascade-notify` action mints from the `opm-cascade` App key, read in the `notify-downstream` job in the `cascade` Environment, and that job grants read-only contents access and runs no core code

### Requirement: CASCADE_NOTIFY set to off stops the notification

The repo variable `CASCADE_NOTIFY` set to exactly `off` MUST stop core's releases from notifying. Any other value, or no variable, MUST leave the notification on. The switch MUST NOT affect the release or the publish.

Source: workspace `RELEASING.md`, "Notify after publish", "repository_dispatch", "Stop switches" and "Owner settings", "The opm-cascade App"; Phase 3 wiring contract (version 3.1) §2.2, §2.3, §4.3 and §10.1 item 9.

#### Scenario: Notify is switched off

- **WHEN** `CASCADE_NOTIFY` is `off` in core and a release is published
- **THEN** the module and the docs bundle are published as usual, and no downstream is notified

#### Scenario: An unset switch leaves notify on

- **WHEN** core has no `CASCADE_NOTIFY` variable, or it holds any value other than `off`, and a release is published
- **THEN** catalog_opm and library are notified

### Requirement: A failed notification fails the release run and is re-sent without a re-publish

A notification that fails after its retries MUST fail the release run visibly. Re-sending it MUST NOT re-publish the module; re-running the failed job sends the notification again for the same tag.

Source: workspace `RELEASING.md`, "Notify after publish", "repository_dispatch", "Stop switches" and "Owner settings", "The opm-cascade App"; Phase 3 wiring contract (version 3.1) §2.2, §2.3, §4.3 and §10.1 item 9.

#### Scenario: A lost dispatch is recovered without a re-publish

- **WHEN** the notification to library fails after its retries, while the module is already published
- **THEN** the release run is red, catalog_opm has still been notified, and re-running the failed job re-sends the notification for the same tag to both catalog_opm and library without running the module publish again

### Requirement: The cascade reference names one full SHA on .github main

core's cascade reference, the `uses:` of the `cascade-notify` action, MUST name a full 40-character SHA of a commit on `.github` `main`, followed by the comment ` # .github main`, and MUST NOT name a branch or a tag.

Source: `.github` README at `0f9c6ac`, "Pinning and bumps" and "The wiring check"; workspace `RELEASING.md`, "Pinning the cascade code" and "Moving the cascade pin".

#### Scenario: A branch reference is refused

- **WHEN** a PR changes the notify `uses:` to `cascade-notify@main`, or to a short SHA, or changes its comment
- **THEN** the required CI job fails at "Verify the cascade wiring"

### Requirement: The cascade reference moves only through a pin PR

core's cascade reference MUST move only through a pin PR that replaces the SHA and the copy of the wiring check, after `gh api repos/open-platform-model/.github/compare/<SHA>...main --jq .status` prints `identical` or `ahead`.

Source: `.github` README at `0f9c6ac`, "Pinning and bumps" and "The wiring check"; workspace `RELEASING.md`, "Pinning the cascade code" and "Moving the cascade pin".

#### Scenario: A pin bump passes

- **WHEN** a `ci(deps)` pin PR replaces the SHA with another full SHA on `.github` `main`, replaces the wiring check with that SHA's copy, and changes nothing else
- **THEN** the wiring check passes and prints the new SHA
- **THEN** CODEOWNERS requests a code owner's review, because the PR changes `.github/` and `.tasks/`

### Requirement: wiring-check.sh is a byte-identical copy that changes only with the pin

`.tasks/cascade/wiring-check.sh` MUST be a byte-identical copy of `.github/scripts/cascade/wiring-check.sh` at the pinned SHA, and MUST change only with the pin.

Source: Phase 3 wiring contract (version 3.1) §2.4 and §10.1 items 2 and 6, with the supervisor's addendum; owner decisions 24 and 29; `.github` README at `0f9c6ac`, "Pinning and bumps" and "The wiring check"; workspace `RELEASING.md`, "Pinning the cascade code" and "Moving the cascade pin".

#### Scenario: A copy that drifted from the pinned file is refused

- **WHEN** a PR edits `.tasks/cascade/wiring-check.sh`, or moves the pin without replacing the copy
- **THEN** the "Verify the cascade wiring" step fails with `differs from`, after the `compare` check passed

### Requirement: The values of core's wiring check live in wiring-check.yaml

core's values MUST live in `.tasks/cascade/wiring-check.yaml` (`receiver: false`, `env-allow: [CUE_VERSION, CUE_REGISTRY]`, `publish-workflows: [release.yml, branch-publish.yml, docs.yml]`, `ci` job `ci.yml`/`ci`, and notify's `needs`, `if:` and `tag` as `release.yml` has them).

Source: `.github` README at `0f9c6ac`, "Pinning and bumps" and "The wiring check"; workspace `RELEASING.md`, "Pinning the cascade code" and "Moving the cascade pin".

#### Scenario: The values of core are read from wiring-check.yaml

- **WHEN** the wiring check runs in core
- **THEN** core's values (`receiver: false`, `env-allow: [CUE_VERSION, CUE_REGISTRY]`, `publish-workflows: [release.yml, branch-publish.yml, docs.yml]`, the `ci` job `ci.yml`/`ci`, and notify's `needs`, `if:` and `tag` as `release.yml` has them) live in `.tasks/cascade/wiring-check.yaml`

### Requirement: The required CI job and an offline task run the wiring check

The required CI job ("Validate schema") MUST run the wiring check on every PR as the step "Verify the cascade wiring" with `GH_TOKEN: ${{ github.token }}` and `run: bash .tasks/cascade/wiring-check.sh --pin-on-main`, with no `if:`, `continue-on-error`, `shell` or `working-directory`. `task cascade:wiring:check` MUST run the same check offline and MUST stay part of the aggregate `task check`.

Source: `.github` README at `0f9c6ac`, "The wiring check"; Phase 3 wiring contract (version 3.1) §2.4.

#### Scenario: The wiring as built passes

- **WHEN** the required CI job runs on a PR that leaves the notify job as built
- **THEN** the "Verify the cascade wiring" step prints `cascade wiring: ok, .github <SHA> (.github main)` and passes

### Requirement: No earlier step or setting of the CI job can reach the wiring step

The CI workflow's and job's `env` MUST hold only `CUE_*`, `OPM_*`, `REGISTRY` or `IMAGE_NAME` names, the required CI job ("Validate schema") MUST have no `container` or `services`, and every step before the wiring step MUST be an action from another repo at a full SHA with only `id`, `name`, `uses` and `with`.

Source: `.github` README at `0f9c6ac`, "Pinning and bumps" and "The wiring check"; workspace `RELEASING.md`, "Pinning the cascade code" and "Moving the cascade pin".

#### Scenario: A step that could reach the wiring step is refused

- **WHEN** a PR adds a `run:` step before "Verify the cascade wiring", or a `BASH_ENV` or `PATH` key to the CI workflow's or job's `env`
- **THEN** the required CI job fails at "Verify the cascade wiring"

### Requirement: The wiring check fails when the notify job differs from the contract shape

The wiring check MUST fail when the `notify-downstream` job's keys, its one step's keys or input names, its credential inputs (exactly `vars.CASCADE_APP_CLIENT_ID` and `secrets.CASCADE_APP_PRIVATE_KEY`), its `environment`, its `runs-on` (exactly `ubuntu-latest`), its timeout or its `permissions` (exactly `contents: read`) differ from the contract shape.

Source: `.github` README at `0f9c6ac`, "The wiring check"; Phase 3 wiring contract (version 3.1) §2.4.

#### Scenario: Code added to the key-holding job is refused

- **WHEN** a PR adds an `env:`, a second step, a step-level `env:` or `if:`, or a `container:` to `notify-downstream`, or changes its `runs-on`
- **THEN** the required CI job fails at "Verify the cascade wiring"

### Requirement: The wiring check fails when a key is read outside its job or Environment

The wiring check MUST fail when the cascade key is read or `environment: cascade` is declared anywhere else than in the `notify-downstream` job under `.github/workflows/`. The wiring check MUST fail when a job reads `RELEASE_APP_PRIVATE_KEY` without declaring exactly `environment: release`, or a job declares `release` without reading it.

Source: `.github` README at `0f9c6ac`, "The wiring check"; Phase 3 wiring contract (version 3.1) §2.4.

#### Scenario: A release-key reader outside the release Environment is refused

- **WHEN** a PR adds a job that names `secrets.RELEASE_APP_PRIVATE_KEY` without `environment: release`, or declares `environment: release` on a job that does not read it
- **THEN** the required CI job fails at "Verify the cascade wiring"

### Requirement: The wiring check fails on a publish workflow cache or a secrets pass into .github

The wiring check MUST fail when a workflow in `publish-workflows` uses an Actions cache. The wiring check MUST fail when a call into `.github` passes `secrets`.

Source: Phase 3 wiring contract (version 3.1) §2.4 and §10.1 items 2 and 6, with the supervisor's addendum; owner decisions 24 and 29; `.github` README at `0f9c6ac`, "Pinning and bumps" and "The wiring check"; workspace `RELEASING.md`, "Pinning the cascade code" and "Moving the cascade pin".

#### Scenario: A publish workflow with an Actions cache is refused

- **WHEN** a PR makes a workflow in `publish-workflows` use an Actions cache
- **THEN** the wiring check fails

#### Scenario: A call into .github that passes secrets is refused

- **WHEN** a PR makes a call into `.github` pass `secrets`
- **THEN** the wiring check fails

### Requirement: The wiring check fails on a loose .github reference or a startup-code variable

The wiring check MUST fail when a `.github` reference lacks the one full SHA and the `.github main` comment. The wiring check MUST fail when `release.yml`'s workflow-level `env` holds a key other than `CUE_VERSION` and `CUE_REGISTRY`.

Source: `.github` README at `0f9c6ac`, "Pinning and bumps" and "The wiring check"; workspace `RELEASING.md`, "Pinning the cascade code" and "Moving the cascade pin".

#### Scenario: A startup-code variable in the release workflow is refused

- **WHEN** a PR adds `BASH_ENV`, `NODE_OPTIONS` or any other key besides `CUE_VERSION` and `CUE_REGISTRY` to `release.yml`'s workflow-level `env`
- **THEN** the required CI job fails at "Verify the cascade wiring"

#### Scenario: A .github reference without the one full SHA is refused

- **WHEN** a PR makes a `.github` reference lack the one full SHA and the `.github main` comment
- **THEN** the wiring check fails

### Requirement: The wiring check fails when a checkout of .github is not pinned

The wiring check MUST fail when a checkout of `.github` is not `actions/checkout` at a full SHA with exactly `repository`, `ref`, `path` and `persist-credentials: false`.

Source: Phase 3 wiring contract (version 3.1) §2.4 and §10.1 items 2 and 6, with the supervisor's addendum; owner decisions 24 and 29; `.github` README at `0f9c6ac`, "Pinning and bumps" and "The wiring check"; workspace `RELEASING.md`, "Pinning the cascade code" and "Moving the cascade pin".

#### Scenario: A checkout of .github that is not pinned is refused

- **WHEN** a PR adds a checkout of `.github` that is not `actions/checkout` at a full SHA with exactly `repository`, `ref`, `path` and `persist-credentials: false`
- **THEN** the wiring check fails

### Requirement: The wiring check fails in CI when the pinned SHA is off main or the copy differs

The wiring check MUST fail, in CI, when the pinned SHA is not on `.github` `main` or the copy differs from `.github/scripts/cascade/wiring-check.sh` at the pinned SHA.

Source: Phase 3 wiring contract (version 3.1) §2.4 and §10.1 items 2 and 6, with the supervisor's addendum; owner decisions 24 and 29; `.github` README at `0f9c6ac`, "Pinning and bumps" and "The wiring check"; workspace `RELEASING.md`, "Pinning the cascade code" and "Moving the cascade pin".

#### Scenario: A SHA only in a fork of `.github` is refused

- **WHEN** a PR pins a full SHA that GitHub resolves under `open-platform-model/.github` but that is not on its `main`
- **THEN** the "Verify the cascade wiring" step fails on the `compare` check, after every shape matched
