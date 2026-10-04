## Context

core's `.github/workflows/release.yml` has three jobs on `main` (f985501):

- `release-please` (release.yml:20-59): outputs `release_created`, `tag_name` and `version`. Tags carry no component (`release-please-config.json`, `"include-component-in-tag": false`), so `tag_name` is `vX.Y.Z-beta.N`, for example `v2.0.0-beta.2`.
- `publish-cue` (release.yml:61-102): `needs: release-please`, gated on `release_created == 'true'`. It runs the GHCR probe, then `cue vet` and `cue mod publish`. Its last step is the publish, so job success means the module is on GHCR.
- `publish-docs` (release.yml:116-131): a docs-kit reusable workflow call, `needs: [release-please, publish-cue]`.

The workflow-level `permissions:` (release.yml:8-12) grant `contents`, `pull-requests`, `packages` and `actions` write; a job-level `permissions:` replaces them for that job. The workflow-level `env:` (release.yml:14-17) holds `CUE_VERSION` and `CUE_REGISTRY`.

The cascade's notify side is specified in workspace `RELEASING.md` "Notify after publish", "repository_dispatch" and "Pinning the cascade code", and made concrete by the Phase 3 wiring contract (version 3.1), merged in `.github` as `openspec/changes/archive/2026-10-04-add-release-cascade-workflows/contract.md` with changelogs 3.1.1 and 3.1.2, cited here as "contract §N". §10.1 is the checklist this change follows. The supervisor's addendum for the five join changes adds two wiring-check assertions (D3). The `cascade-notify` composite action is in `.github` `main` at `2376ffae4bfc665f327d51581350dea694c01504`, the squash commit of `.github` PR 9.

This change touches no `src/*.cue` file and no construct in `.tasks/spec-tracked.txt`. No construct is newly tracked, no definition's closedness, defaults or required-field set changes, and `SPEC.md` does not move.

## Goals / Non-Goals

**Goals:**

- Dispatch `upstream-released` to catalog_opm and library once per published core release, and only after the module is public.
- Read the App key in exactly one place, a caller-owned job in core's `main`-only `cascade` Environment that runs only the SHA-pinned `cascade-notify` action.
- Keep that shape locked: a check in the required CI job refuses a PR that changes it by mistake.
- Give core's releases their own off switch (`CASCADE_NOTIFY=off`).

**Non-Goals:**

- A receiver, `deps-cascade.yml`, `cascade-gates.yml`, `cascade-task.yml` or a `deps:cascade` task in core. core pins nothing OPM-owned (contract §3.2: core is not a receiver; §8.3: core has no gates caller).
- A Dependabot entry: core has no `.github/dependabot.yml`, and contract §10.1 item 7 says not to add one.
- Choosing the targets, the payload or the retry policy. Those live in `.github` (contract §3.1, §4.1, §4.2).
- Any change to `publish-cue`, `publish-docs` or the GHCR probe.

## Decisions

### D1. The job

Appended after `publish-docs` in `.github/workflows/release.yml`, last in the `jobs:` map, as contract §4.6 gives it for core:

```yaml
  # Caller-owned: this job declares the main-only `cascade` Environment and
  # passes the opm-cascade App key (and client id) only as inputs to the
  # SHA-pinned cascade-notify action, which mints the token itself.
  notify-downstream:
    name: Notify downstream
    needs: [release-please, publish-cue]
    if: needs.release-please.outputs.release_created == 'true' && vars.CASCADE_NOTIFY != 'off'
    runs-on: ubuntu-latest
    environment: cascade
    timeout-minutes: 20
    permissions:
      contents: read
    steps:
      - name: Notify downstream
        uses: open-platform-model/.github/.github/actions/cascade-notify@2376ffae4bfc665f327d51581350dea694c01504 # .github main
        with:
          tag: ${{ needs.release-please.outputs.tag_name }}
          client-id: ${{ vars.CASCADE_APP_CLIENT_ID }}
          private-key: ${{ secrets.CASCADE_APP_PRIVATE_KEY }}
```

- The job owns the Environment. A reusable-workflow job that declares `environment: cascade` sees the caller's Environment variables but not its secrets unless the caller passes `secrets: inherit` (sandbox E1, contract §2.2), and `inherit` would hand every core secret to the called workflow. So core's own job declares `environment: cascade` and passes the key as the action's `private-key` input (contract §4.3, §13.1).
- The job has exactly one step, the pinned action: no checkout, no `run:`, and no `env:`, `container:` or `services:`, so no core code runs while the key is in reach.
- `needs` names `release-please` as well, because the `if` and `tag` read its outputs and a job can read only the outputs of jobs it needs.
- The comment above the job says only what contract §10.1 item 1 allows: the job is caller-owned, declares `environment: cascade`, and passes the key to the pinned action as an input.

### D2. The pin

The one cascade reference names `.github` `main` commit `2376ffae4bfc665f327d51581350dea694c01504` in full, followed by ` # .github main` (owner decision 24; contract §2.4). The action runs its scripts from its own directory, so the pin runs exactly that commit's code, and nothing on `.github` `main` changes core's notify until core moves the pin. A move is one PR titled `ci(deps): pin the cascade to .github <first 7 of the SHA>` that replaces the SHA and nothing else (workspace `RELEASING.md` "Moving the cascade pin"; core is never the canary, since it has no receiver). Before it merges, `gh api repos/open-platform-model/.github/compare/<SHA>...main --jq .status` prints `identical` or `ahead`.

`.github` PR 9 merged before this rebuild, so the branch pins the `main` squash SHA from its first notify commit and never carries a `feat/add-release-cascade-workflows` pin (contract §2.4 "Before A merges" does not arise).

### D3. The wiring check

`.tasks/cascade/wiring-check.sh` is the contract §10.1 item 6 script with `RECEIVER=false` and the addendum's two additions:

- `release.yml`'s workflow-level `env` is an allow-list: the keys may be only `CUE_VERSION` and `CUE_REGISTRY` (`ENV_ALLOW`), and the value must be a map. The contract's deny-list (`BASH_ENV`, `ENV`, `NODE_OPTIONS`) is replaced, so any other key that a shell, node or the runner reads at startup fails too. Workflow-level `env` reaches the notify action's steps, which is why it is checked.
- every key-holding job (in core, `notify-downstream` only) has `runs-on: ubuntu-latest`, so the key is held only on a fresh GitHub-hosted runner, never on a runner label a PR could point elsewhere.

The rest is the contract's: exact job keys `[environment, if, name, needs, permissions, runs-on, steps, timeout-minutes]`, exact step keys `[name, uses, with]`, exact `with` keys `[client-id, private-key, tag]`, `environment: cascade`, permissions exactly `{contents: read}`, one step, a `uses` matching `^open-platform-model/\.github/\.github/actions/cascade-notify@[0-9a-f]{40}$`, the two credential inputs exactly as above, `secrets.CASCADE_APP_PRIVATE_KEY` read nowhere else and `environment: cascade` on no other job in any file under `.github/workflows/`, no `.github` call passing `secrets`, and exactly one `.github` reference with one SHA and the `.github main` comment. It prints every mismatch, then fails; on success it prints `cascade wiring: ok, .github <SHA> (.github main)`.

`task cascade:wiring:check` runs it; it sits next to `docs:pins:check` in `Taskfile.yml`, and the aggregate `check` task runs it last. The required `ci.yml` job `ci` ("Validate schema") runs it as the step "Verify the cascade wiring", right after "Install Task", on every PR and push; the runner's preinstalled mikefarah `yq` v4 is the only dependency, and the script refuses another `yq`. It is a step in an existing required check, not a new check (contract §10).

The script is in the PR's own tree, so a PR can change it together with the workflow. It guards against mistakes; review and core's `main` ruleset (PR required, owner bypass through a PR only) guard against a deliberate edit.

### D4. What a run does, case by case

| Case | `publish-cue` | `notify-downstream` |
| --- | --- | --- |
| push to `main`, no release cut | skipped | skipped (`release_created` is not `true`) |
| release cut, probe refuses (already published) | failed | skipped (default `success()`) |
| release cut, publish succeeds | success | runs |
| release cut, publish succeeds, `publish-docs` fails | success | runs (docs is not a need) |
| `CASCADE_NOTIFY=off` | unchanged | skipped |
| notify fails after its retries | success | failed; run is red |
| the pin names a SHA that cannot be fetched, or the action fails | success | failed at "Set up job" or in its step; `release-please`, `publish-cue` and `publish-docs` are unaffected, because a composite action is fetched only when the job that uses it starts |
| a `v1` maintenance release (core's `v1` branch has its own `release.yml`) | not this workflow | not this workflow: `v1` releases notify nobody |

"Re-run failed jobs" on the notify-failure row re-runs `notify-downstream` only: GitHub reuses the outputs of the successful `release-please` and `publish-cue`, so the module is not published again and the probe is not asked again. The re-run dispatches to both targets again, which is harmless: a receiver re-resolves "newest published" itself and never trusts the payload's version (`RELEASING.md`, "repository_dispatch"). So the spec asks for at least one notification per published release, one per run attempt, not exactly one.

Never use "Re-run all jobs" there: it re-runs release-please, which finds the release already tagged (the merged release PR is relabelled from `autorelease: pending` to `autorelease: tagged` on the first run) and reports no release, so `publish-cue` and notify are skipped and the run ends green without notifying. This follows from release-please's labelling and was not seen in a run. If `publish-docs` failed too, "Re-run failed jobs" re-runs it as well, so the guarantee is that the *module* is never re-published.

On a failed `publish-cue` that a re-run then fixes, the same "Re-run failed jobs" also runs the skipped dependents, so notify fires after the successful re-run.

## Research & Decisions

### Where notify hooks in

**Context**: notify must run only once the artifact is really public (`RELEASING.md`, "Notify after publish"), and must not be held back by work that publishes nothing consumers pin.
**Explored**: release.yml:61-131 on `main` at f985501; contract §4.5 row core.
**Decision**: `needs: [release-please, publish-cue]`, `if: release_created == 'true' && vars.CASCADE_NOTIFY != 'off'`. Not `needs: publish-docs`.
**Rationale**: `publish-cue` ends with `cue mod publish`, so its success is "the module is public". The docs bundle is not a cascade pin; gating on it would let a docs failure suppress the cascade.

### How the switch is written

**Context**: contract §4.4 adds `CASCADE_NOTIFY=off` as a stop switch; `RELEASING.md` "Stop switches" lists it.
**Explored**: core's repo variables (`gh api repos/open-platform-model/core/actions/variables`: none on 2026-10-04; `vars` also reads org-level variables, which were not checked: listing them needs `admin:org`).
**Decision**: `vars.CASCADE_NOTIFY != 'off'` in the job's `if`, outside `${{ }}`, since the core `if` has no `!cancelled()` term (contract §4.5 notes the in-brace form only for the `${{ }}` cases).
**Rationale**: an unset variable reads as the empty string, which is not `off`, so notify is on by default and only an explicit `off` stops it.

### Pinning by SHA, not `@main`

**Context**: version 2 of this change called `cascade-notify.yml@main` (owner decision 13). Owner decision 24 (2026-10-04) supersedes `@main` for the cascade actions: "Pin by SHA in all five repos".
**Explored**: `gh api repos/open-platform-model/core/actions/permissions` on 2026-10-04: `allowed_actions: all`, `sha_pinning_required: false`. `.github` is public, so its actions are usable from every org repo. The action's interface at the pin (`.github/actions/cascade-notify/action.yml` at `2376ffa`): inputs `tag`, `client-id`, `private-key`, all required.
**Decision**: `cascade-notify@2376ffae4bfc665f327d51581350dea694c01504 # .github main`.
**Rationale**: decision 24 applies to every repo, whatever its `sha_pinning_required` setting. A pin also removes version 2's startup coupling: `@main` let any `.github` merge change core's release run at once.

### Credentials

**Context**: the release App (`RELEASE_APP_CLIENT_ID`, `RELEASE_APP_PRIVATE_KEY`, release.yml:31-36) is a tag-creating identity; the cascade must not use it (owner decision 5: a separate least-privilege `opm-cascade` App).
**Explored**: `gh api repos/open-platform-model/core/environments/cascade` on 2026-10-04: one protection rule, `branch_policy`, with custom policy `main`; `can_admins_bypass: true`; variable `CASCADE_APP_CLIENT_ID`, secret `CASCADE_APP_PRIVATE_KEY`.
**Decision**: the key is read only in the caller-owned `notify-downstream` job, which declares `environment: cascade` and passes `secrets.CASCADE_APP_PRIVATE_KEY` only as the `private-key` input of the SHA-pinned `cascade-notify` action; that job has no checkout or `run:` of its own, and no `env:`, `container:` or `services:`; no reusable call passes `secrets:` or `secrets: inherit` (contract §10.1 item 9). The job grants `permissions: {contents: read}`, overriding the workflow-level write grants.
**Rationale**: the App token does the dispatch, so the built-in token needs nothing beyond reading contents. Keeping the job to one pinned step means no core code runs in a job that holds the key.

### No receiver, no gates

**Context**: `RELEASING.md` "Changes" row `join-release-cascade`: "receiver (not in core, which pins nothing OPM-owned)". Contract §10 checklist: core gets the notify job and the wiring check.
**Decision**: no `deps-cascade.yml`, `cascade-gates.yml` or `cascade-task.yml`, and no `CASCADE_DRY_RUN` variable in core. The wiring check runs with `RECEIVER=false`.
**Rationale**: a receiver would have nothing to move. G2 and G3 judge downstream pins and upstreams; core has neither.

## Risks / Trade-offs

- **A bad pin.** A pin PR could name a SHA that is not on `.github` `main`, or one whose action fails. → The wiring check refuses anything but one full SHA with the `.github main` comment, and the `compare` check before merge refuses a SHA that is not on `main` (D2). A pin that still fails turns only `notify-downstream` red (D4); the module and docs are already published. The fix is a pin PR back to a SHA core already ran.
- **An interface change in `.github`.** A `.github` change that adds a required input or renames `tag` reaches core only through a pin PR, which carries the caller edit (contract §2.4 step 3). actionlint does not check a composite action's inputs, so the wiring check's exact `with` key set is the check for core's side.
- **The wiring check is in core's own tree.** A PR can change the script and the workflow together. → It guards against mistakes only; review and the `main` ruleset guard against a deliberate edit (D3).
- **A red release run after a successful publish.** A failed dispatch makes the run red although the release is complete. → Accepted: the red job makes a lost dispatch visible (contract §4.1 step 6). Recovery is "Re-run failed jobs", never "Re-run all jobs" (D4), or waiting for the downstreams' daily sweep; it never re-publishes the module.
- **A burst of core releases.** Two releases in quick succession send two dispatches. → The downstream receiver's concurrency group collapses them, and it re-resolves "newest" (`RELEASING.md`, "Concurrency").
- **The shared key reaches every product repo.** Any job running in a `cascade` Environment can mint a token for every repo the App is installed on (contract Facts, §11.5). → This change adds core's one reader of the key, in an Environment that already holds it. The controls are the Environment's `main`-only branch policy, core's `main` ruleset (PR required) and the wiring check.
- **Admins can bypass the Environment's protection rules.** core's `cascade` Environment has `can_admins_bypass: true`, and its only protection rule is the `main` branch policy. Whether an admin can use that to run a non-`main` job in the Environment was not tested. → Not changed here: it is an owner setting on every `cascade` Environment (proposal Impact). Setting `can_admins_bypass` to `false` would make the branch policy bind admins too.
- **Before downstream joins.** A dispatch to catalog_opm or library before their receivers merge returns 204 and starts nothing (contract §1). Nothing is lost: their receivers' first sweep resolves the newest core anyway.

## Migration Plan

1. `.github` `add-release-cascade-workflows` merged as PR 9 (squash `2376ffa` on `main`), after its sandbox cycle (E1 failed, so the composite-action design of contract §13.1 is the design; E1b showed the Environment refuses a non-`main` run) and the `RELEASING.md` amendments of contract §14.
2. Before merging this change's PR, the supervisor runs the contract §10.1 "Pre-merge check" for core: `gh api repos/open-platform-model/.github/compare/2376ffae4bfc665f327d51581350dea694c01504...main --jq .status` prints `identical` or `ahead`; `grep -n "^PIN_COMMENT=\|^RECEIVER=" .tasks/cascade/wiring-check.sh` prints `'.github main'` and `false`; the "Verify the cascade wiring" step on the PR head printed `cascade wiring: ok, .github 2376ffae4bfc665f327d51581350dea694c01504 (.github main)`; `grep -rn -A1 'open-platform-model/.github' .github/workflows` shows no other SHA, branch or `@main`; and the item 11 re-grep leaves only allowed hits. Pre-merge item 1 (a final commit titled `ci: pin the cascade to .github main`) does not apply literally: the pin went in with the job, because `.github` had already merged (D2).
3. This change's PR (`ci: join the release cascade`) is reviewed and merged by the supervisor. `ci` cuts no release, so merging it starts no notify.
4. The first core release after that is the first live notify. The supervisor checks its run: `notify-downstream` is green, and catalog_opm and library each show a `repository_dispatch` run (or none yet, if their receiver has not merged).

Rollback: `CASCADE_NOTIFY=off` in core (immediate) stops notify. A bad pin is fixed by a pin PR back to a SHA core already ran; removing the job is a `ci:` revert PR.

## Open Questions

- None for core's wiring. The `can_admins_bypass` setting is an owner question across all `cascade` Environments (Risks).

## Plan review (2026-10-04)

Applied: the `@main` startup coupling (now gone with the SHA pin, D4), the `@v2`-from-`main` scope with a `v1` scenario, "at least one notification per run attempt", the "Re-run all jobs" trap, and the E1 and org-variable wording.

Applied differently: the review asked that task 1.1 require E1 and E1b to have passed before task 1.2 starts. E1 failed in the sandbox cycle; the contract moved to the composite-action design, and this change was rebuilt to it.

## Rebuild to contract version 3.1 (2026-10-04)

The version 2 change (a reusable `cascade-notify.yml@main` call with no Environment of its own) is replaced by contract §10.1 items 1, 2, 6, 8, 9, 10 and 11 for core. Items 3, 4, 5 and 7 do not apply (no receiver, no `cascade-task.yml`, no `dependabot.yml`). The implementation review's findings are applied: the startup-failure risk no longer exists under a pinned composite action (finding 1; D4 and Risks say so), the "Re-run all jobs" reason is corrected everywhere (finding 2), and the `can_admins_bypass` setting is recorded (finding 3).
