## ADDED Requirements

### Requirement: The release App key is read only by a main job in the release Environment

A job that reads `secrets.RELEASE_APP_PRIVATE_KEY` MUST declare `environment: release`, and no other job SHALL declare that Environment. The `release` Environment admits only `main`, so the key is never available to a run on any other ref. In core the only such job is `release.yml`'s `release-please`.

#### Scenario: The release-please job mints the App token on main

- **WHEN** a push to `main` runs `release.yml`
- **THEN** the `release-please` job runs in the `release` Environment and mints the release App token from `secrets.RELEASE_APP_PRIVATE_KEY`

#### Scenario: A branch workflow cannot read the release key

- **WHEN** a workflow run on a branch other than `main` declares `environment: release` to read the key
- **THEN** GitHub refuses to start the job, because the Environment's branch policy admits only `main`

#### Scenario: A job that does not mint the token holds no release Environment

- **WHEN** a reviewer reads `release.yml`
- **THEN** `publish-cue`, `publish-docs` and `notify-downstream` declare no `environment: release`

### Requirement: Every workflow declares least-privilege token permissions

Every workflow file under `.github/workflows/` MUST declare a top-level `permissions:` block that grants nothing (`{}`), and every job MUST declare its own `permissions:` naming only the scopes its steps use. No workflow SHALL depend on the repository's default `GITHUB_TOKEN` permissions, so the default can be read-only without breaking a job.

#### Scenario: The required CI job runs with a read-only token

- **WHEN** a pull request runs `ci.yml`'s "Validate schema" job
- **THEN** its token holds `contents: read` and nothing else, whatever the repository default is

#### Scenario: The release workflow grants write per job

- **WHEN** `release.yml` runs
- **THEN** only `publish-cue` and `publish-docs` hold `packages: write`, only `release-please` holds `actions: write`, and no job holds `contents: write` or `pull-requests: write`

#### Scenario: A job added without permissions gets none

- **WHEN** a new job without a `permissions:` block is added to a core workflow
- **THEN** it inherits the workflow's empty block and its token can read nothing, so the missing grant shows up as a failing step rather than a silent write token

### Requirement: A publishing workflow uses no Actions cache

A workflow that publishes an artifact (`release.yml`, `branch-publish.yml`, `docs.yml`) MUST NOT restore or save a GitHub Actions cache: no `actions/cache`, no `cache:` input on a setup action that would enable one, and no `type=gha` build cache. Setup actions that keep only the runner's local tool cache are allowed.

#### Scenario: The publishing workflows hold no cache step

- **WHEN** a reviewer searches `release.yml`, `branch-publish.yml` and `docs.yml` for `actions/cache`, a `cache:` input and `type=gha`
- **THEN** there is no hit

#### Scenario: A cache added to a publish job is a deviation

- **WHEN** a change adds `actions/cache` to `publish-cue`
- **THEN** it contradicts this requirement and needs its own change to this spec first

### Requirement: Bot-pushed heads never run with a write token

`branch-publish.yml`, which runs the branch's own Taskfile with `packages: write`, MUST NOT run for the bot-pushed heads `release-please--**`, `deps/cascade` and `dependabot/**`. Every other non-`main` branch still publishes its `-dev` tag.

#### Scenario: A release PR update publishes no dev tag

- **WHEN** the release App pushes `release-please--branches--main--components--core`
- **THEN** "Branch publish" does not run

#### Scenario: A feature branch still publishes its dev tag

- **WHEN** a maintainer pushes `feat/some-change`
- **THEN** "Branch publish" runs and publishes `opmodel.dev/core` at the branch's `-dev` version

### Requirement: The release machinery has code owners

`.github/CODEOWNERS` MUST name code owners for `/.github/`, `/.tasks/`, `/Taskfile*.yml`, `/release-please-config.json` and `/.release-please-manifest.json`, so the `main` ruleset's code-owner review covers every file that decides what a release runs or with which credentials. It SHALL name only paths that exist in core.

#### Scenario: A workflow edit asks for a code owner

- **WHEN** a pull request changes `.github/workflows/release.yml`
- **THEN** GitHub requests a review from the code owners listed for `/.github/`

#### Scenario: A schema-only edit asks for no code owner

- **WHEN** a pull request changes only `src/*.cue` and `SPEC.md`
- **THEN** CODEOWNERS requests no review

### Requirement: Dependabot moves third-party actions and never the OPM pins

`.github/dependabot.yml` MUST keep the `github-actions` ecosystem up to date, and MUST ignore `open-platform-model/docs-kit*` and `open-platform-model/.github*`, whose references move only through their own pin PRs.

#### Scenario: A third-party action release opens a bump

- **WHEN** `actions/checkout` publishes a new release
- **THEN** Dependabot opens a `ci`-prefixed PR moving its SHA pin

#### Scenario: A cascade pin is not bumped by Dependabot

- **WHEN** `.github` `main` moves past the SHA core pins for `cascade-notify`
- **THEN** Dependabot opens no PR for it; the pin moves only through a `ci(deps)` pin PR
