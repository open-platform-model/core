# OPM core schema

The canonical schema for the Open Platform Model. `core` defines the CUE definitions that every OPM artifact — `#Module`, `#ModuleRelease`, `#Platform`, `#Component`, `#Resource`, `#Trait`, `#Blueprint`, `#ComponentTransformer` — is typed against.

This repository is a single CUE module, `opmodel.dev/core@v0`, published to `ghcr.io/open-platform-model/core` and consumed via `import "opmodel.dev/core@v0"` (package `core`).

The module is pre-1.0: `v0.x` makes no stability promise — breaking schema changes may land in minor releases until it graduates to `v1`.

The schema imports only the CUE standard library — it has no external dependencies, so `cue vet` runs fully offline.

## Layout

The `core` package lives at the module root — there is no per-version subdirectory. A breaking schema revision bumps the module major (`@v0` → `@v1`) rather than adding a sibling package.

```text
cue.mod/module.cue   CUE module manifest — opmodel.dev/core@v0
*.cue                the core schema package
docs/                schema design notes
INDEX.md             generated definition index
```

## Release lifecycle

`core` has its own release cadence, independent of any consumer.

- Conventional-commit history drives [release-please](https://github.com/googleapis/release-please), which opens a release PR.
- Merging the release PR tags `vX.Y.Z` and creates the GitHub Release.
- The same `release.yml` run then publishes the module — a `publish-cue` job gated on release-please's `release_created` output runs `cue mod publish vX.Y.Z` against `ghcr.io/open-platform-model`.
- `publish-cue.yml` is a separate `workflow_dispatch` workflow for manually re-publishing a version.

Tags stay within `v0.x.x` — the CUE module path is pinned to major `@v0`.

## Common commands

```bash
task fmt            # format CUE files
task vet            # validate the core schema package
task generate:index # regenerate INDEX.md
task check          # fmt check + vet + INDEX freshness
task publish VERSION=v0.1.0   # publish the CUE module (CI does this on tag)
```
