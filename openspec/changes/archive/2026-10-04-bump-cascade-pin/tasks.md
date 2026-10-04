## 1. Pin and canonical wiring check

- [x] 1.1 Replace `.tasks/cascade/wiring-check.sh` with `.github/scripts/cascade/wiring-check.sh` at `7b9ad1bea132f7a3f053a5db61ac3933b59ee226`; prove it with `cmp` against both `git show` and the `gh api ... contents ...?ref=<sha>` raw download.
- [x] 1.2 Add `.tasks/cascade/wiring-check.yaml` with core's values from the `.github` README table; take notify's `needs`, `if:` and `tag` from `release.yml` as it is.
- [x] 1.3 Move `release.yml`'s `cascade-notify` reference to `7b9ad1bea132f7a3f053a5db61ac3933b59ee226 # .github main`; `grep -rn -i -A1 'open-platform-model/.github' .github/workflows` shows no other reference.
- [x] 1.4 `ci.yml`: the "Verify the cascade wiring" step gets `env: {GH_TOKEN: ${{ github.token }}}` and `run: bash .tasks/cascade/wiring-check.sh --pin-on-main`.
- [x] 1.5 `bash .tasks/cascade/wiring-check.sh --pin-on-main` prints `cascade wiring: ok, .github 7b9ad1b... (.github main)`; `task check` green; commit `ci(deps): pin the cascade to .github 7b9ad1b`.

## 2. Dependabot and docs

- [x] 2.1 `.github/dependabot.yml`: `cooldown: {default-days: 7}` on the `github-actions` entry.
- [x] 2.2 `AGENTS.md` "Release & publishing": describe the canonical copy, its config, the `--pin-on-main` CI step, and that the pin PR replaces the copy too.
- [x] 2.3 `task check` green; commit `ci: add a dependabot cooldown and describe the canonical wiring check`.

## 3. Final checks

- [x] 3.1 Gates: `task check`, `actionlint`, `bash .tasks/cascade/wiring-check.sh --pin-on-main`, `openspec validate bump-cascade-pin --strict`, compare status `identical` or `ahead`.
- [x] 3.2 Commit the ticked task list.
