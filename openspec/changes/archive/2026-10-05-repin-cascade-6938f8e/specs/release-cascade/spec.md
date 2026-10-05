## MODIFIED Requirements

### Requirement: The cascade reference is pinned to one `.github` `main` SHA and checked on every PR

core's cascade reference, the `uses:` of the `cascade-notify` action, MUST name a full 40-character SHA of a commit on `.github` `main`, followed by the comment ` # .github main`, and MUST NOT name a branch or a tag. It MUST move only through a pin PR that replaces the SHA and the copy of the wiring check, after `gh api repos/open-platform-model/.github/compare/<SHA>...main --jq .status` prints `identical` or `ahead`.

`.tasks/cascade/wiring-check.sh` MUST be a byte-identical copy of `.github/scripts/cascade/wiring-check.sh` at the pinned SHA, and MUST change only with the pin; core's values MUST live in `.tasks/cascade/wiring-check.yaml` (`receiver: false`, `env-allow: [CUE_VERSION, CUE_REGISTRY]`, `publish-workflows: [release.yml, branch-publish.yml, docs.yml]`, `ci` job `ci.yml`/`ci`, and notify's `needs`, `if:` and `tag` as `release.yml` has them). The required CI job ("Validate schema") MUST run it on every PR as the step "Verify the cascade wiring" with `GH_TOKEN: ${{ github.token }}` and `run: bash .tasks/cascade/wiring-check.sh --pin-on-main`, with no `if:`, `continue-on-error`, `shell` or `working-directory`; the CI workflow's and job's `env` MUST hold only `CUE_*`, `OPM_*`, `REGISTRY` or `IMAGE_NAME` names, the job MUST have no `container` or `services`, and every step before the wiring step MUST be an action from another repo at a full SHA with only `id`, `name`, `uses` and `with`. `task cascade:wiring:check` MUST run the same check offline and MUST stay part of the aggregate `task check`.

The check MUST fail when the `notify-downstream` job's keys, its one step's keys or input names, its credential inputs (exactly `vars.CASCADE_APP_CLIENT_ID` and `secrets.CASCADE_APP_PRIVATE_KEY`), its `environment`, its `runs-on` (exactly `ubuntu-latest`), its timeout or its `permissions` (exactly `contents: read`) differ from the contract shape; when the cascade key is read or `environment: cascade` is declared anywhere else under `.github/workflows/`; when a job reads `RELEASE_APP_PRIVATE_KEY` without declaring exactly `environment: release`, or a job declares `release` without reading it; when a workflow in `publish-workflows` uses an Actions cache; when a call into `.github` passes `secrets`; when a `.github` reference lacks the one full SHA and the `.github main` comment; when `release.yml`'s workflow-level `env` holds a key other than `CUE_VERSION` and `CUE_REGISTRY`; when a checkout of `.github` is not `actions/checkout` at a full SHA with exactly `repository`, `ref`, `path` and `persist-credentials: false`; and, in CI, when the pinned SHA is not on `.github` `main` or the copy differs from `.github/scripts/cascade/wiring-check.sh` at the pinned SHA.

Source: Phase 3 wiring contract (version 3.1) §2.4 and §10.1 items 2 and 6, with the supervisor's addendum; owner decisions 24 and 29; `.github` README at `6938f8e`, "Pinning and bumps" and "The wiring check"; workspace `RELEASING.md`, "Pinning the cascade code" and "Moving the cascade pin".

#### Scenario: The wiring as built passes

- **WHEN** the required CI job runs on a PR that leaves the notify job as built
- **THEN** the "Verify the cascade wiring" step prints `cascade wiring: ok, .github <SHA> (.github main)` and passes

#### Scenario: A branch reference is refused

- **WHEN** a PR changes the notify `uses:` to `cascade-notify@main`, or to a short SHA, or changes its comment
- **THEN** the required CI job fails at "Verify the cascade wiring"

#### Scenario: Code added to the key-holding job is refused

- **WHEN** a PR adds an `env:`, a second step, a step-level `env:` or `if:`, or a `container:` to `notify-downstream`, or changes its `runs-on`
- **THEN** the required CI job fails at "Verify the cascade wiring"

#### Scenario: A startup-code variable in the release workflow is refused

- **WHEN** a PR adds `BASH_ENV`, `NODE_OPTIONS` or any other key besides `CUE_VERSION` and `CUE_REGISTRY` to `release.yml`'s workflow-level `env`
- **THEN** the required CI job fails at "Verify the cascade wiring"

#### Scenario: A pin bump passes

- **WHEN** a `ci(deps)` pin PR replaces the SHA with another full SHA on `.github` `main`, replaces the wiring check with that SHA's copy, and changes nothing else
- **THEN** the wiring check passes and prints the new SHA
- **THEN** CODEOWNERS requests a code owner's review, because the PR changes `.github/` and `.tasks/`

#### Scenario: A SHA only in a fork of `.github` is refused

- **WHEN** a PR pins a full SHA that GitHub resolves under `open-platform-model/.github` but that is not on its `main`
- **THEN** the "Verify the cascade wiring" step fails on the `compare` check, after every shape matched

#### Scenario: A release-key reader outside the release Environment is refused

- **WHEN** a PR adds a job that names `secrets.RELEASE_APP_PRIVATE_KEY` without `environment: release`, or declares `environment: release` on a job that does not read it
- **THEN** the required CI job fails at "Verify the cascade wiring"

#### Scenario: A copy that drifted from the pinned file is refused

- **WHEN** a PR edits `.tasks/cascade/wiring-check.sh`, or moves the pin without replacing the copy
- **THEN** the "Verify the cascade wiring" step fails with `differs from`, after the `compare` check passed

#### Scenario: A step that could reach the wiring step is refused

- **WHEN** a PR adds a `run:` step before "Verify the cascade wiring", or a `BASH_ENV` or `PATH` key to the CI workflow's or job's `env`
- **THEN** the required CI job fails at "Verify the cascade wiring"
