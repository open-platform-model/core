# Core repository guide

## Purpose

Repo defines + publishes the Open Platform Model **core schema** as a versioned CUE module (`opmodel.dev/core@v1`).

Source of truth for the v1alpha2 schema. Every OPM artifact is typed against these definitions. Downstream repos (`library`, `catalog`, `cli`, `opm-operator`, `modules`, `releases`) consume `core` as a published dependency — never by path.

This is a pure CUE repository: schema definitions plus the tooling to validate and publish them. No Go code.

## Repository Rules

- Guidance from this file, `CONSTITUTION.md`, and `Taskfile.yml`.
- Keep changes small; split broad requests into tiny, independently verifiable steps.
- The schema is a published contract. A breaking change to `v1alpha2` is a breaking change for every consumer — prefer additive evolution.

## Entrypoint

Read on entry:

- Read `CONSTITUTION.md` before changing schema definitions.
- Keep `INDEX.md` updated when adding/removing/renaming definitions. Run `task generate:index` to regenerate; `task generate:index:check` to verify. Review generated output before commit — the script extracts doc comments as descriptions.
- Keep the Project Structure tree in `INDEX.md` in sync with new/removed directories.

## Repository Layout

```text
cue.mod/module.cue   CUE module manifest — opmodel.dev/core@v1
v1alpha2/            v1alpha2 schema package (*.cue) and docs/
.tasks/              Taskfile script fragments
INDEX.md             generated definition index
```

The Go schema fixture harness is **not** part of this repo — it lives in the consuming `library` repo, which exercises the published schema there.

## Release & publishing

- Versioning is tag-driven via release-please (`release.yml`, release type `simple`). Merging the release PR tags `vX.Y.Z`.
- The tag triggers `publish-cue.yml` → `cue mod publish vX.Y.Z` to `ghcr.io/open-platform-model`.
- Never run `cue mod publish` against a live registry manually — let CI publish from the tag.
- Tags stay within `v1.x.x` (CUE module is pinned to major `@v1`).

## Commands

| Command | Purpose |
| --- | --- |
| `task fmt` / `task fmt:check` | Format CUE files / verify formatting |
| `task vet` | Validate the v1alpha2 schema package |
| `task generate:index` | Regenerate `INDEX.md` |
| `task check` | fmt check + vet + INDEX freshness |

## CUE conventions

Follow the CUE style used across the workspace catalog. Pin `language: version: "v0.16.0"` in `cue.mod/module.cue`. Do not hard-wrap prose in `.md` files.
