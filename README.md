# OPM core schema

The canonical schema for the Open Platform Model. `core` defines the CUE definitions that every OPM artifact — `#Module`, `#ModuleRelease`, `#Platform`, `#Component`, `#Resource`, `#Trait`, `#Blueprint`, `#ComponentTransformer` — is typed against.

This repository is a single CUE module, `opmodel.dev/core@v1`, published to `ghcr.io/open-platform-model/core` and consumed via `import "opmodel.dev/core/v1alpha2@v1"`.

The schema imports only the CUE standard library — it has no external dependencies, so `cue vet` runs fully offline.

## Layout

```text
cue.mod/module.cue   CUE module manifest — opmodel.dev/core@v1
v1alpha2/            the v1alpha2 schema package
  *.cue              schema definitions
  docs/              schema design notes
INDEX.md             generated definition index
```

## Release lifecycle

`core` has its own release cadence, independent of any consumer.

- Conventional-commit history drives [release-please](https://github.com/googleapis/release-please), which opens a release PR.
- Merging the release PR tags `vX.Y.Z` and creates the GitHub Release.
- The tag triggers `publish-cue.yml`, which runs `cue mod publish vX.Y.Z` against `ghcr.io/open-platform-model`.

Tags stay within `v1.x.x` — the CUE module path is pinned to major `@v1`.

## Common commands

```bash
task fmt            # format CUE files
task vet            # validate the v1alpha2 schema package
task generate:index # regenerate INDEX.md
task check          # fmt check + vet + INDEX freshness
task publish VERSION=v1.0.7   # publish the CUE module (CI does this on tag)
```
