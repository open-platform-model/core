## Context

core's `.github/workflows/release.yml` has three jobs today:

- `release-please` (release.yml:20-59): outputs `release_created`, `tag_name` and `version` (release.yml:23-26). Tags carry no component (`release-please-config.json`, `"include-component-in-tag": false`), so `tag_name` is `vX.Y.Z-beta.N`, for example `v2.0.0-beta.2`.
- `publish-cue` (release.yml:61-102): `needs: release-please`, gated on `release_created == 'true'`. It runs the GHCR probe (release.yml:80-83), then `cue vet` and `cue mod publish` (release.yml:93-102). Its last step is the publish, so job success means the module is on GHCR.
- `publish-docs` (release.yml:116-131): a docs-kit reusable workflow call, `needs: [release-please, publish-cue]`.

The workflow-level `permissions:` (release.yml:8-12) grant `contents`, `pull-requests`, `packages` and `actions` write. A job-level `permissions:` replaces them for that job.

The cascade's notify side is specified in workspace `RELEASING.md` "Notify after publish" and "repository_dispatch", and made concrete by the Phase 3 wiring contract (version 2), cited here as "contract §N". The shared notify workflow is `.github` change `add-release-cascade-workflows` (contract §1 row A, §4.1). It does not exist on `.github` `main` yet.

This change touches no `src/*.cue` file and no construct in `.tasks/spec-tracked.txt`. No construct is newly tracked, no definition's closedness, defaults or required-field set changes, and `SPEC.md` does not move.

## Goals / Non-Goals

**Goals:**

- Dispatch `upstream-released` to catalog_opm and library once per published core release, and only after the module is public.
- Hold no credential in core's own workflow code: the shared workflow mints the App token in core's `cascade` Environment.
- Give core's releases their own off switch (`CASCADE_NOTIFY=off`).

**Non-Goals:**

- A receiver, `deps-cascade.yml`, `cascade-gates.yml` or a `deps:cascade` task in core. core pins nothing OPM-owned (contract §3.2: core is not a receiver; §8.3: "core has no gates caller").
- Choosing the targets, the payload or the retry policy. Those live in `.github` (contract §3.1, §4.1, §4.2).
- Any change to `publish-cue`, `publish-docs` or the GHCR probe.

## Decisions

### D1. The job

Appended after `publish-docs` in `.github/workflows/release.yml`, exactly as contract §4.3 and §4.5 give it for core:

```yaml
  # Tell the cascade downstreams (catalog_opm, library) that this release is
  # on GHCR. needs publish-cue with the default success() gate: a failed or
  # skipped module publish notifies nobody. publish-docs is not a need, so a
  # docs failure never holds back the dispatch. The shared workflow mints the
  # opm-cascade App token in this repo's main-only `cascade` Environment; this
  # job passes no secret and grants only contents: read. Set the repo variable
  # CASCADE_NOTIFY=off to stop core's releases from dispatching. See the
  # workspace RELEASING.md, "Notify after publish".
  notify-downstream:
    name: Notify downstream
    needs: [release-please, publish-cue]
    if: needs.release-please.outputs.release_created == 'true' && vars.CASCADE_NOTIFY != 'off'
    permissions:
      contents: read
    uses: open-platform-model/.github/.github/workflows/cascade-notify.yml@main
    with:
      tag: ${{ needs.release-please.outputs.tag_name }}
```

- `org-github-ref` is not passed, so it takes its default `main`. The shared workflow refuses any other value outside a sandbox repo (contract §2.4).
- `needs` names `release-please` as well, because the `if` and `tag` read its outputs and a job can read only the outputs of jobs it needs.
- No `environment:` here: a job that calls a reusable workflow cannot set it (contract §4.3). The reusable `notify` job declares `environment: cascade` (contract §4.1).

### D2. What a run does, case by case

| Case | `publish-cue` | `notify-downstream` |
| --- | --- | --- |
| push to `main`, no release cut | skipped | skipped (`release_created` is not `true`) |
| release cut, probe refuses (already published) | failed | skipped (default `success()`) |
| release cut, publish succeeds | success | runs |
| release cut, publish succeeds, `publish-docs` fails | success | runs (docs is not a need) |
| `CASCADE_NOTIFY=off` | unchanged | skipped |
| notify fails after its retries | success | failed; run is red |
| `cascade-notify.yml` missing or invalid on `.github` `main` | not run: the whole run fails at startup, before any `if` is read, so `release-please` does not run either | not run |
| a `v1` maintenance release (core's `v1` branch has its own `release.yml`) | not this workflow | not this workflow: `v1` releases notify nobody |

"Re-run failed jobs" on the notify-failure row re-runs `notify-downstream` only: GitHub reuses the outputs of the successful `release-please` and `publish-cue`, so the module is not published again and the probe is not asked again. The re-run dispatches to both targets again, which is harmless: a receiver re-resolves "newest published" itself and never trusts the payload's version (`RELEASING.md`, "repository_dispatch"). So the spec asks for at least one notification per published release, one per run attempt, not exactly one.

Never use "Re-run all jobs" there: it re-runs `publish-cue`, whose GHCR probe refuses the already published version (exit 1), so notify is skipped and the run stays red with a misleading publish failure. If `publish-docs` failed too, "Re-run failed jobs" re-runs it as well, so the guarantee is that the *module* is never re-published.

On a failed `publish-cue` that a re-run then fixes, the same "Re-run failed jobs" also runs the skipped dependents, so notify fires after the successful re-run.

## Research & Decisions

### Where notify hooks in

**Context**: notify must run only once the artifact is really public (`RELEASING.md`, "Notify after publish"), and must not be held back by work that publishes nothing consumers pin.
**Explored**: release.yml:61-131 on `main` at f985501; the Phase 3 wiring research (r-wiring §1 row core) and contract §4.5 row core.
**Decision**: `needs: [release-please, publish-cue]`, `if: release_created == 'true' && vars.CASCADE_NOTIFY != 'off'`. Not `needs: publish-docs`.
**Rationale**: `publish-cue` ends with `cue mod publish`, so its success is "the module is public". The docs bundle is not a cascade pin; gating on it would let a docs failure suppress the cascade.

### How the switch is written

**Context**: contract §4.4 adds `CASCADE_NOTIFY=off` as a new stop switch, to be added to `RELEASING.md` "Stop switches" by the contract §14 workspace amendment.
**Explored**: core's repo variables (`gh api repos/open-platform-model/core/actions/variables`: none on 2026-10-04; `vars` also reads org-level variables, which were not checked: listing them needs `admin:org`); the `vars` context on a reusable-workflow caller job's `if`.
**Decision**: `vars.CASCADE_NOTIFY != 'off'` in the caller's `if`, outside `${{ }}`, since the core `if` has no `!cancelled()` term (contract §4.5 notes the in-brace form only for the `${{ }}` cases).
**Rationale**: an unset variable reads as the empty string, which is not `off`, so notify is on by default and only an explicit `off` stops it. The caller reads `vars` itself, so nothing depends on how a called workflow sees `vars` (contract §5 rationale, applied the same way here).

### Pinning the shared workflow at `@main`

**Context**: owner decision 13 ("@main + ruleset"). opm-operator has `sha_pinning_required: true`, which may refuse `@main` (contract §10, E6).
**Explored**: `gh api repos/open-platform-model/core/actions/permissions` on 2026-10-04: `allowed_actions: all`, `sha_pinning_required: false`. `.github` is public, so its reusable workflows are callable from every org repo (r-wiring finding 4; the org ruleset `mention-guard` already runs `.github` workflows at `main`).
**Decision**: `cascade-notify.yml@main`. No SHA pin.
**Rationale**: decision 13 applies, and core's settings do not refuse a branch ref. E6 concerns opm-operator only.

### Credentials

**Context**: the release App (`RELEASE_APP_CLIENT_ID`, `RELEASE_APP_PRIVATE_KEY`, release.yml:31-36) is a tag-creating identity; the cascade must not use it (owner decision 5: a separate least-privilege `opm-cascade` App).
**Explored**: `gh api repos/open-platform-model/core/environments`: Environment `cascade`, custom branch policy `main`; its variables list `CASCADE_APP_CLIENT_ID`, its secrets `CASCADE_APP_PRIVATE_KEY` (2026-10-04).
**Decision**: the caller passes no `secrets:` and grants `permissions: {contents: read}`, overriding the workflow-level write grants (release.yml:8-12). The reusable job reads the Environment's variable and secret itself (contract §2.2, §2.3).
**Rationale**: the caller job's `GITHUB_TOKEN` grant is the ceiling for the called job; the called notify job needs only `contents: read`, because the App token does the dispatch. Nothing in core's own file names a secret.

### No receiver, no gates

**Context**: `RELEASING.md` "Changes" row `join-release-cascade`: "receiver (not in core, which pins nothing OPM-owned)". contract §10 checklist: core gets the notify job only.
**Decision**: no `deps-cascade.yml`, no `cascade-gates.yml`, no `CASCADE_DRY_RUN` variable in core.
**Rationale**: a receiver would have nothing to move. G2 and G3 judge downstream pins and upstreams; core has neither.

## Risks / Trade-offs

- **E1 is unproven.** GitHub's reusable-workflow docs say a called job's `environment` makes that Environment's secrets available; what no one has observed yet is that the Environment resolved is the caller repo's, so that core's `cascade` secret reaches the job (r-wiring finding 1). → `add-release-cascade-workflows` proves it in the sandbox before it merges, and this change merges only after it. If E1 fails, contract §13.1 moves the Environment into a caller-side job and this change is revised first.
- **The release workflow depends on `.github` `main` at startup.** GitHub resolves a called reusable workflow when the run starts, before any job's `if` is read. If `cascade-notify.yml` is missing from `.github` `main`, or a later commit there makes it invalid, core's whole Release run fails at startup: `release-please` and `publish-cue` do not run, not only notify. `CASCADE_NOTIFY=off` cannot help, because the `if` is never read. → The merge order (this change after `add-release-cascade-workflows`, with a pre-merge check, Migration Plan step 2) and `.github`'s required `Resolver tests` check, which runs actionlint on its workflows, guard against it. The fix for a startup failure is a revert PR in core or a fix PR in `.github`.
- **A red release run after a successful publish.** A failed dispatch makes the run red although the release is complete. → Accepted: the red job makes a lost dispatch visible (contract §4.1 step 6). Recovery is "Re-run failed jobs", never "Re-run all jobs" (D2), or waiting for the downstreams' daily sweep; it never re-publishes the module.
- **A burst of core releases.** Two releases in quick succession send two dispatches. → The downstream receiver's concurrency group collapses them, and it re-resolves "newest" (`RELEASING.md`, "Concurrency").
- **The shared key reaches all seven repos.** Any job running in a `cascade` Environment can mint a token for every repo the App is installed on (contract Facts, §11.5). → This change adds no holder of the key: the Environment already exists, and only a `main` run can enter it. core's `main` ruleset requires a PR.
- **Before downstream joins.** A dispatch to catalog_opm or library before their receivers merge returns 204 and starts nothing (contract §1). Nothing is lost: their receivers' first sweep resolves the newest core anyway.

## Migration Plan

1. `.github` `add-release-cascade-workflows` merges (after its sandbox cycle and the contract §14 `RELEASING.md` amendments).
2. Before merging this change's PR, the supervisor checks:
   - the E1 and E1b rows of `add-release-cascade-workflows`' `design.md` "Sandbox cycle" table are recorded as passing, each with its run URL;
   - `cascade-notify.yml` on `.github` `main` still declares `tag` as a required string input and `org-github-ref` with default `main`, declares no `secrets:`, and its job still declares `environment: cascade`.

   If either fails, the PR does not merge (a missing workflow would fail core's whole Release run, Risks).
3. This change's PR (`ci: join the release cascade`) is reviewed and merged by the supervisor. `ci` cuts no release, so merging it starts no notify.
4. The first core release after that is the first live notify. The supervisor checks its run: `notify-downstream` is green, and catalog_opm and library each show a `repository_dispatch` run (or none yet, if their receiver has not merged).

Rollback: `CASCADE_NOTIFY=off` in core (immediate) covers a failing notify only. A Release run that fails at startup, because `cascade-notify.yml` is missing or invalid on `.github` `main`, ignores the switch: it needs a revert of the job in a `ci:` PR (or a fix PR in `.github`).

## Open Questions

- None for core. E1, the workflows-permission rule and E6 are decided in `add-release-cascade-workflows`; only E1 can change this change (Risks, first bullet).

## Plan review (2026-10-04)

Applied: the `@main` startup coupling (Risks, D2, Rollback, the AGENTS.md task), the `@v2`-from-`main` scope with a `v1` scenario, "at least one notification per run attempt", the "Re-run all jobs" trap, the pre-merge E1/E1b and interface check (Migration Plan step 2), and the E1 and org-variable wording.

Applied differently: the review asked that task 1.1 require E1 and E1b to have passed before task 1.2 starts, with section 1 as a spike. Not taken as written. E1 can only be proven by `add-release-cascade-workflows`' sandbox cycle, never by a core run, and contract §1 lets this change be written in parallel. So 1.1 records the E1/E1b state, stops on a recorded failure, and the evidence gates the merge (Migration Plan step 2) instead of the edit.

Left to the supervisor: the "(the four only; core has neither)" line belongs in the contract §14 `RELEASING.md` amendment, which this change does not own. The proposal records it.
