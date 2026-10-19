## MODIFIED Requirements

### Requirement: The schema is published only by CI, from a reviewed release

A `core` release MUST be produced by merging the release-please PR, which tags the version and runs the `publish-cue` job gated on `release_created == 'true'`. `cue mod publish` MUST NOT be run against a live registry by hand, including to recover from a failed job: a failed publish is debugged and re-run in CI.

Source: enhancement 0021 ("Release tags are immutable").

#### Scenario: A release is cut by merging the release PR

- **WHEN** the accumulated release PR for the next version on the line (for example `v2.0.0-beta.2`) is merged
- **THEN** the tag and GitHub Release are created, and the `publish-cue` job pushes the module

#### Scenario: A failed publish is not repaired by hand

- **WHEN** the `publish-cue` job fails
- **THEN** the failure is fixed and the job re-run, and no local `cue mod publish` is issued against the registry; the re-run publishes only if the registry still lacks the version, and otherwise fails and the next version is released instead

### Requirement: The published schema is internally coherent before it is tagged

Before a release is cut, `SPEC.md` MUST describe one schema: an invariant stated in more than one section MUST be stated identically, category claims MUST agree with the sections they classify, every cross-reference MUST resolve to a name that exists, and no section MUST describe behaviour a landed change replaced.

Inventory checking is not coherence checking.

#### Scenario: A stale cross-reference blocks the cut

- **WHEN** a `SPEC.md` section refers to a field renamed or deleted by a landed change
- **THEN** the release is not cut until it is corrected, even though `task spec:check` passes

#### Scenario: A design problem found during the pass is not resolved in the release

- **WHEN** the coherence pass surfaces a design inconsistency rather than an editorial one
- **THEN** it is raised as a new change, and the release waits

#### Scenario: Inventory checking does not detect disagreeing sections

- **WHEN** `task spec:check` runs against a `SPEC.md` whose sections disagree
- **THEN** `task spec:check` verifies that tracked constructs have sections and that sections name live constructs; it cannot detect two sections disagreeing

## REMOVED Requirements

### Requirement: A break on a prerelease line advances the prerelease, and only a stable line crosses a major
**Reason**: Split into requirements that each state one behavior.
**Migration**: See "A breaking schema change on a prerelease line lands as a feat! commit with a migration note", "A breaking schema change advances the prerelease counter and not the module path", "A prerelease line does not cross a major before GA", "A core break that would force a catalogs/opm major needs owner sign-off", "Crossing a major is a stable-line act that is decided separately", "Crossing a major takes two edits in the same commit on main", "A consumer retargets a crossing by an import rewrite, and the tag cannot disagree with the declared major".

### Requirement: A line changes prerelease type through a forced carrier commit and goes stable through a visible one
**Reason**: Split into requirements that each state one behavior.
**Migration**: See "A change of prerelease type lands together with a forced first version", "The forced version comes from the squash commit footer alone and its release PR is read", "GA drops the suffix through a visible carrier commit".

### Requirement: A release publishes only a version the registry does not hold
**Reason**: Split into requirements that each state one behavior.
**Migration**: See "A release is published only when GHCR answers that the version is absent", "A version GHCR already holds is not published again", "An inconclusive registry answer stops the publish", "A re-run publishes nothing when the tag exists and the registry lacks the version", "task publish publishes to a local registry only".

## ADDED Requirements

### Requirement: Once the registry holds a version it is not published again

A re-run MAY publish only a version the registry still does not hold. Once the registry holds a version, that version MUST NOT be published again, even when it is broken or incomplete: it is superseded by the next version (roll forward), and the run that found it present stays failed.

Source: enhancement 0021 ("Release tags are immutable").

#### Scenario: A re-run finds the version present

- **WHEN** a re-run finds that the registry already holds the version, even a broken or incomplete one
- **THEN** the version is not published again, the next version supersedes it (roll forward), and the run that found it present stays failed

### Requirement: A published version is immutable

A published version MUST be immutable. A tag CI did not build is a tag nobody reviewed, and it cannot be withdrawn. This holds for every prerelease type the line carries and for a stable release alike.

Source: enhancement 0021 ("Release tags are immutable").

#### Scenario: A published version never changes

- **WHEN** a version has been published, of any prerelease type the line carries or of a stable release
- **THEN** the version is immutable, because a tag CI did not build is a tag nobody reviewed and it cannot be withdrawn

### Requirement: A breaking schema change on a prerelease line lands as a feat! commit with a migration note

A major line with no stable `vX.0.0` release is a prerelease line. Its prerelease type is the `prerelease-type` in `release-please-config.json`; `opmodel.dev/core@v2` is on type `beta`. The rules below write the type as `<type>` because they hold for whichever type the line carries.

From its first beta, a prerelease line is on the path to GA. A breaking schema change of any kind MUST land on it as a `feat!:` commit whose `BREAKING CHANGE:` footer is the migration note the CHANGELOG shows.

#### Scenario: A break without a migration note is refused in review

- **WHEN** a commit that removes or renames a definition, or tightens a published constraint, is typed `feat:` or `fix:`, or is typed `feat!:` with no `BREAKING CHANGE:` footer
- **THEN** it is not merged until it carries the `feat!:` type and a footer a consumer can migrate from, because the CHANGELOG is the only migration channel the line promises

#### Scenario: A break lands as a feat! commit with a BREAKING CHANGE footer

- **WHEN** a breaking schema change of any kind lands on a prerelease line
- **THEN** it lands as a `feat!:` commit whose `BREAKING CHANGE:` footer is the migration note the CHANGELOG shows

### Requirement: A breaking schema change advances the prerelease counter and not the module path

A breaking schema change of any kind advances the prerelease counter, from `vX.0.0-<type>.N` to `vX.0.0-<type>.N+1`, and it MUST NOT move the module path to a new major. While the line is a prerelease, every releasable commit (`fix:`, `feat:`, `feat!:`) advances the counter; minor and patch bumps apply only once the line is stable.

#### Scenario: An absorbable break advances the prerelease counter

- **WHEN** a `feat!:` commit whose `BREAKING CHANGE:` footer carries the migration note reshapes published definitions and no stable `vX.0.0` exists
- **THEN** the release is `vX.0.0-<type>.N+1` (for example `v2.0.0-beta.2` after `v2.0.0-beta.1`), the module path is unmoved, the CHANGELOG shows the migration note, and consumers retarget by a dependency bump, because on a prerelease line the migration note is how every break is absorbed

#### Scenario: A fix commit advances the counter on a prerelease line

- **WHEN** a releasable `fix:` commit lands on a line that is a prerelease
- **THEN** it advances the counter, and minor and patch bumps apply only once the line is stable

### Requirement: A prerelease line does not cross a major before GA

The prerelease line MUST NOT cross a major before GA: a change on it MUST NOT edit `src/cue.mod/module.cue`'s `module:` line or carry a `Release-As:` footer naming a new major.

#### Scenario: A break during beta does not move the module path

- **WHEN** a `feat!:` commit lands on the prerelease line, whatever kind of break it carries
- **THEN** the `module:` line is unchanged, the release is the next `-<type>.N` on the same major, and no `Release-As:` footer is written

#### Scenario: A module line change during beta is refused

- **WHEN** a change on a prerelease line edits the `module:` line in `src/cue.mod/module.cue`, or carries a `Release-As:` footer naming a new major
- **THEN** it is not merged; the break lands instead as a `feat!:` commit with a migration note on the same major, and a major crossing waits for GA

### Requirement: A core break that would force a catalogs/opm major needs owner sign-off

The stable lines built on core keep the normal SemVer rule, where a break is a new major: `opmodel.dev/catalogs/opm` and the module fleets. A core break that would force a `catalogs/opm` major MUST NOT land without owner sign-off, and its proposal MUST record that sign-off.

#### Scenario: A break that would force a catalogs/opm major waits for sign-off

- **WHEN** a core break would leave `opmodel.dev/catalogs/opm` unable to absorb it without moving its own module path to a new major
- **THEN** the change does not land until the owner signs off, and its proposal records the sign-off and the catalog's migration cost

### Requirement: Crossing a major is a stable-line act that is decided separately

Crossing a major is a stable-line act, taken only after GA. It is never implied by a break; it is a deliberate, separately decided act, and a proposal that takes it MUST state it and why. The case for it is a break a consumer cannot absorb by re-reading the same import path: when the meaning of an existing field changes, when values every published artifact declares are refused, or when a derived identity consumers store moves.

#### Scenario: An unabsorbable break bumps the module major

- **WHEN** on a stable line (after GA) a change redefines what an existing field means, refuses values every published artifact declares, or moves a derived identity consumers store, and its proposal records the separate decision to cross a major
- **THEN** the module path moves to the next major, the version is forced to the new major's first version by a `Release-As:` footer in the final message of the same commit, and the proposal states the import-rewrite cost

### Requirement: Crossing a major takes two edits in the same commit on main

Crossing a major MUST require two edits in the **same** commit on `main`: `src/cue.mod/module.cue`'s `module:` line, and a `Release-As:` footer in that commit's final message forcing the new major's first version (`X.0.0-<type>.1` when the new major opens as a prerelease line); `versioning: prerelease` advances the prerelease counter within a major and never crosses one on its own.

#### Scenario: A crossing carries both edits in one commit

- **WHEN** a stable line crosses a major
- **THEN** the same commit on `main` edits the `module:` line of `src/cue.mod/module.cue` and carries a `Release-As:` footer in its final message that forces the new major's first version

### Requirement: A consumer retargets a crossing by an import rewrite, and the tag cannot disagree with the declared major

Crossing changes every consumer's retarget from a dependency bump into an import rewrite. `cue mod publish` MUST refuse a tag whose major disagrees with the declared module path, so the two cannot land apart.

#### Scenario: The declared major and the tag cannot disagree

- **WHEN** a release is tagged at a major the `module:` line does not declare
- **THEN** `cue mod publish` refuses it, and the release fails rather than publishing a mislabelled artifact

#### Scenario: Rollback across a major is an import rewrite

- **WHEN** a consumer needs to reverse a retarget that crossed a major
- **THEN** it restores the previous import path as well as the version pin, and the previous major stays resolvable indefinitely, because a published tag names fixed bytes permanently

### Requirement: A change of prerelease type lands together with a forced first version

Changing `prerelease-type` in `release-please-config.json` MUST land together with a `Release-As:` footer that names the line's first prerelease of the new type (`X.0.0-<type>.1`, for example `2.0.0-beta.1`), written in the final footer block of the commit message that lands on `main`. release-please keeps the existing label when only the type changes, and a change made of hidden-type commits alone opens no release PR.

#### Scenario: A type flip with a forced first version cuts the first beta

- **WHEN** the squash commit that changes `prerelease-type` from `alpha` to `beta` ends with a `Release-As: 2.0.0-beta.1` footer and `.release-please-manifest.json` holds `2.0.0-alpha.13`
- **THEN** release-please opens `chore(main): release 2.0.0-beta.1`, merging it publishes `v2.0.0-beta.1`, and the next releasable commit proposes `2.0.0-beta.2`

#### Scenario: A type flip without the footer cuts nothing new

- **WHEN** `prerelease-type` changes but no commit on `main` carries a `Release-As:` footer
- **THEN** a change of hidden-type commits opens no release PR, a releasable commit proposes the old label's next counter (for example `2.0.0-alpha.14`), and that release PR is not merged

### Requirement: The forced version comes from the squash commit footer alone and its release PR is read

A footer on an inner commit of a squashed PR does not count; only the squash commit's own message is read.

The forced version MUST NOT be written as a `release-as` key in `release-please-config.json`, which stays in force for every later release, and `.release-please-manifest.json` MUST NOT be edited by hand. The release PR the footer opens MUST be read before it is merged, and merged only when its title names the forced version.

#### Scenario: A footer on an inner commit does not count

- **WHEN** a footer `Release-As: 2.0.0-beta.1` sits on an inner commit of a squashed PR and not in the squash commit's own message
- **THEN** the footer does not count, because only the squash commit's own message is read

### Requirement: GA drops the suffix through a visible carrier commit

GA MUST drop the suffix: `prerelease: false` in `release-please-config.json` plus a visible carrier commit on `main`, either a releasable type or a `Release-As: X.0.0` footer. No force is needed for GA: with `prerelease: false`, any releasable commit proposes `X.0.0`.

#### Scenario: GA drops the suffix

- **WHEN** `prerelease` is set to `false` and a visible carrier commit (a releasable type, or a `Release-As: X.0.0` footer) lands on `main`
- **THEN** release-please proposes `X.0.0` with no prerelease suffix, and from then on a break is a new major

### Requirement: A release is published only when GHCR answers that the version is absent

A version-named module tag on GHCR (`vX.Y.Z`, `vX.Y.Z-<type>.N`) always names the bytes first pushed under it. Branch builds (`-0.dev.*`) are outside this requirement.

Before `cue mod publish` runs for a release, CI MUST ask GHCR whether it holds a manifest for `opmodel.dev/core` at the release version, and MUST publish only when the answer is "absent".

Source: enhancement 0021 ("Release tags are immutable").

#### Scenario: A new version is published

- **WHEN** the release PR for `v2.0.0-beta.2` is merged and GHCR returns 404 for that manifest
- **THEN** `cue mod publish v2.0.0-beta.2` runs and the module is published

### Requirement: A version GHCR already holds is not published again

Before `cue mod publish` runs for a release, CI MUST ask GHCR whether it holds a manifest for `opmodel.dev/core` at the release version, and MUST publish only when the answer is "absent".

"Present": the job MUST fail before `cue mod publish` and name the version as already published. Recovery is the next version; the tag MUST NOT be moved or re-created, and the version MUST NOT be re-published.

Branch builds (`-0.dev.*`) are outside this requirement.

#### Scenario: A version GHCR already holds is refused

- **WHEN** the `publish-cue` job runs for a version whose manifest GHCR already serves (for example a re-run after `v2.0.0-beta.1` was published)
- **THEN** the job fails before `cue mod publish`, naming the version as already published, the bytes behind it are unchanged, and the fix is releasing the next version

### Requirement: An inconclusive registry answer stops the publish

Before `cue mod publish` runs for a release, CI MUST ask GHCR whether it holds a manifest for `opmodel.dev/core` at the release version, and MUST publish only when the answer is "absent".

Any answer other than "present" or "absent" (an auth error, a rate limit, a 5xx, an unreachable registry): the job MUST fail before `cue mod publish` and say the registry state could not be determined. Nothing was pushed, so recovery is re-running the job in CI.

#### Scenario: An inconclusive probe is refused and re-run

- **WHEN** the registry probe gets an answer other than 200 or 404 (an auth error, a rate limit, a 5xx, no connection)
- **THEN** the job fails before `cue mod publish`, says the registry state could not be determined, and a later re-run that finds the version absent publishes it

### Requirement: A re-run publishes nothing when the tag exists and the registry lacks the version

When the tag exists, the registry lacks the version and no release PR is pending (release-please failed after creating the release), a re-run publishes nothing; the recovery MUST be the next version.

Source: enhancement 0021 ("Release tags are immutable").

#### Scenario: A re-run after release-please failed publishes nothing

- **WHEN** the tag exists, the registry lacks the version and no release PR is pending because release-please failed after creating the release
- **THEN** a re-run publishes nothing and the recovery is the next version

### Requirement: task publish publishes to a local registry only

`task publish` MUST publish to a local registry only, whatever `CUE_REGISTRY` the calling shell exports, so a laptop publish cannot write a release version to GHCR.

Source: enhancement 0021 ("Release tags are immutable").

#### Scenario: A laptop publish never reaches GHCR

- **WHEN** a developer with `CUE_REGISTRY` set to the canonical GHCR mapping runs `task publish VERSION=vX.Y.Z`
- **THEN** the publish targets `localhost:5000`, and fails rather than falling back to GHCR when no local registry is running
