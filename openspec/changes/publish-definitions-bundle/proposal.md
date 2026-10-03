## Why

opmodel.dev builds core's pages from this repository's git tree: the authored pages under `docs/site/` and the definitions reference that `tools/refgen` generates and commits under `docs/site/reference/definitions/`. docs-kit phase 2 moves every product repository to a signed docs bundle instead: the repository builds, lints and publishes its pages on each release, and a site version pulls the bundles of the versions the cli pins (docs-kit DESIGN decision 10). docs-kit's `cue-definitions` extractor (contract C17) is refgen ported into docs-kit, so core keeps its inclusion list and loses its generator.

The owner decided one cutover per repository (docs-kit DESIGN decision 20): the bundle carries core's whole `docs/site/` together with the generated reference from the day core adopts docs-kit. While the site still reads core from git, the committed generated pages stay and are left out of the bundle with the `markdown` source's `exclude` (C6); once the site reads the bundle, they, the exclude and `tools/refgen/` go.

Sequence and contracts: docs-kit `docs/orchestration.md` (phase 2, "core: `publish-definitions-bundle`") and `https://github.com/open-platform-model/docs-kit/blob/main/docs/contracts.md` (C5, C6, C9, C12, C14, C15, C17). Until a docs-kit change lands, its `openspec/changes/<change>/design.md` on docs-kit `main` shows the contract.

Delivery: one PR per section (cli needs the docs/core 2.0.0-beta.1 bundle after section 2)

## What Changes

- **Section 1, adopt (gate G2-core).** First, a doc-comment-only commit rewords the two comments that cite enhancements in prose (`src/catalog.cue`, `src/identity_package.cue`), which docs-kit's `strip` policy cannot clean. Then `docs-kit.cue` declares the project `core`: docs placement owning `reference/definitions/`, a `cue-definitions` source whose page and exclusion lists are moved verbatim from `tools/refgen/groups.go`, and a `markdown` source over `docs/site` with `exclude: ["reference/definitions/"]`. `.opm-docs-version`, `.tasks/opm-docs.sh` and the tasks `tools:opm-docs`, `docs:bundle`, `docs:pins:check` and `docs:bundle:check` (the last in `task check`) as catalog_opm has them. `.github/workflows/docs.yml` (check on pull requests, edge on push to `main`, dispatch `release` or `revision`). `release.yml` gains `publish-docs` after `publish-cue`. `AGENTS.md` gains a "Docs bundles" paragraph. A local dry run builds `v2.0.0-beta.1` with this config. `tools/refgen` and `docs:reference:check` stay.
- **Section 2, the bundle the cli pins (owner, part of gate G2-pins).** A release-mode backfill of `v2.0.0-beta.1` publishes `docs/core` (owner decision 2026-10-03); the owner checks the package is public, the tags verify, and the run URLs are recorded here. A later core release publishes through `publish-docs` on its own.
- **Section 3, retire refgen (gate G2-switch).** Delete `tools/refgen/`, `docs/site/reference/definitions/`, the `docs:reference`, `docs:reference:check` and `refgen:test` tasks, their CI steps and the `exclude`; core is CUE-only again. Archive.

Not in this change: any definition, constraint or default in `src/*.cue` (only two comments change), opmodel.dev's switch (`pull-reference-bundles`), automating docs revisions (manual for now; core#101, tracked in docs-kit#16).

## Capabilities

### New Capabilities

- `docs-bundle`: how core's docs bundle is configured, checked and published, and how its docs-kit release is pinned.

### Modified Capabilities

- `definitions-reference`: the reference is built from `src/` by docs-kit inside the bundle; nothing generated is committed and `tools/refgen` is gone.

## Impact

**Release classification: no release.** Every commit is `ci:`, `docs:` or `chore:` (one: `chore(index)`, which keeps the gitignored `out/` preview out of `src/INDEX.md`'s tree), and the PR squashes as `ci(docs):`; the published CUE module changes in two comments only, which ride the next release (Principle I does not apply, no beta break licence, no `catalogs/opm` involvement, no schema surface for Principle V). `SPEC.md` does not move; the comment commit uses `SPEC_IMPACT=none` with that reason.

No release is needed: section 2 backfills `v2.0.0-beta.1`, the core version the cli already pins through library `v1.0.0-beta.1`. Release PR core#106 (`2.0.0-beta.2`, from `606498b` `perf(pins)`) is independent of this change; merged after section 1, its run publishes the beta.2 bundle through `publish-docs`, merged before, it needs a `mode=release` dispatch for `v2.0.0-beta.2` (design.md "The bundle the cli pins"). See design.md "The bundle the cli pins".

**Downstream consumers:**

| Consumer | What it has to do |
| --- | --- |
| opmodel.dev | Nothing until `pull-reference-bundles`; v1.0 reads `docs/core` through the cli's pins after gate G2-switch, and the refgen retirement waits for that gate. |
| library | Nothing: library `v1.0.0-beta.1` already pins core `v2.0.0-beta.1`, the version section 2 backfills. |
| cli, opm-operator, catalog_opm, modules | Nothing. |

**Constitution.** Section 3 restores "CUE only, no Go" in `openspec/config.yaml` and `AGENTS.md`, and replaces validation gate 5 (`task docs:reference:check`) with `task docs:bundle:check`.

**Owner items:** merging docs-kit's release PRs (gate G2-core), dispatching the `v2.0.0-beta.1` backfill, checking `ghcr.io/open-platform-model/docs/core` is public on first push.
