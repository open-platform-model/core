## Why

The owner ruled on 2026-10-01 that release tags are immutable: no tag under `refs/tags/` is ever moved, deleted or re-created, a broken release is fixed by releasing the next version, and a version-named registry tag (`vX.Y.Z` on GHCR) is never overwritten. The reason is the docs system: `opmodel.dev` pins a git ref per site version, so a tag or published version that changes under it silently changes what a published docs page describes. The owner split the work in two phases. Phase 1 (this change) guards releases as they exist today, all cut from `main`. Phase 2 (before GA) adds lazily cut `release/vX.Y` maintenance branches and their automation; no release-branch support lands in any repo before then.

Org rulesets (owner-applied in the browser) guard the git side. On 2026-10-01 only `tags-immutable` is active on core: it refuses tag update, deletion and non-fast-forward, with an empty bypass list. GitHub immutable releases are also on for core. `tags-create-app-only` (tag creation only by the opm-release-please App) is not active yet; until it is, a hand-made tag at a future release version is not refused, and this change adds no tag-to-commit assertion because the owner's plan makes that ruleset the guard (design.md Migration Plan lists it as a checkable precondition). Release branches and their ruleset are Phase 2 and nothing in this change touches one. Nothing guards the registry side, and core's release tooling has two gaps:

- `cue mod publish` has no existence check. At cue v0.17.1 `modregistry.Client.putCheckedModule` pushes the manifest under the version tag unconditionally (`PushManifest(ctx, repo, tag, ...)`), and GHCR has no tag immutability, so a re-run or a mistaken publish replaces the bytes behind a version every consumer has pinned.
- `task publish` honours whatever `CUE_REGISTRY` the shell carries. With the canonical developer mapping (`opmodel.dev=ghcr.io/open-platform-model`) exported, `task publish VERSION=vX.Y.Z` writes to GHCR from a laptop. Library's publish tasks already force a local mapping in-script; core's does not.

## What Changes

- `.github/workflows/release.yml`, `publish-cue` job: probes GHCR for the manifest of `opmodel.dev/core` at the release version before `cue mod publish`. A present manifest refuses the publish (recovery: the next version); an inconclusive probe (anything but 200 or 404) also refuses (recovery: re-run the job, since nothing was pushed). The probe lives in `.tasks/publish-probe.sh` so it can be run and checked locally.
- `Taskfile.yml`, `task publish`: forces `CUE_REGISTRY` to a local-only mapping (`opmodel.dev=localhost:5000+insecure,registry.cue.works`) inside the task, ignoring the ambient mapping, so a laptop publish can never reach GHCR. `task publish:branch` is unchanged: branch builds (`-0.dev.*`) are outside the release rule, and CI publishes them to GHCR through it.
- `AGENTS.md`: one pointer line to the workspace rule ("Release tags are immutable", workspace root `AGENTS.md`); the release section names the probe and the re-run versus roll-forward rule. `README.md` and `docs/publishing.md` drop every claim that the registry refuses to overwrite a tag or that a re-publish is a storage no-op, and record the release probe.

Nothing under `src/` changes. The published CUE is byte-identical, so under Principle I this is neither MAJOR, MINOR nor PATCH; it does not rely on the `@v2` beta break licence and forces no `catalogs/opm` major. Every commit is a hidden type (`ci:`, `chore:`, `docs:`), so the change cuts no release.

This change carries part of enhancement 0021 D10 ("Release tags are immutable", enhancements PR 74, open, head c52aaf2): `0021:D10:R2` (roll-forward recovery) and `0021:D10:R3` (a version-named registry tag always names the content first pushed under it) for core's release path. It claims no whole decision, so `enhancement.yaml` declares `decisions: []`: D10 also needs the rulesets, the release-branch policy and four other repositories, and is claimed by the change that completes it. The requirement numbers are cited as they stand at c52aaf2; if PR 74 renumbers them before it merges, a `docs(openspec)` follow-up re-points the `Source:` lines in `openspec/specs/schema-release/spec.md`.

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
- **The `v1` maintenance branch** carries its own `release.yml`, runs release-please with `GITHUB_TOKEN` (not the release App) and publishes with no probe. Under `tags-create-app-only` its next release cannot create its tag. That is a follow-up `ci:` change on `v1` (design.md Migration Plan, precondition 1), not done here, because `main`'s changes never merge into `v1`; it must land before the owner enables `tags-create-app-only` on core.
