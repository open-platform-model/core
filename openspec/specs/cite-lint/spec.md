# cite-lint Specification

## Purpose
TBD - created by archiving change wire-cite-lint. Update Purpose after archive.

## Requirements

### Requirement: A local task runs the comment rule at one tool commit

Core MUST have a task `cite-lint` that runs `enh cite-lint --root .` from `github.com/open-platform-model/enhancements/tools/enh` at a full 40-hex commit, never a branch, a tag or `latest`. Each exclude of the task MUST carry a comment that gives its reason.

#### Scenario: The tree follows the comment rule

- **WHEN** `task cite-lint` runs on a tree whose Go and CUE comments cite enhancements by id beside a reason
- **THEN** it prints 0 findings and exits 0

#### Scenario: A decision number is refused

- **WHEN** a CUE comment cites an enhancement by a decision number
- **THEN** `task cite-lint` fails and prints `path:line: rule: message`

### Requirement: CI calls the shared cite-lint workflow as a plain call

`.github/workflows/ci.yml` MUST hold a job `cite-lint` that calls `open-platform-model/.github/.github/workflows/cite-lint.yml` at the one full `.github` SHA of every other `.github` reference in the repo, with the comment ` # .github main`, on `pull_request` and on `push` to `main`. The job MUST have only `name`, `permissions` (exactly `contents: read`), `uses` and `with`, and MUST pass no secret. Each exclude in `with` MUST carry a comment that gives its reason.

#### Scenario: A decision number fails the PR

- **WHEN** a PR adds a CUE comment that cites an enhancement by a decision number
- **THEN** the "Cite lint" job fails

### Requirement: The wiring check declares the cite-lint call

`.tasks/cascade/wiring-check.yaml` MUST declare the call as `{file: ci.yml, kind: cite-lint}` in `extra-references`.

#### Scenario: A call that differs in shape is refused

- **WHEN** a PR gives the call job a `secrets` key, a second permission or a step
- **THEN** the "Verify the cascade wiring" step fails
