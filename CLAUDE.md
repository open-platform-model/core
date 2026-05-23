# Core repository guide

## Purpose

Repo defines + publishes the Open Platform Model **core schema** as a versioned CUE module (`opmodel.dev/core@v0`).

Source of truth for the OPM schema. Every OPM artifact is typed against these definitions. Downstream repos (`library`, `catalog`, `cli`, `opm-operator`, `modules`, `releases`) consume `core` as a published dependency — never by path.

This is a pure CUE repository: schema definitions plus the tooling to validate and publish them. No Go code.

## Repository Rules

- Guidance from this file, `CONSTITUTION.md`, and `Taskfile.yml`.
- Keep changes small; split broad requests into tiny, independently verifiable steps.
- The schema is a published contract. A breaking change to the `core` package is a breaking change for every consumer — prefer additive evolution.

## Entrypoint

Read on entry:

- Read `CONSTITUTION.md` before changing schema definitions.
- Keep `INDEX.md` updated when adding/removing/renaming definitions. Run `task generate:index` to regenerate; `task generate:index:check` to verify. Review generated output before commit — the script extracts doc comments as descriptions.
- Keep the Project Structure tree in `INDEX.md` in sync with new/removed directories.

## Repository Layout

```text
cue.mod/module.cue   CUE module manifest — opmodel.dev/core@v0
*.cue                the core schema package (lives at the module root)
docs/                schema design notes (tutorial / explanatory)
SPEC.md              normative schema specification (definitions, constraints, rationale)
.tasks/              Taskfile script fragments + git hooks
.claude/skills/      repo-local skills (e.g. core-schema-edit)
INDEX.md             generated definition index
```

The `core` package sits at the module root — there is no per-version subdirectory. A breaking schema revision bumps the module major (`@v0` → `@v1`), it does not add a sibling package.

The Go schema fixture harness is **not** part of this repo — it lives in the consuming `library` repo, which exercises the published schema there.

## Release & publishing

- Versioning is via release-please (`release.yml`, release type `simple`). Merging the release PR tags `vX.Y.Z` and creates the GitHub Release.
- The same `release.yml` run publishes the module — a `publish-cue` job gated on `release_created` runs `cue mod publish` to `ghcr.io/open-platform-model`. It runs in the workflow run the human merge triggers, so it is not subject to GITHUB_TOKEN tag-trigger suppression.
- Never run `cue mod publish` against a live registry manually — let CI publish.
- Tags stay within `v0.x.x` (CUE module is pinned to major `@v0`; pre-1.0, so minors may carry breaking schema changes).

## Commands

| Command | Purpose |
| --- | --- |
| `task fmt` / `task fmt:check` | Format CUE files / verify formatting |
| `task vet` | Validate the core schema package |
| `task generate:index` | Regenerate `INDEX.md` |
| `task spec:check` | Verify `SPEC.md` inventory matches CUE construct definitions |
| `task hooks:install` | Install the pre-commit hook (SPEC.md co-update gate) |
| `task check` | fmt check + vet + INDEX freshness + SPEC inventory |

## Schema editing protocol

Every change to a tracked construct in `core/*.cue` MUST co-commit with a corresponding update to `SPEC.md`. This is enforced by three layers:

- **Local pre-commit hook** — `task hooks:install` symlinks `.git/hooks/pre-commit` to `.tasks/hooks/pre-commit`. The hook blocks any commit that stages `*.cue` without `SPEC.md` unless `SPEC_IMPACT=none` is set (for whitespace / formatting-only edits).
- **`task spec:check`** — inventory check, wired into `task check`. Catches new constructs without SPEC sections, and SPEC references to renamed/deleted constructs.
- **CI co-update gate** — `ci.yml` rejects PRs that change `*.cue` without `SPEC.md` unless the PR body contains `Spec-Impact: none`.

Full protocol — section format, workflow, exceptions — lives in `.claude/skills/core-schema-edit/SKILL.md`. **Read that skill before editing any `*.cue` file.** Subagents dispatched here should be told to read it explicitly, since they do not load this file.

## CUE conventions

Follow the CUE style used across the workspace catalog. Pin `language: version: "v0.16.0"` in `cue.mod/module.cue`. Do not hard-wrap prose in `.md` files.
