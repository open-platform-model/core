## Context

core has four workflows: `ci.yml` (required "Validate schema", on PRs, pushes to `main` and dispatch), `docs.yml` (docs-kit's reusable `publish.yml`), `release.yml` (release-please, `publish-cue`, `publish-docs`, `notify-downstream`) and `branch-publish.yml` (a `-dev` tag for every non-`main` push). The repository's default `GITHUB_TOKEN` is `write` today; decision 30 flips it to `read` after this change merges, so every job must name what it uses first. No `src/*.cue` file and no construct in `.tasks/spec-tracked.txt` is touched.

## Goals / Non-Goals

**Goals:** the release key readable only from a `main` job in the `release` Environment; every job's token scoped to its steps; no write token for bot heads; CODEOWNERS and Dependabot in place for the ruleset and settings the supervisor applies next.

**Non-Goals:** the wiring check and the `.github` pin (wave 2); rulesets, repository settings, Environments and secrets (supervisor and owner); docs-kit's `publish.yml` internals.

## Decisions

### D1. Per-job grants

Each workflow sets `permissions: {}` at the top, and each job lists exactly what its steps use. A job-level block replaces the workflow-level one entirely, so the top-level `{}` only matters for a job added later without its own block: it gets nothing rather than the repository default.

| Workflow / job | Grant | Used by |
| --- | --- | --- |
| `ci.yml` / `ci` | `contents: read` | checkout, `git fetch origin <base>` |
| `branch-publish.yml` / `publish` | `contents: read`, `packages: write` | checkout with tags; `docker login ghcr.io` with `GITHUB_TOKEN`, then `cue mod publish` |
| `release.yml` / `release-please` | `actions: write`, `contents: read` | `gh workflow run ci.yml` with `GITHUB_TOKEN` (`contents: read` because gh may read the workflow file to check its inputs). release-please runs with the App token, and the job checks nothing out. |
| `release.yml` / `publish-cue` | `contents: read`, `packages: write` | checkout of the tag; `publish-probe.sh` (anonymous GHCR token); GHCR login and `cue mod publish` |
| `release.yml` / `publish-docs` | unchanged (`contents: read`, `packages: write`, `id-token: write`) | docs-kit `publish.yml` release mode |
| `release.yml` / `notify-downstream` | unchanged (`contents: read`; the wiring check requires exactly this) | the cascade action mints its own App token |
| `docs.yml` | unchanged (`{}` at top, per-job already) | |

`release.yml`'s old workflow-level `contents: write` and `pull-requests: write` were never used by `GITHUB_TOKEN`: release-please has acted as the release App since the App was introduced. Dropping them also removes the `pull-requests: write` token that, once approvals are required, could approve a PR (the "Actions may approve PRs" finding).

### D2. `environment: release` on `release-please` only

The key is read in one step, `Mint the release App token`. Only its job gets `environment: release`. `release.yml` runs only on pushes to `main`, which the Environment's branch policy admits; `branch-publish.yml`, `ci.yml` and `docs.yml` never read the key. An Environment with no secret of that name falls back to the organization secret, so the job is unchanged until the owner moves the key (decision 29).

### D3. Bot heads and Actions cache

`branch-publish.yml` holds `packages: write` and runs the branch's own `Taskfile.yml` and `.tasks/`. The release App pushes `release-please--branches--main--components--core`, and App pushes do start workflows. That head's tree is `main` plus release-please's changelog and manifest edits, so the realistic risk is small, but the plan's rule is that no bot head runs with a write token before a human looks, and a dev tag of a release PR has no use. `branches-ignore` gains `release-please--**`, `deps/cascade` (core has no receiver today; the entry costs nothing and holds if it gains one) and `dependabot/**` (read-only token there, so the job could only fail).

## Research & Decisions

### Actions cache in the publishing workflows
**Context**: the plan forbids Actions cache in any workflow that publishes, because a cache entry written by a branch run can be restored into a `main` publish run.
**Explored**: `grep` of all four workflows for `cache`, `actions/cache` and `type=gha` (no hits); the bundled `dist/index.js` of `cue-lang/setup-cue@a93fa358` and `go-task/setup-task@3be4020d` searched for `restoreCache`, `saveCache`, `ACTIONS_CACHE_URL` and `_apis/artifactcache` (no hits; both use `@actions/tool-cache`, which is the runner's local directory and does not survive the job on GitHub-hosted runners).
**Decision**: no edit; the requirement is recorded in the `workflow-security` spec.
**Rationale**: nothing to remove, and a spec line makes a later addition a visible deviation.

### The in-tree wiring check
**Context**: the plan says not to touch `.tasks/cascade/wiring-check.sh` unless it refuses a needed edit.
**Explored**: the script checks `notify-downstream`'s keys and permissions, the cascade key's readers, the `cascade` Environment's jobs, `.github` references and `release.yml`'s workflow `env` keys. It does not read workflow-level `permissions`, `environment: release` or `branch-publish.yml`.
**Decision**: unchanged; `task cascade:wiring:check` passes on the branch.

## Risks / Trade-offs

- **A missed grant fails a job only after the default flips.** While the repository default is still `write`, a job-level block already narrows the token, so a missing grant shows up at once in this PR's own runs (`ci.yml`) or at the next release (`release.yml`). `release.yml` cannot be exercised before merge; D1's table is the review aid. If `gh workflow run` fails, the step already ends in `|| echo`, so the release still proceeds and only the dispatched CI is missing.
- **Deployment records.** Each push to `main` creates a `release` deployment. That is noise in the Deployments view, not a gate: the Environment has no reviewers.
