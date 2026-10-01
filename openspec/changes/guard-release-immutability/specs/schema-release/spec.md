## ADDED Requirements

### Requirement: A release publishes only a version the registry does not hold, from the commit its tag names

A release tag and the module version it names are immutable: no tag under `refs/tags/` is moved, deleted or re-created, and a version-named module tag on GHCR (`vX.Y.Z`, `vX.Y.Z-<type>.N`) is never overwritten. Branch builds (`-0.dev.*`) are outside this requirement and stay mutable.

Before `cue mod publish` runs for a release, CI MUST verify two things and MUST NOT publish unless both hold:

- The release tag's peeled commit on the remote, and the commit the publish checks out, both equal the commit release-please released (its `sha` output).
- GHCR answers that it holds no manifest for `opmodel.dev/core` at the release version. A probe that cannot prove absence (any answer other than "present" or "absent") MUST refuse, never proceed.

A refused release is recovered only by releasing the next version. The tag MUST NOT be moved or re-created, the version MUST NOT be re-published, and the refused run stays failed.

`task publish` MUST publish to a local registry only, whatever `CUE_REGISTRY` the calling shell exports, so a laptop publish cannot write a release version to GHCR.

#### Scenario: A new version is published

- **WHEN** the release PR for `v2.0.0-beta.2` is merged, the tag `v2.0.0-beta.2` points at the release commit, and GHCR returns 404 for that manifest
- **THEN** `cue mod publish v2.0.0-beta.2` runs and the module is published

#### Scenario: A version GHCR already holds is refused

- **WHEN** the `publish-cue` job runs for a version whose manifest GHCR already serves (for example a re-run after `v2.0.0-beta.1` was published)
- **THEN** the job fails before `cue mod publish`, naming the version as already published, and the bytes behind it are unchanged

#### Scenario: An inconclusive probe is refused

- **WHEN** the registry probe gets an answer other than 200 or 404 (an auth error, a rate limit, a 5xx)
- **THEN** the job fails before `cue mod publish` and says the registry state could not be determined

#### Scenario: A release attached to a stale tag is refused

- **WHEN** a tag named `v2.0.0-beta.2` already existed at a different commit, and release-please created the release on it
- **THEN** the release run fails at the tag-SHA assertion, naming the tag's commit and the release commit, `publish-cue` does not publish, and recovery is the next release rather than a tag move

#### Scenario: A laptop publish never reaches GHCR

- **WHEN** a developer with `CUE_REGISTRY` set to the canonical GHCR mapping runs `task publish VERSION=vX.Y.Z`
- **THEN** the publish targets `localhost:5000`, and fails rather than falling back to GHCR when no local registry is running
