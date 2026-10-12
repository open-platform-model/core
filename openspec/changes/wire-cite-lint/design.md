## Context

`.github` provides `cite-lint.yml` (reusable) and a wiring-check kind `cite-lint` that checks the call shape. The local task must run the same tool commit.

## Decisions

- **A separate job `cite-lint` in `ci.yml`, not a step of `ci`.** A reusable workflow is called at job level. `ci.yml` already has the right triggers (`push` to `main`, `pull_request`, `workflow_dispatch`). The job is not part of the "Validate schema" required job; making it required is the owner's (org ruleset) and is out of scope.
- **The `.github` pin moves for all references together.** The wiring check refuses two different SHAs. So the cascade-notify pin moves with the new call in the same PR, but in its own `ci(deps)` commit first.
- **No excludes.** `enh cite-lint` over the tree reports 0 findings. `.claude/`, `agent-swarm/`, `CHANGELOG.md` and the CUE caches are skipped by the tool's own walk.
- **`go run` at a commit, not a Go dependency.** Core has no Go. The task needs only the Go toolchain on the path; `task check` stays free of Go, so `cite-lint` is not part of it. CI runs it through the reusable workflow.
- **Same tool commit in two places.** The workflow holds it as the `enh-ref` default; the task holds it inline in its command. A bump of the `.github` pin brings the new workflow default; the task variable is moved by hand in the same PR. A comment in the Taskfile names this.
