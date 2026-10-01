## Why

The owner ruled on 2026-10-01 that release tags are immutable: no tag under `refs/tags/` is ever moved, deleted or re-created, a broken release is fixed by releasing the next version, and a version-named registry tag (`vX.Y.Z` on GHCR) is never overwritten. The reason is the docs system: `opmodel.dev` pins a git ref per site version, so a tag or published version that changes under it silently changes what a published docs page describes. The same day the owner settled how a released minor is maintained: lazily cut `release/vX.Y` branches (core: `release/v2.0`), created by one automated action, never deleted, changed only through PRs, with release-please releasing patches from them.

Org rulesets (owner-applied in the browser) guard the git side: `tags-immutable` refuses tag update and deletion, `tags-create-app-only` lets only the opm-release-please App create a tag, and `release-branches` refuses deletion and force pushes on `release/*` and requires a PR. Because a hand-made or stale tag can no longer exist, no tag-to-commit assertion is needed in the workflow. Nothing guards the registry side, and core's release tooling has three gaps:

- `cue mod publish` has no existence check. At cue v0.17.1 `modregistry.Client.putCheckedModule` pushes the manifest under the version tag unconditionally (`PushManifest(ctx, repo, tag, ...)`), and GHCR has no tag immutability, so a re-run or a mistaken publish replaces the bytes behind a version every consumer has pinned.
- `task publish` honours whatever `CUE_REGISTRY` the shell carries. With the canonical developer mapping (`opmodel.dev=ghcr.io/open-platform-model`) exported, `task publish VERSION=vX.Y.Z` writes to GHCR from a laptop. Library's publish tasks already force a local mapping in-script; core's does not.
- `release.yml` runs only on pushes to `main` and has release-please target `main`, so a `release/v2.0` branch, once cut, could never release a patch; and there is no way to cut the branch at all.

## What Changes

- `.github/workflows/release.yml`, `publish-cue` job: probes GHCR for the manifest of `opmodel.dev/core` at the release version before `cue mod publish`. A present manifest refuses the publish (recovery: the next version); an inconclusive probe (anything but 200 or 404) also refuses (recovery: re-run the job, since nothing was pushed). The probe lives in `.tasks/publish-probe.sh` so it can be run and checked locally.
- `.github/workflows/release.yml`, trigger and `release-please` job: the workflow also runs on pushes to `release/**`; release-please gets `target-branch: ${{ github.ref_name }}`, and the "Trigger required CI" step dispatches CI onto that branch's release PR branch instead of a hard-coded `main` one.
- `.github/workflows/cut-release-branch.yml` (new): a `workflow_dispatch` caller with one input, the released minor `X.Y`. It calls the shared reusable workflow `open-platform-model/.github/.github/workflows/cut-release-branch.yml` with `tag_prefix: v` and package `.`; that workflow creates `release/vX.Y` from the highest `vX.Y.*` tag and opens a PR into it setting `versioning: always-bump-patch` and `prerelease: false` for package `.`. No release branch is cut by this change; core is in beta, where fixes go forward on `main`.
- `Taskfile.yml`, `task publish`: forces `CUE_REGISTRY` to a local-only mapping (`opmodel.dev=localhost:5000+insecure,registry.cue.works`) inside the task, ignoring the ambient mapping, so a laptop publish can never reach GHCR. `task publish:branch` is unchanged: branch builds (`-0.dev.*`) stay mutable by design and CI publishes them to GHCR through it.
- `AGENTS.md`: one pointer line to the workspace rule ("Release tags are immutable", workspace root `AGENTS.md`); the branch-model table gains the lazy `release/vX.Y` row; the release section names the probe and the release-branch flow. `README.md` and `docs/publishing.md` drop every claim that the registry refuses to overwrite a tag or that a re-publish is a storage no-op, and record the release probe.

Nothing under `src/` changes. The published CUE is byte-identical, so under Principle I this is neither MAJOR, MINOR nor PATCH; it does not rely on the `@v2` beta break licence and forces no `catalogs/opm` major. Every commit is a hidden type (`ci:`, `chore:`, `docs:`), so the change cuts no release.

This change implements enhancement 0021 D10 ("Release tags are immutable", enhancements PR 74, open): `0021:D10:R2` (roll-forward recovery) and `0021:D10:R3` (a version-named registry tag is never overwritten) for core's release path. D10 is being revised for the release-branch model; the requirement numbers are re-checked against the merged text before archive.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `schema-release`:
  - MODIFIED "The schema is published only by CI, from a reviewed release": a release PR is merged on `main` or on a `release/vX.Y` branch, and the re-run rule now states what a re-run may do (publish only a version the registry still lacks) and that a published version is superseded, never repaired.
  - ADDED "A release publishes only a version the registry does not hold": the GHCR probe, fail-closed on an inconclusive answer, roll-forward as the only recovery once a version exists, and the local-only `task publish`.
  - ADDED "A released minor is maintained on a lazily cut release branch": cut by the `cut-release-branch` action only, never during beta, patch-only, changed by PR, never deleted, docs-only fixes release nothing.

## Impact

- **library**, **cli**, **opm-operator**, **catalog_opm**: no action from this change. Sibling changes from the same canon give each the same release-branch trigger and `cut-release-branch` caller. They consume core from GHCR by version; this change only stops an existing version from changing under them.
- **modules**: excluded from the rule for now; untouched.
- **open-platform-model/.github**: owns the reusable `cut-release-branch.yml`, written in parallel. This change's caller pins it by commit SHA once it merges; until then the caller cannot run, which is harmless because no branch is cut during beta.
- **opmodel.dev**: no action; this change is what keeps its pinned core refs meaningful, and a docs-only fix on `release/v2.0` gives it a commit SHA to pin.
- **Recovery cost**: a release whose version GHCR already holds does not publish. The fix is the next release (`-beta.N+1` during beta, the next patch after GA), never a tag move or a re-publish, and that run stays red. An inconclusive probe is re-run.
- **Developers**: `task publish` now needs a running local registry (`task registry:start` at the workspace root) and can no longer target GHCR, even deliberately.
- **The `v1` maintenance branch** carries its own `release.yml`, runs release-please with `GITHUB_TOKEN` (not the release App) and publishes with no probe. Under `tags-create-app-only` its next release cannot create its tag. That is tracked as a follow-up `ci:` change on `v1` (task 4.1), not done here, because `main`'s changes never merge into `v1`.
