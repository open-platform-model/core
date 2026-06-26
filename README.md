# OPM core schema

The canonical schema for the Open Platform Model. `core` defines the CUE definitions that every OPM artifact — `#Module`, `#ModuleInstance`, `#Platform`, `#Component`, `#Resource`, `#Trait`, `#Blueprint`, `#ComponentTransformer` — is typed against.

This repository is a single CUE module, `opmodel.dev/core@v1`, published to `ghcr.io/open-platform-model/core` and consumed via `import "opmodel.dev/core@v1"` (package `core`).

The module is on its `v1` major, shipping `v1.0.0-alpha.N` prereleases while the post-rename schema settles (enhancement 0002 D13). The prior `@v0` line is retired; downstream consumers re-pin to `@v1`.

The schema imports only the CUE standard library — it has no external dependencies, so `cue vet` runs fully offline.

## Layout

The CUE module lives under `src/` — both the `core` package files and `cue.mod/` sit there, so `src/` is the CUE module root and the import path is `opmodel.dev/core@v1` (no per-version subdirectory). The generated definition index ships inside `src/` so it travels with the published module; everything else (docs, SPEC, README, Taskfile, CI workflows) stays at the repo root. A breaking schema revision bumps the module major (e.g. `@v1` → `@v2`) rather than adding a sibling package.

```text
src/cue.mod/module.cue   CUE module manifest — opmodel.dev/core@v1
src/*.cue                the core schema package
src/INDEX.md             generated definition index
docs/                    schema design notes
SPEC.md                  normative schema specification
```

## Release lifecycle

`core` has its own release cadence, independent of any consumer.

- Conventional-commit history drives [release-please](https://github.com/googleapis/release-please), which opens a release PR.
- Merging the release PR tags `vX.Y.Z` and creates the GitHub Release.
- The same `release.yml` run then publishes the module — a `publish-cue` job gated on release-please's `release_created` output runs `cue mod publish vX.Y.Z` against `ghcr.io/open-platform-model`.

The CUE module path is on major `@v1`, currently shipping `v1.0.0-alpha.N` prereleases (enhancement 0002 D13).

## Common commands

```bash
task fmt            # format CUE files
task vet            # validate the core schema package
task generate:index # regenerate src/INDEX.md
task check          # fmt check + vet + INDEX freshness
task publish VERSION=v1.0.0-alpha.1   # publish the CUE module (CI does this on tag)
```
