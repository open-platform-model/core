## 1. Pin and copy

- [x] 1.1 Replace `.tasks/cascade/wiring-check.sh` with `.github/scripts/cascade/wiring-check.sh` at `0f9c6ac2c9b752a79f4874f637ef9955bcf00c13`; prove it with `cmp`.
- [x] 1.2 Move `release.yml`'s `cascade-notify` reference to `0f9c6ac2c9b752a79f4874f637ef9955bcf00c13 # .github main`; `grep -rn -i -A1 'open-platform-model/.github' .github/workflows` shows no other reference.
- [x] 1.3 Confirm the README at that SHA asks no CI or `wiring-check.yaml` edit for core (no edit).
- [x] 1.4 Commit `ci(deps): pin the cascade to .github 0f9c6ac`.

## 2. Spec

- [ ] 2.1 Delta for `release-cascade`: the README citation at `0f9c6ac`.

## 3. Final checks

- [ ] 3.1 Gates: `task check`, `actionlint`, `bash .tasks/cascade/wiring-check.sh --pin-on-main`, `openspec validate repin-cascade-0f9c6ac --strict`.
