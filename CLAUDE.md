# Core repository guide

## Purpose

This repo defines and publishes the Open Platform Model **core schema** as a versioned CUE module (`opmodel.dev/core@v1`).

The schema is the source of truth for OPM. Every OPM artifact is typed against these definitions, and downstream repos (`library`, `catalog`, `cli`, `opm-operator`, `modules`, `releases`) consume `core` as a published dependency — never by filesystem path.

This is a pure CUE repository: schema definitions plus the tooling to validate and publish them. No Go code.

## Repository Rules

- Authority is this file and `Taskfile.yml`. If they disagree with anything below, they win.
- Keep changes small. Split broad requests into tiny, independently verifiable steps.
- The schema is a published contract. A breaking change to the `core` package is a breaking change for every consumer — prefer additive evolution.
- Never run `cue mod publish` against a live registry manually — let CI publish.
- The CUE module is on major `@v1`, currently shipping `v1.0.0-alpha.N` prereleases (enhancement 0002 D13 — the `#ModuleRelease`→`#ModuleInstance` rename graduated the schema off the retired `@v0` line). release-please runs in prerelease mode (`prerelease: true`, `prerelease-type: "alpha"`, `bump-minor-pre-major: false` in `release-please-config.json`); a `feat!:` advances the alpha counter. A future stable cut drops the `-alpha` suffix; a later breaking revision bumps the module major (`@v1` → `@v2`).

## Entrypoint

Read these on entry:

- `CLAUDE.md` — repo working rules (this file).
- `Taskfile.yml` — authoritative build/validate/publish entrypoints.
- `SPEC.md` — normative schema specification (definitions, constraints, rationale).
- `src/INDEX.md` — generated definition index (lives inside the CUE module so it ships with publication).
- `docs/` — schema design notes (tutorial / explanatory).
- `.claude/skills/core-schema-edit/SKILL.md` — **required protocol** before editing any `src/*.cue` file.

## Repository Layout

```text
src/cue.mod/module.cue   CUE module manifest — opmodel.dev/core@v1
src/*.cue                the core schema package (module root lives under src/)
src/INDEX.md             generated definition index (ships inside the CUE module)
docs/                    schema design notes (tutorial / explanatory)
SPEC.md                  normative schema specification (definitions, constraints, rationale)
.tasks/                  Taskfile script fragments + git hooks
.claude/skills/          repo-local skills (e.g. core-schema-edit)
```

`src/` is the CUE module root: the `core` package and its `cue.mod/` both live there, so the import path is `opmodel.dev/core@v1` with no per-version subdirectory inside the module. Repo-level material (docs, SPEC, INDEX, README, Taskfile, CI workflows) sits at the repo root. A breaking schema revision bumps the module major (e.g. `@v1` → `@v2`); it does not add a sibling package.

All raw `cue` invocations run from `src/`. The Taskfile handles this via `dir: src` / `cd src` — see `task fmt`, `task vet`, `task tidy`, `task publish`.

The Go schema fixture harness is **not** part of this repo. It lives in the consuming `library` repo, which exercises the published schema there.

## Environment Notes

- Pin `language: version: "v0.17.0"` in `cue.mod/module.cue` (workspace-wide convention). This is a
  consumer floor, not a toolchain pin: a module declaring `vX` is rejected by every `cue` older than
  `vX`. Declare `v0.17.0` — the minimum that enables `cue.mod/local-module.cue` — never `v0.17.1`,
  which would lock out v0.17.0 tools for no gain. The toolchain itself is pinned separately (CI
  `CUE_VERSION`, and `cuelang.org/go` in the consuming Go repos).
- For raw `cue` outside `task`, export workspace registry vars from the root `CLAUDE.md` (`CUE_REGISTRY`, `OPM_REGISTRY`).

## Build And Dev Commands

| Command                       | Purpose                                                       |
| ---                           | ---                                                           |
| `task fmt` / `task fmt:check` | Format CUE files / verify formatting                          |
| `task vet`                    | Validate the core schema package                              |
| `task generate:index`         | Regenerate `src/INDEX.md`                                     |
| `task generate:index:check`   | Verify `src/INDEX.md` is up to date                           |
| `task spec:check`             | Verify `SPEC.md` inventory matches CUE construct definitions  |
| `task hooks:install`          | Install the pre-commit hook (SPEC.md co-update gate)          |
| `task check`                  | fmt check + vet + INDEX freshness + SPEC inventory            |

### Release & publishing

- release-please (`release.yml`, release type `simple`) opens and updates the release PR. Merging it tags `vX.Y.Z` and creates the GitHub Release.
- The same workflow run publishes the module: a `publish-cue` job gated on `release_created == 'true'` runs `cue mod publish` to `ghcr.io/open-platform-model`. It executes in the workflow run triggered by the human merging the release PR, so it is not subject to GitHub's GITHUB_TOKEN tag-trigger suppression.

### Commit conventions and release impact

Releases are driven entirely by commit message types (Conventional Commits). Use the right type — a misclassified commit will either cut a release nobody needs or hide a change consumers needed to see.

| Commit type                       | Version bump                    | In changelog | Use for                                                       |
| ---                               | ---                             | ---          | ---                                                           |
| `feat:`                           | minor                           | yes          | new construct, new field, additive schema surface             |
| `fix:`                            | patch                           | yes          | wrong constraint, broken default, definition behaving wrong   |
| `perf:`                           | patch                           | yes          | schema compile-time / evaluation cost improvements            |
| `revert:`                         | patch                           | yes          | undo of a prior released change                               |
| `feat!:` / `BREAKING CHANGE:`     | prerelease (advances `-alpha.N` on `@v1`) | yes | removing/renaming a definition, tightening a published constraint |
| `refactor:`                       | none                            | hidden       | moving files, renaming internal-only identifiers, restructuring |
| `docs:`                           | none                            | hidden       | README, design notes, comments — anything consumers don't see  |
| `style:`                          | none                            | hidden       | formatting-only changes (run `task fmt`)                       |
| `chore:`, `test:`, `ci:`, `build:` | none                           | hidden       | Taskfile, hooks, workflows, repo tooling                       |

**Rule of thumb:** if the published CUE schema is byte-identical before and after the change, it is *not* a `feat:` or `fix:`. File moves, directory restructures, doc tweaks, Taskfile edits, CI hardening — none of these warrant a release. They get `refactor:`, `docs:`, `chore:`, etc., and release-please skips them.

Examples:

- Moving `*.cue` files between directories with no content change → `refactor:`
- Adding a new `#Component` or expanding a definition's field set → `feat:`
- Tightening a regex constraint already in a published definition → `feat!:` (consumers may now fail validation)
- Loosening a regex constraint → `fix:` (was rejecting things it should have accepted)
- Editing `SPEC.md` only → `docs:`
- Editing `Taskfile.yml`, hooks, workflows → `chore:` or `ci:`

If a window between releases contains only hidden-type commits, no release PR is opened. If it mixes one `feat:` with several `refactor:`/`chore:`, a release is cut but the changelog only lists the `feat:`.

## CUE Style Guidelines

Follow the CUE style used across the workspace catalog. Pin `language: version: "v0.17.0"` in `cue.mod/module.cue` (see Environment Notes for why `v0.17.0` and not the current toolchain version). Do not hard-wrap prose in `.md` files.

## Working Style for Agents

- **Before editing any `src/*.cue` file**, load `.claude/skills/core-schema-edit/SKILL.md`. Every change to a tracked construct MUST co-commit with a corresponding update to `SPEC.md`. Three layers enforce this:
  - **Local pre-commit hook** — `task hooks:install` symlinks `.git/hooks/pre-commit` to `.tasks/hooks/pre-commit`. The hook blocks any commit that stages `*.cue` without `SPEC.md` unless `SPEC_IMPACT=none` is set (for whitespace / formatting-only edits).
  - **`task spec:check`** — inventory check, wired into `task check`. Catches new constructs without SPEC sections, and SPEC references to renamed or deleted constructs.
  - **CI co-update gate** — `ci.yml` rejects PRs that change `*.cue` without `SPEC.md` unless the PR body contains `Spec-Impact: none`.
- Subagents dispatched here should be told to read the `core-schema-edit` skill explicitly, since they do not load this file.
- Keep `src/INDEX.md` in sync when adding, removing, or renaming definitions, and when the directory tree under `src/` changes. `task generate:index` regenerates it (extracts doc comments as descriptions — review the output before commit). The Project Structure tree inside `src/INDEX.md` is hand-maintained alongside the generated section; update both.
- Run `task check` before finishing — it covers fmt, vet, INDEX freshness, and SPEC inventory in one shot.
