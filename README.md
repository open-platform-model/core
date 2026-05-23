# OPM core schema

The canonical schema for the Open Platform Model. `core` defines the CUE definitions that every OPM artifact — `#Module`, `#ModuleRelease`, `#Platform`, `#Component`, `#Resource`, `#Trait`, `#Blueprint`, `#ComponentTransformer` — is typed against.

This repository is a single CUE module, `opmodel.dev/core@v0`, published to `ghcr.io/open-platform-model/core` and consumed via `import "opmodel.dev/core@v0"` (package `core`).

The module is pre-1.0: `v0.x` makes no stability promise — breaking schema changes may land in minor releases until it graduates to `v1`.

The schema imports only the CUE standard library — it has no external dependencies, so `cue vet` runs fully offline.

## Layout

The CUE module lives under `src/` — both the `core` package files and `cue.mod/` sit there, so `src/` is the CUE module root and the import path stays `opmodel.dev/core@v0` (no per-version subdirectory). Repo-level material (docs, SPEC, INDEX, README, Taskfile, CI workflows) stays at the repo root. A breaking schema revision bumps the module major (`@v0` → `@v1`) rather than adding a sibling package.

```text
src/cue.mod/module.cue   CUE module manifest — opmodel.dev/core@v0
src/*.cue                the core schema package
docs/                    schema design notes
SPEC.md                  normative schema specification
INDEX.md                 generated definition index
```

## Release lifecycle

`core` has its own release cadence, independent of any consumer.

- Conventional-commit history drives [release-please](https://github.com/googleapis/release-please), which opens a release PR.
- Merging the release PR tags `vX.Y.Z` and creates the GitHub Release.
- The same `release.yml` run then publishes the module — a `publish-cue` job gated on release-please's `release_created` output runs `cue mod publish vX.Y.Z` against `ghcr.io/open-platform-model`.

Tags stay within `v0.x.x` — the CUE module path is pinned to major `@v0`.

## Common commands

```bash
task fmt            # format CUE files
task vet            # validate the core schema package
task generate:index # regenerate INDEX.md
task check          # fmt check + vet + INDEX freshness
task publish VERSION=v0.1.0   # publish the CUE module (CI does this on tag)
```
