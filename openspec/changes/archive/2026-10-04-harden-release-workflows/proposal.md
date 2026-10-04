## Why

The 2026-10-04 security pass over the release cascade found that core's workflows lean on permissive repository defaults and on review that nothing enforces:

- `release.yml`'s `release-please` job reads `secrets.RELEASE_APP_PRIVATE_KEY`, an organization secret visible to every workflow on every branch. That key belongs to the only actor that may bypass the tag-creation ruleset (findings GOV-2 and the missed "release App key is an org secret" finding).
- `ci.yml` declares no `permissions:`, so its PR-tree code runs with the repository default token, which is `write` today (findings N4, GOV-3, and the missed "required CI jobs run PR-tree code with a write-all token" finding). `release.yml` grants `contents`, `pull-requests`, `packages` and `actions` write to every job at workflow level.
- `branch-publish.yml` runs branch code with `packages: write` on every non-`main` push, including the bot-pushed `release-please--*` head, before any human has looked at it.
- No `CODEOWNERS` exists, so the `main` ruleset cannot ask for a code owner's review of the release machinery (GOV-1, CAS-R1). No Dependabot config keeps the SHA-pinned third-party actions current (GOV-4).

The owner decided (items 28-30 of the 2026-10-04 security decisions): the release key moves into a `main`-only Environment `release` in every repo that reads it (the supervisor created core's, branch policy `main`, `can_admins_bypass: false`); `main` will require one approval plus code-owner review; and the repository's default token will flip to read-only once every workflow declares its own permissions. This change does core's side of those three decisions. The supervisor applies the rulesets and repository settings after it merges.

## What Changes

- **The release key needs the `release` Environment.** `release.yml`'s `release-please` job, the only job that reads `secrets.RELEASE_APP_PRIVATE_KEY`, declares `environment: release`. No other job declares it. Until the owner moves the secret into the Environment, an Environment without the secret falls back to the organization secret, so the job keeps working when this merges.
- **Every workflow declares least-privilege permissions.** All four workflows carry `permissions: {}` at the top level and grant each job exactly what its steps use:
  - `ci.yml` job `ci`: `contents: read` (checkout and `git fetch`).
  - `branch-publish.yml` job `publish`: `contents: read`, `packages: write` (the GHCR login for `cue mod publish`).
  - `release.yml` job `release-please`: `actions: write` and `contents: read`, for `gh workflow run ci.yml`. release-please itself acts with the App token, never `GITHUB_TOKEN`.
  - `release.yml` job `publish-cue`: `contents: read`, `packages: write`.
  - `publish-docs`, `notify-downstream` and all of `docs.yml` already declare their own and are unchanged.
- **Bot heads never publish a dev tag.** `branch-publish.yml` ignores `release-please--**`, `deps/cascade` and `dependabot/**` in addition to `main`. The first two are bot-written heads (the release App and, should core ever gain a receiver, the cascade App); Dependabot pushes run with a read-only token, so the job would only fail there.
- **No Actions cache in a publishing workflow.** Verified, not changed: no core workflow uses `actions/cache`, a `cache:` input or a `type=gha` cache, and the two setup actions (`cue-lang/setup-cue`, `go-task/setup-task`) use only the runner's local tool cache (design D3). The requirement is written down so a later edit cannot add one unnoticed.
- **`.github/CODEOWNERS`** names `/.github/`, `/.tasks/`, `/Taskfile*.yml`, `/release-please-config.json` and `/.release-please-manifest.json` (owners emil-jacero and orvis98). core has no `/.cascade-frozen` and no `/hack/`, so those lines are left out.
- **`.github/dependabot.yml`** covers `github-actions` weekly with the `ci` prefix, ignoring `open-platform-model/docs-kit*` (moves with `.opm-docs-version` in one PR) and `open-platform-model/.github*` (moves only through a `ci(deps)` pin PR). The `join-release-cascade` change deliberately added no Dependabot config (contract §10.1 item 7); the security pass's binding plan supersedes that, and the two ignores keep both pins out of its reach.
- `AGENTS.md` "Release & publishing" records the `release` Environment, the per-job permissions rule and the CODEOWNERS file.

Nothing under `src/` changes. The published CUE is byte-identical, so under Principle I this is neither MAJOR, MINOR nor PATCH, relies on no beta break licence and forces no `catalogs/opm` major. Every commit is a hidden type (`ci:`, `docs:`), so the change cuts no release.

Not touched, by plan: `.tasks/cascade/wiring-check.sh` and the `.github` pin (wave 2 replaces both with the canonical script and a new SHA). The current wiring check does not object to any edit here: it inspects only `notify-downstream`, the cascade key's readers and `release.yml`'s workflow `env`.

No enhancement backs this change; it implements owner decisions 28-30 of the release cascade security pass. It has no `enhancement.yaml`.

## Capabilities

### New Capabilities

- `workflow-security`: what core's GitHub Actions workflows may hold and when: the release key only in a `main`-only `release` Environment job, an explicit least-privilege `permissions:` in every workflow, no Actions cache where something is published, no write token for bot-pushed heads, code-owner review for the release machinery, and Dependabot for third-party actions only.

### Modified Capabilities

None. `schema-release` and `release-cascade` keep their requirements; this change narrows the credentials the jobs they describe run with, not what those jobs do.

## Impact

- **Downstream consumers** (`library`, `catalog_opm`, `cli`, `opm-operator`, `modules`): none. No published artifact changes.
- **core's release run**: the `release-please` job now records a deployment to the `release` Environment on every push to `main`. Its branch policy admits only `main`, which is the only ref `release.yml` runs on.
- **core's PRs**: unchanged checks. `ci.yml` runs with a read-only token; none of its steps writes.
- **Branch pushes**: a `release-please--*`, `deps/cascade` or `dependabot/*` push no longer starts "Branch publish". Every other branch still publishes its dev tag.
- **Supervisor follow-ups (not in this change)**: the `main` ruleset's approval and code-owner settings (decision 28), the repository settings (decision 30: default token read-only, Actions may not approve PRs, SHA pinning required, secret scanning, push protection, Dependabot alerts), and the owner moving `RELEASE_APP_PRIVATE_KEY` into the `release` Environment (decision 29).
