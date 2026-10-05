## Context

The controller repo `opm-operator` becomes `opm-controller` (owner decisions recorded in the controller repo's ADR-019 and the new enhancement entry amending 0006). core carries no code that names it, only prose and comments. This design fixes which "operator" words move.

## Goals / Non-Goals

**Goals:** every mention of the OPM product in core's live text says "controller"; every source citation names a path that exists after the rename.

**Non-Goals:** no schema change; no edit to `CHANGELOG.md` or `openspec/changes/archive/**`; no edit to `.tasks/cascade/wiring-check.sh` (hashed `.github` copy).

## Decisions

- The substitution is by exact pattern, never a bare word rule. Patterns, in order: `opm-operator` to `opm-controller`; `cli/internal/cmd/operator/` to `cli/internal/cmd/controller/`; `cli/internal/operator/` to `cli/internal/controller/`; `opm operator install` to `opm controller install`; `GateOperatorVersionCeiling` to `GateControllerVersionCeiling`; then, per line after review, the product noun (`an operator` to `a controller`, `operator` to `controller`, `Operator` to `Controller`).
- Lines where "operator" is not the product stay: the human role ("a platform operator", "an operator upgrading a catalog"), Kubernetes-generic ("an operator's bundle", "the set of operators installed in a cluster"), and "Helm operators". SPEC.md's `#ModuleInstance` definition ("what an operator, CI pipeline, or controller actually renders") names the human who runs the render, so it becomes "a platform operator, a CI pipeline, or the controller". SPEC.md's "a deployer on a cluster with no operator" names OPM's own product (the skip-unprovided proposal says "a cluster without the operator, where no provider can ever be registered"), so it becomes "no controller".
- `opm-operator/internal/controller/...` becomes `opm-controller/internal/controller/...`: the controller repo keeps its `internal/controller` package (controller-runtime reconcilers).
- `src/*.cue` edits are comment-only. Doc comments are replayed into `src/INDEX.md` and the definitions reference, so `task generate:index` is re-run; the CI co-update gate is already satisfied because `SPEC.md` changes in the same PR, so the `Spec-Impact: none` line in the PR body is optional (carried anyway as a record).

## Risks / Trade-offs

- [Citation names a cli symbol before the cli renames it] The cli's `GateOperatorVersionCeiling` and `internal/cmd/operator/` are assumed to move to `GateControllerVersionCeiling` and `internal/cmd/controller/` in the cli rename change. Mitigation: this change merges after the cli change; recheck both names at the cutover.

## Research & Decisions

### Which hits move
**Context**: core has about 100 live lines with "operator", not all of them the product.
**Explored**: the workspace rename inventory (core section) and a per-line `git grep -nIi operator` over the tree, excluding `CHANGELOG.md` and the OpenSpec archive.
**Decision**: per-line review with exact patterns, as listed under Decisions.
**Rationale**: a bare word rule would rewrite the human platform operator and Kubernetes-generic operators, which keep their meaning.

### Anchors
**Context**: retitled headings change their anchors.
**Explored**: grep across the workspace for links to `who-owns-an-instance/#`, `versions/#`, `modules-and-instances/#` and `application-and-platform-models/#` anchors containing "operator".
**Decision**: retitle freely; there are no inbound anchor links.
**Rationale**: the rename takes no redirects; nothing breaks.
