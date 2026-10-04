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

"Re-run failed jobs" on the last row re-runs `notify-downstream` only: GitHub reuses the outputs of the successful `release-please` and `publish-cue`, so the module is not published again and the probe is not asked again. The re-run dispatches to both targets again, which is harmless: a receiver re-resolves "newest published" itself and never trusts the payload's version (`RELEASING.md`, "repository_dispatch").

On a failed `publish-cue` that a re-run then fixes, the same "Re-run failed jobs" also runs the skipped dependents, so notify fires after the successful re-run.

## Research & Decisions

### Where notify hooks in

**Context**: notify must run only once the artifact is really public (`RELEASING.md`, "Notify after publish"), and must not be held back by work that publishes nothing consumers pin.
**Explored**: release.yml:61-131 on `main` at f985501; the Phase 3 wiring research (r-wiring §1 row core) and contract §4.5 row core.
**Decision**: `needs: [release-please, publish-cue]`, `if: release_created == 'true' && vars.CASCADE_NOTIFY != 'off'`. Not `needs: publish-docs`.
**Rationale**: `publish-cue` ends with `cue mod publish`, so its success is "the module is public". The docs bundle is not a cascade pin; gating on it would let a docs failure suppress the cascade.

### How the switch is written

**Context**: contract §4.4 adds `CASCADE_NOTIFY=off` as a new stop switch, to be added to `RELEASING.md` "Stop switches" by the contract §14 workspace amendment.
**Explored**: core's repo variables (`gh api repos/open-platform-model/core/actions/variables`: none on 2026-10-04); the `vars` context on a reusable-workflow caller job's `if`.
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

- **E1 is unproven.** That a called job's `environment: cascade` resolves the caller repo's Environment secret is undocumented (r-wiring finding 1). → `add-release-cascade-workflows` proves it in the sandbox before it merges, and this change merges only after it. If E1 fails, contract §13.1 moves the Environment into a caller-side job and this change is revised first.
- **A red release run after a successful publish.** A failed dispatch makes the run red although the release is complete. → Accepted: the red job makes a lost dispatch visible (contract §4.1 step 6). Recovery is "Re-run failed jobs" (D2) or waiting for the downstreams' daily sweep; it never involves re-publishing.
- **A burst of core releases.** Two releases in quick succession send two dispatches. → The downstream receiver's concurrency group collapses them, and it re-resolves "newest" (`RELEASING.md`, "Concurrency").
- **The shared key reaches all seven repos.** Any job running in a `cascade` Environment can mint a token for every repo the App is installed on (contract Facts, §11.5). → This change adds no holder of the key: the Environment already exists, and only a `main` run can enter it. core's `main` ruleset requires a PR.
- **Before downstream joins.** A dispatch to catalog_opm or library before their receivers merge returns 204 and starts nothing (contract §1). Nothing is lost: their receivers' first sweep resolves the newest core anyway.

## Migration Plan

1. `.github` `add-release-cascade-workflows` merges (after its sandbox cycle and the contract §14 `RELEASING.md` amendments).
2. This change's PR (`ci: join the release cascade`) is reviewed and merged by the supervisor. `ci` cuts no release, so merging it starts no notify.
3. The first core release after that is the first live notify. The supervisor checks its run: `notify-downstream` is green, and catalog_opm and library each show a `repository_dispatch` run (or none yet, if their receiver has not merged).

Rollback: set `CASCADE_NOTIFY=off` in core (immediate), or revert the job in a `ci:` PR.

## Open Questions

- None for core. E1, the workflows-permission rule and E6 are decided in `add-release-cascade-workflows`; only E1 can change this change (Risks, first bullet).
