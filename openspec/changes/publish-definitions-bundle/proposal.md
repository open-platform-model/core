## Why

opmodel.dev builds core's pages from this repository's git tree: the authored pages under `docs/site/` and the definitions reference that `tools/refgen` generates and commits under `docs/site/reference/definitions/`. docs-kit phase 2 moves every product repository to a signed docs bundle instead: the repository builds, lints and publishes its pages on each release, and a site version pulls the bundles of the versions the cli pins (docs-kit DESIGN decision 10). docs-kit's `cue-definitions` extractor (contract C17) is refgen ported into docs-kit, so core keeps its inclusion list and loses its generator.

The owner decided one cutover per repository (docs-kit DESIGN decision 20): the bundle carries core's whole `docs/site/` together with the generated reference from the day core adopts docs-kit. While the site still reads core from git, the committed generated pages stay and are left out of the bundle with the `markdown` source's `exclude` (C6); once the site reads the bundle, they, the exclude and `tools/refgen/` go.

Sequence and contracts: docs-kit `docs/orchestration.md` (phase 2, "core: `publish-definitions-bundle`") and `https://github.com/open-platform-model/docs-kit/blob/main/docs/contracts.md` (C5, C6, C9, C12, C14, C15, C17). Until a docs-kit change lands, its `openspec/changes/<change>/design.md` on docs-kit `main` shows the contract.

Delivery: one PR per section (opmodel.dev needs the docs/core release bundle after section 2)

## What Changes

- **Section 1, adopt (gate G2-core).** `docs-kit.cue` declares the project `core`: docs placement owning `reference/definitions/`, a `cue-definitions` source whose page and exclusion lists are moved verbatim from `tools/refgen/groups.go`, and a `markdown` source over `docs/site` with `exclude: ["reference/definitions/"]`. `.opm-docs-version`, `.tasks/opm-docs.sh` and the tasks `tools:opm-docs`, `docs:bundle`, `docs:pins:check` and `docs:bundle:check` (the last in `task check`) as catalog_opm has them. `.github/workflows/docs.yml` (check on pull requests, edge on push to `main`, dispatch `release` or `revision`). `release.yml` gains `publish-docs` after `publish-cue`. `AGENTS.md` gains a "Docs bundles" paragraph. `tools/refgen` and `docs:reference:check` stay.
- **Section 2, first release bundle (owner).** The next core release publishes `docs/core`; the owner checks the package is public, the tags verify, and the run URLs are recorded here.
- **Section 3, retire refgen (gate G2-switch).** Delete `tools/refgen/`, `docs/site/reference/definitions/`, the `docs:reference`, `docs:reference:check` and `refgen:test` tasks, their CI steps and the `exclude`; core is CUE-only again. Archive.

Not in this change: anything in `src/*.cue` (no definition, constraint or doc comment changes), opmodel.dev's switch (`pull-reference-bundles`), the library's `DefaultSchemaModule` bump that makes a new core release reach the cli's pins (the release cascade).

## Capabilities

### New Capabilities

- `docs-bundle`: how core's docs bundle is configured, checked and published, and how its docs-kit release is pinned.

### Modified Capabilities

- `definitions-reference`: the reference is built from `src/` by docs-kit inside the bundle; nothing generated is committed and `tools/refgen` is gone.

## Impact

**Release classification: no release.** Every commit is `ci:` or `docs:`; the published CUE module is byte-identical (Principle I does not apply, no beta break licence, no `catalogs/opm` involvement, no schema surface for Principle V). `SPEC.md` does not move; no `src/*.cue` file is touched, so the co-update gate is not triggered.

A release is still needed for section 2, and nothing releasable has landed on `main` since `v2.0.0-beta.1` (every later commit is `docs:`, `ci:` or `chore:`). See design.md "The release that carries the first bundle".

**Downstream consumers:**

| Consumer | What it has to do |
| --- | --- |
| opmodel.dev | Nothing until `pull-reference-bundles`; v1.0 reads `docs/core` through the cli's pins after G2-switch, and section 3 waits for that. |
| library | Its next release pins the core release of section 2 (`DefaultSchemaModule`, release cascade), so the cli's pins name a core with a bundle (gate G2-pins). |
| cli, opm-operator, catalog_opm, modules | Nothing. |

**Constitution.** Section 3 restores "CUE only, no Go" in `openspec/config.yaml` and `AGENTS.md`, and replaces validation gate 5 (`task docs:reference:check`) with `task docs:bundle:check`.

**Owner items:** merging docs-kit's release PRs (gate), the core release of section 2, checking `ghcr.io/open-platform-model/docs/core` is public on first push.
