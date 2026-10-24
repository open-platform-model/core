## Why

The release cascade security pass shipped its `.github` side as `.github` PR 12 (squash `7b9ad1bea132f7a3f053a5db61ac3933b59ee226` on `main`): a bounded `cascade-publish`, pinned tool downloads, a resolver that refuses tags off `main`, and one canonical wiring check that every product repo copies byte for byte. core still pins `cascade-notify` to `2376ffa` and runs its own older, core-only `wiring-check.sh`, which knows nothing of the release-key Environment rule (owner decision 29), the no-cache rule for publishing workflows, or the imposter-commit check. A `.github` change reaches core only through a pin PR, so until this lands core runs none of it.

## What Changes

- **Move the pin.** `release.yml`'s `notify-downstream` step names `cascade-notify@7b9ad1bea132f7a3f053a5db61ac3933b59ee226 # .github main`. It is core's only `.github` reference (core has no receiver and no `cascade-task.yml`). `gh api repos/open-platform-model/.github/compare/7b9ad1b...main --jq .status` prints `identical`.
- **Adopt the canonical wiring check.** `.tasks/cascade/wiring-check.sh` becomes a byte-identical copy of `.github/scripts/cascade/wiring-check.sh` at that SHA, and `.tasks/cascade/wiring-check.yaml` carries core's values from the `.github` README table: `receiver: false`, `env-allow: [CUE_VERSION, CUE_REGISTRY]`, `publish-workflows: [release.yml, branch-publish.yml, docs.yml]`, `ci: {workflow: ci.yml, job: ci}`, and notify's `needs`, `if:` and `tag` read from core's own `release.yml`.
- **Check the pin is on `.github` `main` in CI.** The required job's "Verify the cascade wiring" step runs `bash .tasks/cascade/wiring-check.sh --pin-on-main` with `GH_TOKEN: ${{ github.token }}`, the exact shape the canonical check requires. `task cascade:wiring:check` stays the offline local entry and stays in `task check`.
- **Dependabot cooldown.** The `github-actions` entry waits seven days (`cooldown: {default-days: 7}`) before proposing an action release.
- `AGENTS.md` "Release & publishing" describes the canonical check, its config and the `--pin-on-main` step.

No caller shape changes: core's notify job already matches the README's notify shape, and the new `release` Environment rule matches what `harden-release-workflows` built (only `release-please` reads the release key and declares `environment: release`).

Nothing under `src/` changes; the published CUE is byte-identical. Every commit is a hidden type (`ci:`, `docs:`), so no release is cut.

No enhancement backs this change; it is wave 2 of the release cascade security pass (owner decisions 28-31). It has no `enhancement.yaml`.

## Capabilities

### New Capabilities

### Modified Capabilities

- `release-cascade`: the cascade reference moves with the canonical wiring check, and the required CI step also checks the pinned SHA is on `.github` `main`.
- `workflow-security`: Dependabot waits seven days before proposing a third-party action release.

## Impact

- `.github/workflows/release.yml` (pin), `.github/workflows/ci.yml` (wiring step), `.github/dependabot.yml` (cooldown), `.tasks/cascade/wiring-check.sh` (canonical copy), `.tasks/cascade/wiring-check.yaml` (new), `AGENTS.md`.
- The required "Validate schema" job now calls the GitHub API once (the `compare` call) with its read-only token; `.github` is public, so `contents: read` is enough.
