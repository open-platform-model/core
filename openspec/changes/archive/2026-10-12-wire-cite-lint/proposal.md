## Why

Core now cites an enhancement only as its id beside a reason in words (change `align-enhancement-store`). Nothing yet stops a later PR from adding a decision number or a lone id. The org shares one check, `enh cite-lint`, built from the enhancements repo at one commit and wrapped in the reusable workflow `cite-lint.yml` of `.github`. Core must run it locally and in CI like every other repo.

## What Changes

- `Taskfile.yml`: a task `cite-lint` runs `enh cite-lint --root .` through `go run` at the commit `e0335b2ec44e659c0191bc3523d79d17f26f8e7d`, with no excludes. The base tree has 0 findings.
- `.github/workflows/ci.yml`: a job `cite-lint` calls `open-platform-model/.github/.github/workflows/cite-lint.yml` at `.github` commit `2b66da51fede4332969c324b069012632d8edea9`, comment `# .github main`, on the existing `pull_request` and `push` to `main` triggers. The call holds only `name`, `permissions` (`contents: read`), `uses` and `with` (`paths: .`).
- The one other `.github` reference (`release.yml`, the `cascade-notify` step) and the copy `.tasks/cascade/wiring-check.sh` move from `0f9c6ac2` to `2b66da51` in one `ci(deps)` commit. `.tasks/cascade/wiring-check.yaml` declares `{file: ci.yml, kind: cite-lint}`.
- `AGENTS.md`: the task table lists `task cite-lint`.

Between the two pins `.github` changed `wiring-check.sh` (new kind `cite-lint`), `wiring/lib.sh` (accepts the name `opm-controller` beside `opm-operator`; the target list for a core release is unchanged: `catalog_opm library`), `lib/prtext.sh`, `lib/release.sh` and added `cite-lint.yml`. Core's notify step inputs do not change.

The task and the CI call both use no excludes, so no list needs a shared place. A later exclude must be added in both.

No schema or CUE changes. Every commit is a hidden type, so no release is cut.

## Enhancement

None.

## Capabilities

### New Capabilities

- `cite-lint`: the comment rule runs locally and in CI at one pinned tool commit.

### Modified Capabilities

None.

## Impact

- `Taskfile.yml`, `.github/workflows/ci.yml`, `.github/workflows/release.yml` (pin), `.tasks/cascade/`, `AGENTS.md`.
- If the pin of `.github` is wrong, the "Validate schema" job fails at the wiring step; roll back with a pin PR.
