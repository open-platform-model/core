# OPM core schema

The canonical schema for the Open Platform Model. `core` defines the CUE definitions that every OPM artifact — `#Module`, `#ModuleInstance`, `#Platform`, `#Component`, `#Resource`, `#Trait`, `#Blueprint`, `#ComponentTransformer` — is typed against.

This repository is a single CUE module, `opmodel.dev/core@v2`, published to `ghcr.io/open-platform-model/core` and consumed via `import "opmodel.dev/core@v2"` (package `core`).

The module is on its `v2` major, shipping `v2.0.0-beta.N` prereleases (enhancement 0010). From its first beta the line is on the path to GA: a break lands only as a `feat!` whose `BREAKING CHANGE:` footer is the migration note, and never moves the module path. The `@v1` line lives on, stable at `v1.1.0`, on the protected `v1` maintenance branch; downstream consumers re-pin to `@v2`, which is an import rewrite rather than a dependency bump.

The schema imports only the CUE standard library — it has no external dependencies, so `cue vet` runs fully offline.

## Layout

The CUE module lives under `src/` — both the `core` package files and `cue.mod/` sit there, so `src/` is the CUE module root and the import path is `opmodel.dev/core@v2` (no per-version subdirectory). The generated definition index ships inside `src/` so it travels with the published module; everything else (docs, SPEC, README, Taskfile, CI workflows) stays at the repo root. A new major (e.g. `@v2` → `@v3`), taken only after GA, is the only way the module path changes; it never adds a sibling package.

```text
src/cue.mod/module.cue   CUE module manifest — opmodel.dev/core@v2
src/*.cue                the core schema package
src/INDEX.md             generated definition index
docs/                    schema design notes
docs/site/               site pages; the definitions reference is generated into the docs bundle
docs-kit.cue             the core docs bundle (docs-kit)
SPEC.md                  normative schema specification
```

## Release lifecycle

`core` has its own release cadence, independent of any consumer.

- Conventional-commit history drives [release-please](https://github.com/googleapis/release-please), which opens a release PR.
- Merging the release PR tags `vX.Y.Z` and creates the GitHub Release.
- The same `release.yml` run then publishes the module — a `publish-cue` job gated on release-please's `release_created` output runs `cue mod publish vX.Y.Z` against `ghcr.io/open-platform-model`.
- Before it publishes, the job probes GHCR and refuses a version that is already there. A published version is never overwritten: a broken release is fixed by releasing the next version.
- Once the module is published, the run notifies catalog_opm and library so their release cascade picks up the new version (workspace `RELEASING.md`).

The CUE module path is on major `@v2`, currently shipping `v2.0.0-beta.N` prereleases (enhancement 0010).

## Common commands

```bash
task fmt            # format CUE files
task vet            # validate the core schema package
task generate:index # regenerate src/INDEX.md
task check          # fmt check + vet + INDEX freshness
task publish VERSION=vX.Y.Z   # CI publishes releases; locally, only against a local registry
```
