## Why

The release cascade (workspace `RELEASING.md`, "The cascade") moves OPM pins downstream by having each upstream tell its downstreams when it has published. core is the root of that graph: catalog_opm and library pin `opmodel.dev/core@v2`, and today they learn about a new core release only when a human runs `task deps:update` or `task -x deps:cascade`. Phase 3 of the rollout (`RELEASING.md`, "Rollout and changes", "Phases") wires each repo into the cascade. For core that means one thing: after a release is really published to GHCR, dispatch `upstream-released` to catalog_opm and library. core pins nothing OPM-owned, so it gets no receiver and no gates (`RELEASING.md`, "Changes", row `join-release-cascade`; Phase 3 wiring contract §1 row B1, §10).

## What Changes

- `.github/workflows/release.yml` gains one job, `notify-downstream`, after `publish-cue`. It calls the shared reusable workflow `open-platform-model/.github/.github/workflows/cascade-notify.yml@main` with `tag: ${{ needs.release-please.outputs.tag_name }}` (Phase 3 wiring contract §4.3, §4.5 row core).
  - `needs: [release-please, publish-cue]` and `if: needs.release-please.outputs.release_created == 'true' && vars.CASCADE_NOTIFY != 'off'`. The default `success()` gate means a failed or skipped `publish-cue` (release.yml:61-102) skips notify, because nothing was published.
  - `publish-docs` (release.yml:116-131) does not gate notify, and notify does not gate it.
  - The job grants only `permissions: {contents: read}`. It passes no `secrets:`. The App key stays in core's `cascade` Environment, which the reusable job declares (`RELEASING.md`, "Notify after publish", last bullet; contract §2.2 "No secrets input", §2.3).
  - The targets (catalog_opm, library), the payload and the retries are owned by the shared workflow (contract §3.1, §4.1, §4.2). core passes only the tag.
- A new repo variable switch, `CASCADE_NOTIFY=off`, stops core's releases from dispatching (contract §4.4, §9.2 switch 4). It is not set today, so notify runs.
- `AGENTS.md` "Release & publishing" and `README.md` "Release lifecycle" record the job, its targets, the switch, and how to recover a failed notify.

Nothing under `src/` changes. The published CUE is byte-identical, so under Principle I this is neither MAJOR, MINOR nor PATCH. It does not rely on the `@v2` beta break licence and forces no `catalogs/opm` major. Every commit is a hidden type (`ci:`, `docs:`), so the change cuts no release. The join PR title is `ci: join the release cascade` (contract §1).

No enhancement backs the release cascade; it is specified in workspace `RELEASING.md`. This change has no `enhancement.yaml`.

**Depends on and gates.**

- **Merges only after `.github` `add-release-cascade-workflows` has merged** (contract §1 "Order"): the job calls `cascade-notify.yml@main`, which does not exist on `.github` `main` today (checked 2026-10-04: `.github/workflows/` holds only `cascade-resolver*.yml`, `mention-guard.yml` and `tag-ledger.yml`). That change in turn merges only after the sandbox cycle, including E1 (a called job's `environment: cascade` resolves the caller repo's Environment), is green.
- **If E1 fails**, contract §13.1 replaces the reusable notify workflow with a composite action and a caller-side job that declares `environment: cascade` itself. That is a contract change: this change's design and tasks are revised before implementation, not patched in review.
- The `RELEASING.md` row also names the repo's `add-deps-cascade-task` and `prepare-release-cascade`. core has neither and needs neither: it has no receiver, and nothing in core is a cascade pin.
- Phase 0 settings it relies on, checked read-only on 2026-10-04: core's `cascade` Environment exists, its deployment branch policy allows `main` only, and it holds the variable `CASCADE_APP_CLIENT_ID` and the secret `CASCADE_APP_PRIVATE_KEY`. core's Actions settings are `allowed_actions: all`, `sha_pinning_required: false`, so an `@main` reusable call is allowed (owner decision 13).
- Implementation may be written in parallel with `add-release-cascade-workflows` (contract §1). Its section 1 verification reads the merged or branch `cascade-notify.yml` interface.

## Capabilities

### New Capabilities

- `release-cascade`: how a published core release takes part in the cross-repo release cascade: it notifies its downstreams once the module is public, through the shared notify workflow and the `opm-cascade` App, and only then.

### Modified Capabilities

None. `schema-release` covers how a release is cut and published; its requirements are unchanged. Notify starts after the last thing that requirement set governs.

## Impact

- **catalog_opm**, **library**: from the first core release after this merges, each receives an `upstream-released` dispatch with `{"source":"core","tags":["vX.Y.Z-beta.N"]}`. Until their own `join-release-cascade` merges, the dispatch returns 204 and starts nothing (contract §1). Once joined, their receivers run in dry run until Phase 4 sets `CASCADE_DRY_RUN=false`.
- **cli**, **opm-operator**: no dispatch from core. Their core pins follow the opm catalog (`RELEASING.md`, "Notify after publish").
- **modules**, the leaves: untouched; they stay on `task deps:update` (owner decision 15).
- **core's release run**: one more job. A failed dispatch turns the run red after the module and the docs bundle are already published. The fix is "Re-run failed jobs", which re-sends the dispatch only, and the downstreams' daily sweep covers a lost one. Nothing is re-published, so the immutability rule (`schema-release`, "A release publishes only a version the registry does not hold") is untouched.
- **Security**: the job never sees the release App's key, and the cascade key is reachable only from a job in the `main`-only `cascade` Environment. The key is shared by all seven `cascade` Environments, so the reach is org-wide (contract Facts, §11.5); this change adds no new holder.
