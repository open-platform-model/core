## ADDED Requirements

### Requirement: The schema is published only by CI, from a reviewed release

A `core` release MUST be produced by merging the release-please PR, which tags the version and runs the `publish-cue` job gated on `release_created == 'true'`. `cue mod publish` MUST NOT be run against a live registry by hand, including to recover from a failed job — a failed publish is debugged and re-run in CI.

A published version is immutable. A tag CI did not build is a tag nobody reviewed, and it cannot be withdrawn.

#### Scenario: A release is cut by merging the release PR

- **WHEN** the accumulated release PR for `v1.0.0-alpha.4` is merged
- **THEN** the tag and GitHub Release are created, and the `publish-cue` job pushes the module

#### Scenario: A failed publish is not repaired by hand

- **WHEN** the `publish-cue` job fails
- **THEN** the failure is fixed and the job re-run, and no local `cue mod publish` is issued against the registry

### Requirement: A break inside the alpha line does not move the module path

While `opmodel.dev/core@v1` has published no stable `v1.0.0`, a breaking schema change MUST land as a prerelease advance on the `@v1` line rather than as a module-major bump. The module path MUST NOT move.

This holds only while the line is pre-stable. Once `v1.0.0` ships, a breaking revision bumps the module major.

#### Scenario: A breaking change advances the alpha counter

- **WHEN** `feat!:` commits reshape published definitions and no stable `v1.0.0` exists
- **THEN** the release is `v1.0.0-alpha.N+1`, and consumers retarget by a dependency bump rather than an import rewrite

#### Scenario: Rollback is a re-pin

- **WHEN** a consumer needs to reverse a retarget before it has merged its own changes
- **THEN** re-pinning to the previous alpha restores the prior behaviour, with no import path change

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

- **WHEN** a fresh tree adds `opmodel.dev/core@v1` at the published version and evaluates a minimal `#Module`
- **THEN** it resolves and evaluates, confirming the artifact is complete as published rather than only as built
