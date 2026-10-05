## Why

`.github` `main` is now `0f9c6ac2c9b752a79f4874f637ef9955bcf00c13`. Since core's pin `6938f8e` it carries `.github` PR 16 (a single code owner), PR 17 (owner decision 37: which repos move when) and PR 19 (`cascade-publish` mirror-drift refusal, the daily `cascade-mirror-drift.yml`, and the resolver's check that opm-operator's `opm_operator-v*` tags are on its `main`). PR 19 changes `wiring/lib.sh`, which `cascade-notify` runs, so under the README's "Both actions" rule one upstream moved first: the library (library PR 204). Its first live notify on the new pin (library `v1.0.0-beta.5` release run 37294102028, "Notify downstream" success) and its first live publish (library PR 206) succeeded, so core may move now.

## What Changes

- **Move the pin.** `release.yml`'s `notify-downstream` step names `cascade-notify@0f9c6ac2c9b752a79f4874f637ef9955bcf00c13 # .github main`, core's only `.github` reference. `gh api repos/open-platform-model/.github/compare/0f9c6ac...main --jq .status` prints `identical`.
- **Replace the copy.** `.tasks/cascade/wiring-check.sh` becomes the file at that SHA, byte for byte. The file is unchanged between `6938f8e` and `0f9c6ac`, so the copy is already identical; the check still compares it against the new pin.
- No caller, config or CI edit: the README at `0f9c6ac` keeps core's row in its config table unchanged and changes no caller shape or `cascade-notify` input. core is not a receiver, so it has no `mirror_sources` entry and the new drift refusal does not apply to it.
- The `release-cascade` spec cites the README at `0f9c6ac`; its behavior is unchanged.

Nothing under `src/` changes and every commit is a hidden type, so no release is cut. No enhancement backs this change; it is wave 2 of the release cascade security pass.

## Capabilities

### New Capabilities

### Modified Capabilities

- `release-cascade`: the pin requirement cites the `.github` README at the new SHA.

## Impact

- `.github/workflows/release.yml` (pin), `.tasks/cascade/wiring-check.sh` (byte-identical copy, no content change).
- A bad pin fails only `notify-downstream`, after the publish; the rollback is a pin PR back to `6938f8e`.
