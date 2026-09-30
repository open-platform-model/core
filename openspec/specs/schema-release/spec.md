## Purpose

Defines how a `core` schema release is cut and published: CI-only publication from a reviewed release PR, why a break on a prerelease line advances the prerelease and only a stable line crosses a major, how a line changes prerelease type or goes GA, why a partial tag on the line is never a retarget target, and the coherence, example-evaluation and resolve-after-publish checks a cut MUST pass (change `core-alpha-release`, 2026-08).

## Requirements

### Requirement: The schema is published only by CI, from a reviewed release

A `core` release MUST be produced by merging the release-please PR, which tags the version and runs the `publish-cue` job gated on `release_created == 'true'`. `cue mod publish` MUST NOT be run against a live registry by hand, including to recover from a failed job — a failed publish is debugged and re-run in CI.

A published version is immutable. A tag CI did not build is a tag nobody reviewed, and it cannot be withdrawn. This holds for every prerelease type the line carries and for a stable release alike.

#### Scenario: A release is cut by merging the release PR

- **WHEN** the accumulated release PR for the next version on the line (for example `v2.0.0-beta.2`) is merged
- **THEN** the tag and GitHub Release are created, and the `publish-cue` job pushes the module

#### Scenario: A failed publish is not repaired by hand

- **WHEN** the `publish-cue` job fails
- **THEN** the failure is fixed and the job re-run, and no local `cue mod publish` is issued against the registry

### Requirement: A break on a prerelease line advances the prerelease, and only a stable line crosses a major

A major line with no stable `vX.0.0` release is a prerelease line. Its prerelease type is the `prerelease-type` in `release-please-config.json`; `opmodel.dev/core@v2` is on type `beta`. The rules below write the type as `<type>` because they hold for whichever type the line carries.

From its first beta, a prerelease line is on the path to GA. A breaking schema change of any kind MUST land on it as a `feat!:` commit whose `BREAKING CHANGE:` footer is the migration note the CHANGELOG shows. It advances the prerelease counter, from `vX.0.0-<type>.N` to `vX.0.0-<type>.N+1`, and it MUST NOT move the module path to a new major. The line MUST NOT cross a major before GA: a change on it MUST NOT edit `src/cue.mod/module.cue`'s `module:` line or carry a `Release-As:` footer naming a new major. While the line is a prerelease, every releasable commit (`fix:`, `feat:`, `feat!:`) advances the counter; minor and patch bumps apply only once the line is stable.

The stable lines built on core keep the normal SemVer rule, where a break is a new major: `opmodel.dev/catalogs/opm` and the module fleets. A core break that would force a `catalogs/opm` major MUST NOT land without owner sign-off, and its proposal MUST record that sign-off.

Crossing a major is a stable-line act, taken only after GA. It is never implied by a break; it is a deliberate, separately decided act, and a proposal that takes it MUST state it and why. The case for it is a break a consumer cannot absorb by re-reading the same import path: when the meaning of an existing field changes, when values every published artifact declares are refused, or when a derived identity consumers store moves. Crossing changes every consumer's retarget from a dependency bump into an import rewrite. It requires two edits in the **same** commit on `main`: `src/cue.mod/module.cue`'s `module:` line, and a `Release-As:` footer in that commit's final message forcing the new major's first version (`X.0.0-<type>.1` when the new major opens as a prerelease line) — `versioning: prerelease` advances the prerelease counter within a major and never crosses one on its own. `cue mod publish` refuses a tag whose major disagrees with the declared module path, so the two cannot land apart.

#### Scenario: An absorbable break advances the prerelease counter

- **WHEN** a `feat!:` commit whose `BREAKING CHANGE:` footer carries the migration note reshapes published definitions and no stable `vX.0.0` exists
- **THEN** the release is `vX.0.0-<type>.N+1` (for example `v2.0.0-beta.2` after `v2.0.0-beta.1`), the module path is unmoved, the CHANGELOG shows the migration note, and consumers retarget by a dependency bump, because on a prerelease line the migration note is how every break is absorbed

#### Scenario: An unabsorbable break bumps the module major

- **WHEN** on a stable line (after GA) a change redefines what an existing field means, refuses values every published artifact declares, or moves a derived identity consumers store, and its proposal records the separate decision to cross a major
- **THEN** the module path moves to the next major, the version is forced to the new major's first version by a `Release-As:` footer in the final message of the same commit, and the proposal states the import-rewrite cost

#### Scenario: A break during beta does not move the module path

- **WHEN** a `feat!:` commit lands on the prerelease line, whatever kind of break it carries
- **THEN** the `module:` line is unchanged, the release is the next `-<type>.N` on the same major, and no `Release-As:` footer is written

#### Scenario: A module line change during beta is refused

- **WHEN** a change on a prerelease line edits the `module:` line in `src/cue.mod/module.cue`, or carries a `Release-As:` footer naming a new major
- **THEN** it is not merged; the break lands instead as a `feat!:` commit with a migration note on the same major, and a major crossing waits for GA

#### Scenario: A break without a migration note is refused in review

- **WHEN** a commit that removes or renames a definition, or tightens a published constraint, is typed `feat:` or `fix:`, or is typed `feat!:` with no `BREAKING CHANGE:` footer
- **THEN** it is not merged until it carries the `feat!:` type and a footer a consumer can migrate from, because the CHANGELOG is the only migration channel the line promises

#### Scenario: A break that would force a catalogs/opm major waits for sign-off

- **WHEN** a core break would leave `opmodel.dev/catalogs/opm` unable to absorb it without moving its own module path to a new major
- **THEN** the change does not land until the owner signs off, and its proposal records the sign-off and the catalog's migration cost

#### Scenario: The declared major and the tag cannot disagree

- **WHEN** a release is tagged at a major the `module:` line does not declare
- **THEN** `cue mod publish` refuses it, and the release fails rather than publishing a mislabelled artifact

#### Scenario: Rollback across a major is an import rewrite

- **WHEN** a consumer needs to reverse a retarget that crossed a major
- **THEN** it restores the previous import path as well as the version pin, and the previous major stays resolvable indefinitely, because a published tag names fixed bytes permanently

### Requirement: A partial tag on the line is not a retarget target

A tag that carries only some of the changes a cut is defined to publish MUST NOT be retargeted to by any consumer. Publication makes a tag resolvable; it does not make it complete.

`v2.0.0-alpha.1` is exactly this case: it was published by the major bump and carries `core-identity-shape` alone, without the contract keying, platform surface or identity package. A resolvable partial tag is more hazardous than no tag, because nothing in the registry distinguishes it from a complete one.

#### Scenario: A consumer re-pins to a partial alpha

- **WHEN** a consumer re-pins to an alpha published before every slice of the cut has landed
- **THEN** it compiles against an incomplete schema, and the failure surfaces as missing constructs rather than as a version error

### Requirement: The published schema is internally coherent before it is tagged

Before a release is cut, `SPEC.md` MUST describe one schema: an invariant stated in more than one section MUST be stated identically, category claims MUST agree with the sections they classify, every cross-reference MUST resolve to a name that exists, and no section MUST describe behaviour a landed change replaced.

Inventory checking is not coherence checking. `task spec:check` verifies that tracked constructs have sections and that sections name live constructs; it cannot detect two sections disagreeing.

#### Scenario: A stale cross-reference blocks the cut

- **WHEN** a `SPEC.md` section refers to a field renamed or deleted by a landed change
- **THEN** the release is not cut until it is corrected, even though `task spec:check` passes

#### Scenario: A design problem found during the pass is not resolved in the release

- **WHEN** the coherence pass surfaces a design inconsistency rather than an editorial one
- **THEN** it is raised as a new change, and the release waits

### Requirement: Every worked example evaluates against the shipped schema

Every illustrative shape in `SPEC.md`, in `docs/`, and in the authoring doc comments inside `src/*.cue` MUST be evaluated against the schema being published, not reviewed by reading.

A stale example in a normative document is a false statement about a published contract, and the stale ones look correct.

#### Scenario: An example carrying a superseded shape is caught

- **WHEN** a `SPEC.md` example declares a module path in a form the current schema refuses
- **THEN** evaluation fails and the example is corrected before the tag is cut

### Requirement: The published artifact is verified to resolve

After publication, the released version MUST be verified by resolving it from a tree that did not build it and evaluating a minimal artifact in the new shape.

#### Scenario: A scratch consumer compiles against the new release

- **WHEN** a fresh tree adds `opmodel.dev/core@v2` at the published version and evaluates a minimal `#Module`
- **THEN** it resolves and evaluates, confirming the artifact is complete as published rather than only as built

### Requirement: A line changes prerelease type through a forced carrier commit and goes stable through a visible one

Changing `prerelease-type` in `release-please-config.json` MUST land together with a `Release-As:` footer that names the line's first prerelease of the new type (`X.0.0-<type>.1`, for example `2.0.0-beta.1`), written in the final footer block of the commit message that lands on `main`. release-please keeps the existing label when only the type changes, and a change made of hidden-type commits alone opens no release PR. A footer on an inner commit of a squashed PR does not count; only the squash commit's own message is read.

The forced version MUST NOT be written as a `release-as` key in `release-please-config.json`, which stays in force for every later release, and `.release-please-manifest.json` MUST NOT be edited by hand. The release PR the footer opens MUST be read before it is merged, and merged only when its title names the forced version.

GA drops the suffix: `prerelease: false` in `release-please-config.json` plus a visible carrier commit on `main`, either a releasable type or a `Release-As: X.0.0` footer. No force is needed for GA: with `prerelease: false`, any releasable commit proposes `X.0.0`.

#### Scenario: A type flip with a forced first version cuts the first beta

- **WHEN** the squash commit that changes `prerelease-type` from `alpha` to `beta` ends with a `Release-As: 2.0.0-beta.1` footer and `.release-please-manifest.json` holds `2.0.0-alpha.13`
- **THEN** release-please opens `chore(main): release 2.0.0-beta.1`, merging it publishes `v2.0.0-beta.1`, and the next releasable commit proposes `2.0.0-beta.2`

#### Scenario: A type flip without the footer cuts nothing new

- **WHEN** `prerelease-type` changes but no commit on `main` carries a `Release-As:` footer
- **THEN** a change of hidden-type commits opens no release PR, a releasable commit proposes the old label's next counter (for example `2.0.0-alpha.14`), and that release PR is not merged

#### Scenario: GA drops the suffix

- **WHEN** `prerelease` is set to `false` and a visible carrier commit (a releasable type, or a `Release-As: X.0.0` footer) lands on `main`
- **THEN** release-please proposes `X.0.0` with no prerelease suffix, and from then on a break is a new major
