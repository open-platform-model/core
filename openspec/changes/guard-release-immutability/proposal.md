## Why

The owner ruled on 2026-10-01 that release tags are immutable: no tag under `refs/tags/` is ever moved, deleted or re-created, a broken release is fixed by releasing the next version, and a version-named registry tag (`vX.Y.Z` on GHCR) is never overwritten. The reason is the docs system: `opmodel.dev` pins a git ref per site version, so a tag or published version that changes under it silently changes what a published docs page describes. The owner split the work in two phases. Phase 1 (this change) guards releases as they exist today, all cut from `main`. Phase 2 (before GA) adds lazily cut `release/vX.Y` maintenance branches and their automation; no release-branch support lands in any repo before then.

Org rulesets (owner-applied in the browser) guard the git side: `tags-immutable` refuses tag update and deletion, `tags-create-app-only` lets only the opm-release-please App create a tag, and `release-branches` refuses deletion and force pushes on `release/*` and requires a PR. Once `tags-create-app-only` is active (not yet, see design.md Migration Plan), a hand-made or stale tag cannot exist, so no tag-to-commit assertion is needed in the workflow. Nothing guards the registry side, and core's release tooling has two gaps:

- `cue mod publish` has no existence check. At cue v0.17.1 `modregistry.Client.putCheckedModule` pushes the manifest under the version tag unconditionally (`PushManifest(ctx, repo, tag, ...)`), and GHCR has no tag immutability, so a re-run or a mistaken publish replaces the bytes behind a version every consumer has pinned.
- `task publish` honours whatever `CUE_REGISTRY` the shell carries. With the canonical developer mapping (`opmodel.dev=ghcr.io/open-platform-model`) exported, `task publish VERSION=vX.Y.Z` writes to GHCR from a laptop. Library's publish tasks already force a local mapping in-script; core's does not.

## What Changes

- `.github/workflows/release.yml`, `publish-cue` job: probes GHCR for the manifest of `opmodel.dev/core` at the release version before `cue mod publish`. A present manifest refuses the publish (recovery: the next version); an inconclusive probe (anything but 200 or 404) also refuses (recovery: re-run the job, since nothing was pushed). The probe lives in `.tasks/publish-probe.sh` so it can be run and checked locally.
- `Taskfile.yml`, `task publish`: forces `CUE_REGISTRY` to a local-only mapping (`opmodel.dev=localhost:5000+insecure,registry.cue.works`) inside the task, ignoring the ambient mapping, so a laptop publish can never reach GHCR. `task publish:branch` is unchanged: branch builds (`-0.dev.*`) are outside the release rule, and CI publishes them to GHCR through it.
- `AGENTS.md`: one pointer line to the workspace rule ("Release tags are immutable", workspace root `AGENTS.md`); the release section names the probe and the re-run versus roll-forward rule. `README.md` and `docs/publishing.md` drop every claim that the registry refuses to overwrite a tag or that a re-publish is a storage no-op, and record the release probe.

Nothing under `src/` changes. The published CUE is byte-identical, so under Principle I this is neither MAJOR, MINOR nor PATCH; it does not rely on the `@v2` beta break licence and forces no `catalogs/opm` major. Every commit is a hidden type (`ci:`, `chore:`, `docs:`), so the change cuts no release.

This change implements enhancement 0021 D10 ("Release tags are immutable", enhancements PR 74, open): `0021:D10:R2` (roll-forward recovery) and `0021:D10:R3` (a version-named registry tag is never overwritten) for core's release path. D10 also states the full branch policy, which Phase 2 delivers; this change implements none of it. The requirement numbers are re-checked against the merged text before archive.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `schema-release`:
  - MODIFIED "The schema is published only by CI, from a reviewed release": the re-run rule now states what a re-run may do (publish only a version the registry still lacks) and that a published version is superseded, never repaired.
  - ADDED "A release publishes only a version the registry does not hold": the GHCR probe, fail-closed on an inconclusive answer, roll-forward as the only recovery once a version exists, and the local-only `task publish`.

## Impact

- **library**, **cli**, **opm-operator**, **catalog_opm**: no action from this change. They consume core from GHCR by version; this change only stops an existing version from changing under them.
- **modules**: excluded from the rule for now; untouched.
- **opmodel.dev**: no action; this change is what keeps its pinned core refs meaningful.
- **Recovery cost**: a release whose version GHCR already holds does not publish. The fix is the next release (`-beta.N+1` during beta, the next version from `main` after GA until Phase 2 adds release branches), never a tag move or a re-publish, and that run stays red. An inconclusive probe is re-run.
- **Developers**: `task publish` now needs a running local registry (`task registry:start` at the workspace root) and can no longer target GHCR, even deliberately.
- **The `v1` maintenance branch** carries its own `release.yml`, runs release-please with `GITHUB_TOKEN` (not the release App) and publishes with no probe. Under `tags-create-app-only` its next release cannot create its tag. That is tracked as a follow-up `ci:` change on `v1` (task 3.1), not done here, because `main`'s changes never merge into `v1`; it must land before the owner enables `tags-create-app-only` on core.
