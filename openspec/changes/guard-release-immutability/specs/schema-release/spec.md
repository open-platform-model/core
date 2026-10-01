## MODIFIED Requirements

### Requirement: The schema is published only by CI, from a reviewed release

A `core` release MUST be produced by merging the release-please PR, on `main` or on a `release/vX.Y` maintenance branch, which tags the version and runs the `publish-cue` job gated on `release_created == 'true'`. `cue mod publish` MUST NOT be run against a live registry by hand, including to recover from a failed job — a failed publish is debugged and re-run in CI.

A re-run MAY publish only a version the registry still does not hold. Once the registry holds a version, that version MUST NOT be published again, even when it is broken or incomplete: it is superseded by the next version (roll forward), and the run that found it present stays failed.

A published version is immutable. A tag CI did not build is a tag nobody reviewed, and it cannot be withdrawn. This holds for every prerelease type the line carries and for a stable release alike.

Source: `0021:D10:R2`.

#### Scenario: A release is cut by merging the release PR

- **WHEN** the accumulated release PR for the next version on the line (for example `v2.0.0-beta.2`) is merged
- **THEN** the tag and GitHub Release are created, and the `publish-cue` job pushes the module

#### Scenario: A failed publish is not repaired by hand

- **WHEN** the `publish-cue` job fails
- **THEN** the failure is fixed and the job re-run, and no local `cue mod publish` is issued against the registry; the re-run publishes only if the registry still lacks the version, and otherwise fails and the next version is released instead

## ADDED Requirements

### Requirement: A release publishes only a version the registry does not hold

A version-named module tag on GHCR (`vX.Y.Z`, `vX.Y.Z-<type>.N`) always names the bytes first pushed under it. Branch builds (`-0.dev.*`) are outside this requirement and stay mutable.

Before `cue mod publish` runs for a release, CI MUST ask GHCR whether it holds a manifest for `opmodel.dev/core` at the release version, and MUST publish only when the answer is "absent":

- "Present": the job MUST fail before `cue mod publish` and name the version as already published. Recovery is the next version; the tag MUST NOT be moved or re-created, and the version MUST NOT be re-published.
- Any answer other than "present" or "absent" (an auth error, a rate limit, a 5xx, an unreachable registry): the job MUST fail before `cue mod publish` and say the registry state could not be determined. Nothing was pushed, so recovery is re-running the job in CI.

`task publish` MUST publish to a local registry only, whatever `CUE_REGISTRY` the calling shell exports, so a laptop publish cannot write a release version to GHCR.

Source: `0021:D10:R3`.

#### Scenario: A new version is published

- **WHEN** the release PR for `v2.0.0-beta.2` is merged and GHCR returns 404 for that manifest
- **THEN** `cue mod publish v2.0.0-beta.2` runs and the module is published

#### Scenario: A version GHCR already holds is refused

- **WHEN** the `publish-cue` job runs for a version whose manifest GHCR already serves (for example a re-run after `v2.0.0-beta.1` was published)
- **THEN** the job fails before `cue mod publish`, naming the version as already published, the bytes behind it are unchanged, and the fix is releasing the next version

#### Scenario: An inconclusive probe is refused and re-run

- **WHEN** the registry probe gets an answer other than 200 or 404 (an auth error, a rate limit, a 5xx, no connection)
- **THEN** the job fails before `cue mod publish`, says the registry state could not be determined, and a later re-run that finds the version absent publishes it

#### Scenario: A laptop publish never reaches GHCR

- **WHEN** a developer with `CUE_REGISTRY` set to the canonical GHCR mapping runs `task publish VERSION=vX.Y.Z`
- **THEN** the publish targets `localhost:5000`, and fails rather than falling back to GHCR when no local registry is running

### Requirement: A released minor is maintained on a lazily cut release branch

A released minor that needs a fix `main` cannot ship receives it on a `release/vX.Y` branch (for example `release/v2.0`). The branch MUST be created only by the `cut-release-branch` workflow, from the highest `vX.Y.*` tag, and only after that minor is stable: during a prerelease line no release branch is cut, and fixes go forward on `main` as the next `-<type>.N`. The PR the workflow opens into the new branch sets `versioning: always-bump-patch` and `prerelease: false`, so every release from the branch is the next patch of that minor and no commit type can claim a minor or major.

The release workflow MUST run on pushes to `release/**` with release-please targeting that branch, and MUST publish through the same `publish-cue` job and guards as `main`. A change reaches a release branch only through a PR. A release branch MUST NOT be deleted or force-pushed; its end of life is documented, not enacted. A docs-only change on a release branch (a hidden commit type) cuts no release, and the docs site pins its commit SHA.

#### Scenario: A backport ships as the next patch

- **WHEN** `release/v2.0` exists at `v2.0.3` and a `fix:` backport PR is merged into it
- **THEN** release-please opens a release PR for `2.0.4` against that branch, and merging it tags `v2.0.4` and publishes it through the probe-guarded `publish-cue` job

#### Scenario: A feature commit on a release branch still releases a patch

- **WHEN** a commit typed `feat:` is merged into `release/v2.0` at `v2.0.4`
- **THEN** the next release from that branch is `v2.0.5`, never `v2.1.0`, because the branch's config pins `always-bump-patch`

#### Scenario: A docs-only fix on a release branch releases nothing

- **WHEN** a `docs:` commit correcting a released page is merged into `release/v2.0`
- **THEN** no release PR is opened, no tag is created, and the docs site pins the merge commit's SHA

#### Scenario: No release branch is cut during beta

- **WHEN** the line is still a prerelease (`v2.0.0-beta.N`) and a fix is needed
- **THEN** no `release/v2.0` is cut; the fix lands on `main` and ships as the next `-beta.N`

#### Scenario: A release branch is never removed

- **WHEN** a release branch's minor reaches end of life
- **THEN** the branch stays, and its end of life is recorded in documentation rather than by deleting it
