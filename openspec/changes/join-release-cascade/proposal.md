## Why

The release cascade (workspace `RELEASING.md`, "The cascade") moves OPM pins downstream by having each upstream tell its downstreams when it has published. core is the root of that graph: catalog_opm and library pin `opmodel.dev/core@v2`, and today they learn about a new core release only when a human runs `task deps:update` or `task -x deps:cascade`. Phase 3 of the rollout (`RELEASING.md`, "Rollout and changes", "Phases") wires each repo into the cascade. For core that means one thing: after a release is really published to GHCR, dispatch `upstream-released` to catalog_opm and library. core pins nothing OPM-owned, so it gets no receiver and no gates (`RELEASING.md`, "Changes", row `join-release-cascade`; Phase 3 wiring contract §1 row B1, §10).

The binding design is the Phase 3 wiring contract (version 3.1), merged in `.github` as `openspec/changes/archive/2026-10-04-add-release-cascade-workflows/contract.md` (changelogs 3.1.1 and 3.1.2), cited here as "contract §N", plus the supervisor's addendum for the five join changes (an allow-list for `release.yml`'s workflow `env`, and `runs-on: ubuntu-latest` on every key-holding job). This change was first written to contract version 2 (a reusable notify workflow called at `@main`). The sandbox cycle showed that a reusable workflow cannot read the caller's Environment secret (E1), and owner decision 24 pins the cascade code by SHA, so the change is rebuilt to version 3.1.

## What Changes

- `.github/workflows/release.yml` gains one job, `notify-downstream`, after `publish-docs` and last in the `jobs:` map. It is the contract §4.6 core block, byte for byte:
  - `needs: [release-please, publish-cue]` and `if: needs.release-please.outputs.release_created == 'true' && vars.CASCADE_NOTIFY != 'off'`. The default `success()` gate means a failed or skipped `publish-cue` skips notify, because nothing was published. `publish-docs` does not gate notify, and notify does not gate it.
  - `runs-on: ubuntu-latest`, `environment: cascade`, `timeout-minutes: 20`, `permissions: {contents: read}`.
  - One step: `uses: open-platform-model/.github/.github/actions/cascade-notify@2376ffae4bfc665f327d51581350dea694c01504 # .github main`, with the inputs `tag: ${{ needs.release-please.outputs.tag_name }}`, `client-id: ${{ vars.CASCADE_APP_CLIENT_ID }}` and `private-key: ${{ secrets.CASCADE_APP_PRIVATE_KEY }}`.
  - The key is read only in this caller-owned job, which declares `environment: cascade` and passes `secrets.CASCADE_APP_PRIVATE_KEY` only as the `private-key` input of the SHA-pinned `cascade-notify` action; the job has no checkout or `run:` of its own, and no `env:`, `container:` or `services:`; no reusable call passes `secrets:` or `secrets: inherit` (contract §2.2, §10.1 item 9). The action mints the App token itself (contract §2.3, §4.1).
  - The targets (catalog_opm, library), the payload and the retries are owned by the action (contract §3.1, §4.1, §4.2). core passes only the tag.
- **The pin.** core's one cascade reference names the full SHA of `.github` PR 9's squash commit on `main`, with the comment ` # .github main` (owner decision 24, contract §2.4). `.github` already merged, so the branch pins the `main` SHA from the start and never names a branch commit. A later `.github` change reaches core only through a `ci(deps): pin the cascade to .github <first 7 of the SHA>` PR (contract §2.4, workspace `RELEASING.md` "Moving the cascade pin").
- **The wiring check.** A new script `.tasks/cascade/wiring-check.sh` (the contract §10.1 item 6 script with `RECEIVER=false`, plus the addendum's two additions), run by a new task `cascade:wiring:check`, which the aggregate `check` task also runs. It is a new step, "Verify the cascade wiring", in the required `ci.yml` job `ci` ("Validate schema"), right after "Install Task", so it runs on every PR. It asserts the notify job's exact keys, its one step's exact keys and input names, the two credential inputs, `environment: cascade`, `runs-on: ubuntu-latest`, `permissions` exactly `{contents: read}`, the SHA-pinned `uses:`, the key only in that step, `environment: cascade` on no other job, no `.github` call that passes `secrets`, one SHA and the pin comment on every `.github` reference, and that `release.yml`'s workflow-level `env` holds only `CUE_VERSION` and `CUE_REGISTRY`. The script lives in the PR's own tree: it guards against mistakes, while review and the `main` ruleset guard against a deliberate edit.
- A new repo variable switch, `CASCADE_NOTIFY=off`, stops core's releases from dispatching (contract §4.4, `RELEASING.md` "Stop switches"). core has no repo-level variable today (org-level variables were not checked), so notify runs.
- `AGENTS.md` "Release & publishing" and `README.md` "Release lifecycle" record the job, its targets, the pin and how it moves, the wiring check, the switch, and how to recover a failed notify.
- No Dependabot change: core has no `.github/dependabot.yml`, and the contract says not to add one (§10.1 item 7). No `cascade-task.yml` exists in core, so there is no resolver `ref:` to pin.

Nothing under `src/` changes. The published CUE is byte-identical, so under Principle I this is neither MAJOR, MINOR nor PATCH. It does not rely on the `@v2` beta break licence and forces no `catalogs/opm` major. Every commit is a hidden type (`ci:`, `docs:`), so the change cuts no release. The join PR title is `ci: join the release cascade` (contract §1).

No enhancement backs the release cascade; it is specified in workspace `RELEASING.md`. This change has no `enhancement.yaml`.

**Depends on and gates.**

- **`.github` `add-release-cascade-workflows` has merged** (PR 9, squash `2376ffae4bfc665f327d51581350dea694c01504` on `main`; `gh api repos/open-platform-model/.github/compare/2376ffae4bfc665f327d51581350dea694c01504...main --jq .status` printed `identical` on 2026-10-04). The `cascade-notify` action at that SHA declares exactly the inputs `tag`, `client-id` and `private-key`, all required (contract §4.1).
- **Only the `@v2` line notifies.** The job goes into `release.yml` on `main`. core's protected `v1` branch releases `v1.1.x` through its own `release.yml`, which this change does not touch, so `v1` maintenance releases notify nobody; every downstream pins `@v2`.
- **A pinned action cannot fail the release at startup.** A composite action is fetched when the job that uses it starts, so a bad pin (a SHA that does not exist, or an action that fails) fails only `notify-downstream`, after `publish-cue`; `publish-docs` runs independently. A merge to `.github` `main` changes nothing in core until core moves its pin. The fix for a bad pin is a pin PR (contract §10.1 item 10).
- The `RELEASING.md` row also names the repo's `add-deps-cascade-task` and `prepare-release-cascade`. core has neither and needs neither: it has no receiver, and nothing in core is a cascade pin.
- Phase 0 settings it relies on, checked read-only on 2026-10-04: core's `cascade` Environment exists, its deployment branch policy allows `main` only, and it holds the variable `CASCADE_APP_CLIENT_ID` and the secret `CASCADE_APP_PRIVATE_KEY`. core's Actions settings are `allowed_actions: all`, `sha_pinning_required: false` (core pins by SHA anyway, decision 24).

## Capabilities

### New Capabilities

- `release-cascade`: how a published core release takes part in the cross-repo release cascade: it notifies its downstreams once the module is public, through the SHA-pinned `cascade-notify` action run in core's own `cascade` Environment job, and only then; and how that wiring stays locked by the wiring check on every PR.

### Modified Capabilities

None. `schema-release` covers how a release is cut and published; its requirements are unchanged. Notify starts after the last thing that requirement set governs.

## Impact

- **catalog_opm**, **library**: from the first core release after this merges, each receives an `upstream-released` dispatch with `{"source":"core","tags":["vX.Y.Z-beta.N"]}`. Until their own `join-release-cascade` merges, the dispatch returns 204 and starts nothing (contract §1). Once joined, their receivers run in dry run until Phase 4 sets `CASCADE_DRY_RUN=false`.
- **cli**, **opm-operator**: no dispatch from core. Their core pins follow the opm catalog (`RELEASING.md`, "Notify after publish").
- **modules**, the leaves: untouched; they stay on `task deps:update` (owner decision 15).
- **core's release run**: one more job. A failed dispatch turns the run red after the module is already published (`publish-cue`; `publish-docs` runs independently). The fix is "Re-run failed jobs", which re-sends the dispatch to both targets; the downstreams' daily sweep covers a lost one. Never "Re-run all jobs": it re-runs release-please, which finds the release already tagged and reports no release, so `publish-cue` and notify are skipped and the run ends green without notifying. The module is never re-published, so the immutability rule (`schema-release`, "A release publishes only a version the registry does not hold") is untouched.
- **core's PRs**: the required "Validate schema" check gains one offline step, `task cascade:wiring:check` (mikefarah `yq`, preinstalled on the runner).
- **Security**: the release App's key is never used for the cascade. The cascade key is read only in `notify-downstream`, a job in the `main`-only `cascade` Environment that runs only the pinned action. The key is shared by every product repo's `cascade` Environment, so the reach is org-wide (contract Facts, §11.5); this change adds the key's reader in core and no new holder. core's `cascade` Environment has `can_admins_bypass: true` (design, Risks).
