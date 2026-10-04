Rebuilt to the Phase 3 wiring contract (version 3.1), `.github` `openspec/changes/archive/2026-10-04-add-release-cascade-workflows/contract.md`, following §10.1 for core, with the supervisor's addendum. The `.github` pin is `2376ffae4bfc665f327d51581350dea694c01504` (PR 9's squash commit on `main`). The version 2 sections (a reusable `cascade-notify.yml@main` call) were implemented in `1c0abbd` and `e88d3d2` and are replaced by the sections below.

## 1. Notify job in release.yml

- [x] 1.1 Check the preconditions read-only, and stop and report to the supervisor if any fails: `gh api repos/open-platform-model/core/environments/cascade/deployment-branch-policies --jq '[.branch_policies[].name]'` prints `["main"]`; the Environment's variables contain `CASCADE_APP_CLIENT_ID` and its secrets `CASCADE_APP_PRIVATE_KEY`; `gh api repos/open-platform-model/.github/compare/2376ffae4bfc665f327d51581350dea694c01504...main --jq .status` prints `identical` or `ahead`; `.github/actions/cascade-notify/action.yml` at that SHA declares exactly the inputs `tag`, `client-id` and `private-key`. Record `can_admins_bypass` in design Risks.
- [x] 1.2 `.github/workflows/release.yml`: replace the version 2 `notify-downstream` job with the contract §4.6 core block (design D1), last in `jobs:`, `<SHA>` = `2376ffae4bfc665f327d51581350dea694c01504`, comment ` # .github main`. The comment above the job says only that it is caller-owned, declares `environment: cascade`, and passes the key to the pinned action as an input (contract §10.1 item 1). Change nothing else in the file.
- [x] 1.3 Verify: `actionlint` 1.7.12 on `.github/workflows/*.yml` reports nothing new (the `ci.yml` SC2016 info is on `main` already); `git diff origin/main -- .github/workflows/release.yml` shows only added lines; `grep -rn -A1 'open-platform-model/.github' .github/workflows` shows one reference, at the SHA, with the comment.
- [x] 1.4 `task check` green, then commit `ci(release): notify the release cascade through the pinned action`

## 2. Wiring check

- [ ] 2.1 Add `.tasks/cascade/wiring-check.sh`: the contract §10.1 item 6 script with `RECEIVER=false`, `PIN_COMMENT='.github main'`, and the addendum's two additions (design D3): the `release.yml` workflow-`env` allow-list `CUE_VERSION`, `CUE_REGISTRY` in place of the deny-list, and `runs-on: ubuntu-latest` in `key_job`. `shellcheck` 0.11.0 is clean.
- [ ] 2.2 `Taskfile.yml`: add `cascade:wiring:check` next to `docs:pins:check` (contract text), and append `- task: cascade:wiring:check` to the aggregate `check` task's `cmds`.
- [ ] 2.3 `.github/workflows/ci.yml` job `ci` ("Validate schema"): add the step `Verify the cascade wiring` / `run: task cascade:wiring:check` directly after "Install Task".
- [ ] 2.4 Test the check against mutations of a copy of `.github/workflows/` (scratchpad only): the branch as built passes, and so do a header comment and a changed `CUE_VERSION` value; each of these fails: notify `contents: write` or an extra permission; job-level `env:`, `container:`, `services:`, `strategy:` or `defaults:`; step-level `env:` or `if:`; an extra `with:` key; a second step or a checkout step; `@main`, a short SHA, a branch comment or no comment; another action; `environment` dropped or changed; `runs-on: self-hosted` or a list; a literal client id; another key secret; the job removed; `environment: cascade` or the key on another job or in another file; a `.github` call with `secrets: inherit`; a second `.github` reference; `BASH_ENV`, `ENV`, `NODE_OPTIONS` or any other key in the workflow `env`; a non-map workflow `env`.
- [ ] 2.5 `task check` green, then commit `ci: check the cascade wiring on every PR`

## 3. Release docs

- [ ] 3.1 `AGENTS.md` "Release & publishing": replace the version 2 bullet with the caller-owned job running the pinned `cascade-notify` action (key passed only as the `private-key` input), its targets, the pin and how it moves (a `ci(deps)` pin PR, `compare` check), `task cascade:wiring:check` in "Validate schema", `CASCADE_NOTIFY=off`, the bad-pin failure mode (only notify fails; fixed by a pin PR), recovery by "Re-run failed jobs" and why never "Re-run all jobs" (design D4), `v1` releases do not notify, and no receiver or gates in core. Add `task cascade:wiring:check` where the guide lists tasks.
- [ ] 3.2 `README.md` "Release lifecycle": keep the notify bullet; make it name the pinned action and the wiring check only if the bullet would otherwise mislead.
- [ ] 3.3 `task check` green, then commit `docs(release): document the pinned cascade notify job`

## 4. Final checks

- [ ] 4.1 Contract §10.1 item 11 re-grep on the branch; every hit fixed or allowed (archived or superseded text, design history sections that say they are superseded).
- [ ] 4.2 Gates: `task check`, actionlint 1.7.12, `task cascade:wiring:check`, `shellcheck .tasks/cascade/wiring-check.sh`, `openspec validate join-release-cascade --strict`.
- [ ] 4.3 Commit the ticked task list as `docs(openspec): record the join-release-cascade rebuild checks`
