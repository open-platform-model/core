## ADDED Requirements

### Requirement: core publishes one docs bundle

The repository SHALL declare one docs-kit project, `core`, in `docs-kit.cue`: placed in a site version's `/docs/` tree, owning `reference/definitions/`, versioned from tags with the prefix `v`, built from a `cue-definitions` source over `./src` (files matching `*_pins.cue` skipped) and a `markdown` source over `docs/site`. The bundle SHALL carry the authored pages under `docs/site/` and the generated definitions reference together (docs-kit DESIGN decision 20). `task docs:bundle` SHALL build it into `out/core/` and `task docs:bundle:check` SHALL build and lint it without publishing.

#### Scenario: The bundle holds both kinds of page

- **WHEN** `task docs:bundle` runs on a clean checkout
- **THEN** `out/core/content/` holds `concepts/modules-and-instances.md` (authored) and `reference/definitions/components.md` (generated), and `out/core/manifest.json` names the placement `docs` owning `reference/definitions/`

#### Scenario: A committed generated page that is not excluded collides

- **WHEN** `docs/site/reference/definitions/components.md` is committed and the `markdown` source does not exclude `reference/definitions/`
- **THEN** `task docs:bundle:check` fails, naming the page both sources write

### Requirement: Every core release publishes its docs bundle

`release.yml` SHALL run a `publish-docs` job that calls docs-kit's `publish.yml` with `project: core`, `mode: release` and the release's tag, in the workflow run of the push that merged the release PR, only when release-please created a release and only after `publish-cue` succeeded.

#### Scenario: A release publishes its bundle

- **WHEN** the release PR for `v2.0.0-beta.2` merges and `publish-cue` succeeds
- **THEN** `publish-docs` publishes `ghcr.io/open-platform-model/docs/core` with the tags the release names (C4), signed by core's workflow

#### Scenario: A failed module publish publishes no docs

- **WHEN** `publish-cue` fails
- **THEN** `publish-docs` is skipped, and `docs.yml` dispatched with `mode: release` and the tag is the recovery

### Requirement: Pull requests check the bundle and main publishes edge

`.github/workflows/docs.yml` SHALL run `publish.yml` in `check` mode on every pull request (permissions `contents: read`, `packages: read`), in `edge` mode on every push to `main`, and on `workflow_dispatch` in the `release` or `revision` mode with a `tag` and, for `revision`, a `fix` commit; the publishing jobs SHALL hold only `contents: read`, `packages: write` and `id-token: write`, and the workflow SHALL declare `permissions: {}` at the top.

#### Scenario: A pull request that breaks the bundle fails its check

- **WHEN** a pull request adds an exported definition to `src/` without placing or excluding it in `docs-kit.cue`
- **THEN** the `Docs / check` job fails, naming the definition, and nothing is published

#### Scenario: A merge to main publishes edge

- **WHEN** a commit lands on `main`
- **THEN** the `edge` job publishes that commit as the `edge` build of `docs/core`

### Requirement: The docs-kit release is pinned once per form and the forms agree

`.opm-docs-version` SHALL hold one docs-kit release tag, and every `open-platform-model/docs-kit/.github/workflows/publish.yml@<ref>` under `.github/workflows/` SHALL name that same tag, never a SHA (docs-kit C5, C9). `task docs:pins:check` SHALL refuse a disagreement offline, and `task docs:bundle:check` SHALL run it first.

#### Scenario: A half-moved pin is refused

- **WHEN** `.opm-docs-version` names `v0.4.0` and `docs.yml` still names `publish.yml@v0.3.0`
- **THEN** `task docs:pins:check` fails, listing the stale ref and telling the author to move both in one PR

#### Scenario: Agreeing pins pass

- **WHEN** both forms name `v0.4.0`
- **THEN** `task docs:pins:check` passes
