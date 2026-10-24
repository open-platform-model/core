## Why

`.github` `main` moved to `6938f8e0247e019cb0c2db13fff5b7b558a6b67d` with two fixes: the resolver cleanup (`.github` PR 14) and a stronger wiring check (`.github` PR 15). With `--pin-on-main` the canonical check now compares the running copy byte for byte with `.github/scripts/cascade/wiring-check.sh` at the pinned SHA, restricts the CI workflow's and job's `env` and every step before the wiring step, and holds every checkout of `.github` to the pin. core still pins `7b9ad1b` and runs that SHA's copy, so it gets none of this until a pin PR lands.

## What Changes

- **Move the pin.** `release.yml`'s `notify-downstream` step names `cascade-notify@6938f8e0247e019cb0c2db13fff5b7b558a6b67d # .github main`, core's only `.github` reference. `gh api repos/open-platform-model/.github/compare/6938f8e...main --jq .status` prints `identical`.
- **Replace the copy.** `.tasks/cascade/wiring-check.sh` becomes the file at that SHA, byte for byte.
- No caller, config or CI edit: core's "Validate schema" job has no workflow or job `env`, and the three steps before "Verify the cascade wiring" are SHA-pinned actions with only `name`, `uses` and `with`, which is the shape the new rules require. `wiring-check.yaml` needs no new key.
- The `release-cascade` spec records the new refusals (copy comparison, CI step surroundings, `.github` checkout shape) and cites the README at `6938f8e`.

Nothing under `src/` changes and every commit is a hidden type, so no release is cut. No enhancement backs this change; it is wave 2 of the release cascade security pass.

## Capabilities

### New Capabilities

### Modified Capabilities

- `release-cascade`: the pinned wiring check also compares the copy with the pinned file in CI and refuses code placed around the CI step.

## Impact

- `.github/workflows/release.yml` (pin), `.tasks/cascade/wiring-check.sh` (copy), `AGENTS.md` (one sentence on the new refusals).
- The required "Validate schema" job now makes two API calls in its wiring step (the `compare` and the contents read of the pinned file) with its read-only token.
