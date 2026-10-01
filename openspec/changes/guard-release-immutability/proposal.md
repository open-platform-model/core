## Why

The owner ruled on 2026-10-01 that release tags are immutable: no tag under `refs/tags/` is ever moved, deleted or re-created, a broken release is fixed by releasing the next version, and a version-named registry tag (`vX.Y.Z` on GHCR) is never overwritten. The reason is the docs system: `opmodel.dev` pins a git ref per site version, so a tag or published version that changes under it silently changes what a published docs page describes. An org tag ruleset and GitHub immutable releases (owner-applied in the browser) guard the git side. Nothing guards the registry side, and two gaps in core can still overwrite or mislabel a published version:

- `cue mod publish` has no existence check. At cue v0.17.1 `modregistry.Client.putCheckedModule` pushes the manifest under the version tag unconditionally (`PushManifest(ctx, repo, tag, ...)`), and GHCR has no tag immutability, so a re-run or a mistaken publish replaces the bytes behind a version every consumer has pinned.
- `task publish` honours whatever `CUE_REGISTRY` the shell carries. With the canonical developer mapping (`opmodel.dev=ghcr.io/open-platform-model`) exported, `task publish VERSION=vX.Y.Z` writes to GHCR from a laptop. Library's publish tasks already force a local mapping in-script; core's does not.
- release-please (17.3.0, bundled by the pinned action v4.4.1) creates the GitHub Release with `target_commitish` set to the release commit, and when a tag of that name already exists GitHub attaches the release to the existing tag wherever it points. The `publish-cue` job then checks out `tag_name` and publishes whatever that tag names, which can differ from the commit the release PR merged.

## What Changes

- `.github/workflows/release.yml`, `release-please` job: after a release is created, a step asserts that the tag's peeled commit on the remote (`git ls-remote`) equals release-please's `sha` output (the release commit), and fails the run otherwise. The job exposes `sha` as an output.
- `.github/workflows/release.yml`, `publish-cue` job: asserts the checked-out `HEAD` equals that `sha`, then probes GHCR for the manifest of `opmodel.dev/core` at the release version before `cue mod publish`. A present manifest refuses the publish; an inconclusive probe (anything but 200 or 404) also refuses. The probe lives in `.tasks/publish-probe.sh` so it can be run and checked locally.
- `Taskfile.yml`, `task publish`: forces `CUE_REGISTRY` to a local-only mapping (`opmodel.dev=localhost:5000+insecure,registry.cue.works`) inside the task, ignoring the ambient mapping, so a laptop publish can never reach GHCR. `task publish:branch` is unchanged: branch builds (`-0.dev.*`) stay mutable by design and CI publishes them to GHCR through it.
- `AGENTS.md`: one pointer line to the workspace rule ("Release tags are immutable", workspace root `AGENTS.md`), and the release section names the two guards. `README.md` and `docs/publishing.md` drop the false claim that the registry refuses to overwrite a tag, and record the release probe (the publishing doc's "idempotency probe" follow-up, for the release path).

Nothing under `src/` changes. The published CUE is byte-identical, so under Principle I this is neither MAJOR, MINOR nor PATCH; it does not rely on the `@v2` beta break licence and forces no `catalogs/opm` major. Every commit is a hidden type (`ci:`, `chore:`, `docs:`), so the change cuts no release.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `schema-release`: adds one requirement, "A release publishes only a version the registry does not hold, from the commit its tag names", covering the GHCR probe, the tag-SHA assertion, fail-closed on an inconclusive probe, roll-forward as the only recovery, and the local-only `task publish`. The existing "published only by CI" requirement is unchanged.

## Impact

- **library**, **cli**, **opm-operator**, **catalog_opm**, **modules**: no action. They consume core from GHCR by version; this change only stops an existing version from changing under them. library, catalog_opm, cli and opm-operator carry their own tag-SHA assertions in sibling changes from the same canon; modules is excluded from the rule for now.
- **opmodel.dev**: no action; this change is what keeps its pinned core refs meaningful.
- **Recovery cost**: a release whose tag fails the assertion, or whose version GHCR already holds, does not publish. The fix is the next release (`-beta.N+1`), never a tag move or a re-publish. The release run goes red and stays red.
- **Developers**: `task publish` now needs a running local registry (`task registry:start` at the workspace root) and can no longer target GHCR, even deliberately.
- The `v1` maintenance branch carries its own `release.yml` and is untouched here.
- This change carries no `enhancement.yaml`: the matching enhancement 0021 decision ("Release tags are immutable") is still being drafted, and its number is not yet fixed.
