## Why

The owner decided on 2026-09-30 to move every prerelease line in OPM from alpha to beta now, starting with the root of the dependency graph: `opmodel.dev/core@v2`. Beta makes a promise that alpha did not: the line is on the path to GA, and a break is still allowed but only as an announced `feat!` whose `BREAKING CHANGE:` footer is the migration note. Every downstream beta cut (library, catalogs/k8s, cli, opm-operator) waits on core `v2.0.0-beta.1` being on GHCR (gate G1). Today core's config, constitution, AGENTS.md, README, publishing notes and site page all state the alpha rule ("promises nothing"), and flipping `prerelease-type` alone would cut nothing: release-please keeps the existing label on a flip, and core has only hidden-type commits since `v2.0.0-alpha.13`.

## What Changes

- `release-please-config.json`: `prerelease-type` goes from `alpha` to `beta`, so every release after the first continues `2.0.0-beta.N`. No `release-as` key is added; the manifest is not hand-edited.
- The first beta is forced by a one-shot `Release-As: 2.0.0-beta.1` footer in the final squash commit message of this change's single PR (squash type `chore(release)`). The release PR it opens, `chore(main): release 2.0.0-beta.1`, carries the same schema bytes as `v2.0.0-alpha.13`.
- `openspec/specs/schema-release/spec.md`: the prerelease requirements become type-agnostic (the current type is `beta`), state the beta promise, and state that a line's first prerelease is forced by a `Release-As:` footer in the final commit message. The historical partial-tag requirement is left alone.
- The canonical beta promise replaces the alpha wording in `openspec/config.yaml` (Principle IV, the commit conventions, the proposal rule), `AGENTS.md` (branch table, the prerelease rule, the commit table), `README.md`, `docs/publishing.md` (including the false claim that prereleases are always excluded from `@latest`), and the promise text in `docs/site/concepts/versions.md`.
- Comments that name the alpha line as current: `Taskfile.yml` publish example, `src/cue.mod/module.cue`, `.tasks/branch-tag.sh`, `.github/workflows/release.yml`. Comment-only; no logic reads the prerelease label.
- `CHANGELOG.md` and `openspec/changes/archive/**` are historical records and stay as they are.

This is not a schema change. The published CUE is byte-identical before and after, so under Principle I it is neither MAJOR, MINOR nor PATCH in content; the version moves from `2.0.0-alpha.13` to `2.0.0-beta.1` by the forced footer alone. It relies on `@v2` still being a prerelease line (Principle IV) and redefines what that line promises: from beta.1 on, a break advances `-beta.N` and never moves the module path by itself.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `schema-release`: the CI-only publication scenario and the pre-stable break requirement stop naming `alpha`, carry the beta promise and the owner sign-off rule for breaks that would force a `catalogs/opm` major, and a new requirement states how a line changes prerelease type or goes GA (forced by a `Release-As:` footer in the final commit message; a config flip alone cuts nothing).

## Impact

- **library**: re-pins `DefaultSchemaModule` and its registry test pins to `opmodel.dev/core@v2` `v2.0.0-beta.1` in its own `adopt-beta-release-line` change, after G1. Until then its skew report names beta.1 as newer than the alpha.13 it carries (expected).
- **catalog_opm**: `catalogs/k8s` and `catalogs/opm` bump their core pin to beta.1 after G1 (k8s cuts `1.0.0-beta.1`, opm stays stable at `4.4.4`).
- **cli**, **opm-operator**: pick up core beta.1 through the library re-pin and their templates and samples; no direct action from this change.
- **modules**, **opm-modules**: re-pin through the supervisor's `task deps:update` after the cli beta; they stay on stable per-module SemVer.
- Every consumer pinning an explicit `v2.0.0-alpha.N` keeps resolving it: published tags are immutable. A consumer resolving `opmodel.dev/core@v2` with no pin gets the highest prerelease, and `beta` sorts above `alpha`, so the move is monotonic.
- Branch dev tags (`-0.dev.`) are unaffected: `.tasks/branch-tag.sh` reads only the base version of the highest tag.
- Enhancement 0021 carries verbatim copies of the rule text changed here; the supervisor re-copies them after this merges (outside this repo). This change implements no enhancement decision, so it carries no `enhancement.yaml`.
