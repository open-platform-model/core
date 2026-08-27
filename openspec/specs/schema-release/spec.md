## Purpose

Defines how a `core` schema release is cut and published: CI-only publication from a reviewed release PR, when a pre-stable break advances the prerelease versus bumps the module major, why a partial tag on the line is never a retarget target, and the coherence, example-evaluation and resolve-after-publish checks a cut MUST pass (change `core-alpha-release`, 2026-08).

## Requirements

### Requirement: The schema is published only by CI, from a reviewed release

A `core` release MUST be produced by merging the release-please PR, which tags the version and runs the `publish-cue` job gated on `release_created == 'true'`. `cue mod publish` MUST NOT be run against a live registry by hand, including to recover from a failed job — a failed publish is debugged and re-run in CI.

A published version is immutable. A tag CI did not build is a tag nobody reviewed, and it cannot be withdrawn.

#### Scenario: A release is cut by merging the release PR

- **WHEN** the accumulated release PR for `v2.0.0-alpha.2` is merged
- **THEN** the tag and GitHub Release are created, and the `publish-cue` job pushes the module

#### Scenario: A failed publish is not repaired by hand

- **WHEN** the `publish-cue` job fails
- **THEN** the failure is fixed and the job re-run, and no local `cue mod publish` is issued against the registry

### Requirement: A pre-stable break defaults to advancing the prerelease, and crossing a major is a separate decision

A breaking schema change on a pre-stable major line MUST either advance the prerelease on that line or bump the module major, and it MUST state in its proposal which it does and why. Advancing the prerelease with the module path unmoved is the **default**, not an absolute.

A change MUST bump the module major when the break is one a consumer cannot absorb by re-reading the same import path: when the meaning of an existing field changes, when values every published artifact declares are refused, or when a derived identity consumers store moves. Pre-stable licence makes staying on the line *permissible*; it does not make it correct.

Crossing a major MUST be deliberate and MUST be stated in the proposal, because it changes every consumer's retarget from a dependency bump into an import rewrite. It requires two edits in the **same** commit: `src/cue.mod/module.cue`'s `module:` line, and a `Release-As: X.0.0-alpha.1` footer forcing the version — `versioning: prerelease` advances the prerelease counter within a major and never crosses one on its own. `cue mod publish` refuses a tag whose major disagrees with the declared module path, so the two cannot land apart.

#### Scenario: An absorbable break advances the prerelease counter

- **WHEN** `feat!:` commits reshape published definitions, no stable `vX.0.0` exists, and consumers can absorb the break by re-reading the same import path
- **THEN** the release is `vX.0.0-alpha.N+1`, the module path is unmoved, and consumers retarget by a dependency bump

#### Scenario: An unabsorbable break bumps the module major

- **WHEN** a change redefines what an existing field means, refuses values every published artifact declares, or moves a derived identity consumers store
- **THEN** the module path moves to the next major, the version is forced to `X.0.0-alpha.1` by a `Release-As:` footer, and the proposal states the import-rewrite cost

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
