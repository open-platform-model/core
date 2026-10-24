## 1. Pin and copy

- [x] 1.1 Replace `.tasks/cascade/wiring-check.sh` with `.github/scripts/cascade/wiring-check.sh` at `6938f8e0247e019cb0c2db13fff5b7b558a6b67d`; prove it with `cmp`.
- [x] 1.2 Move `release.yml`'s `cascade-notify` reference to `6938f8e0247e019cb0c2db13fff5b7b558a6b67d # .github main`; `grep -rn -i -A1 'open-platform-model/.github' .github/workflows` shows no other reference.
- [x] 1.3 Confirm the CI job and `wiring-check.yaml` already meet the README's rules at that SHA (no edit).
- [x] 1.4 Commit `ci(deps): pin the cascade to .github 6938f8e`.

## 2. Spec and docs

- [x] 2.1 Delta for `release-cascade`: the new refusals and the README citation at `6938f8e`.
- [x] 2.2 `AGENTS.md` "Release & publishing": the CI step also compares the copy and refuses code around the step.
- [x] 2.3 Commit `docs(cascade): record the copy comparison and CI step rules at 6938f8e`.

## 3. Final checks

- [x] 3.1 Gates: `task check`, `actionlint`, `bash .tasks/cascade/wiring-check.sh --pin-on-main`, `openspec validate repin-cascade-6938f8e --strict`.
- [x] 3.2 Commit `docs(cascade): close the repin-cascade-6938f8e task list`.
