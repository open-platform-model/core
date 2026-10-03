## Context

core publishes `opmodel.dev/core@v2` from `src/` on each release-please release (`release.yml` job `publish-cue`). Its site pages are `docs/site/` (authored concepts and authoring pages) plus `docs/site/reference/definitions/` (nine pages written by `tools/refgen` and checked by `task docs:reference:check`, `Taskfile.yml` lines 74-103, `ci.yml` lines 52-64). opmodel.dev's v1.0 is a line version: it reads core's `docs/site/` from `main` while `main` still releases the minor (`opmodel.dev/site/versions.conf`).

docs-kit contracts read: C5 (`publish.yml`, its modes and caller permissions), C6 (`docs-kit.cue`, `markdown` `include`/`exclude`), C9 (signing identity, tag-pinned `publish.yml`), C12 (`.opm-docs-version`, the local tool install), C14 (repository commands; core runs none), C15 (docs placement, `owns`), C17 (`cue-definitions`). They are defined by docs-kit's `generalize-build-assembly`, `add-cue-definitions-extractor` and `add-authored-docs`. The reference adopter is catalog_opm: `.github/workflows/docs.yml`, `release.yml` job `publish-docs`, `Taskfile.yml` tasks `tools:opm-docs`, `docs:bundle`, `docs:pins:check`, `docs:bundle:check`, and `.tasks/opm-docs.sh`.

Two comments change in `src/catalog.cue` and `src/identity_package.cue` (comment text only); no construct in `.tasks/spec-tracked.txt` moves, no `SPEC.md` section changes, and no definition's closedness, defaults or required fields change.

## Goals / Non-Goals

**Goals:** core's docs bundle with its authored pages and its generated reference at the same URLs as today; publishing on every release; deleting refgen once the site reads the bundle.

**Non-Goals:** doc-comment rewrites beyond the two comments with enhancement prose; the site's switch; the library and cli releases of the cascade.

## Decisions

### D1. `docs-kit.cue`

The page and exclusion lists move verbatim from `tools/refgen/groups.go` (order kept). The section title, description and weight are those of today's `_index.md`.

```cue
bundles: core: {
	placement: {kind: "docs", root: "/docs/", owns: ["reference/definitions/"]}
	version: {from: "tag", prefix: "v"}
	sources: [{
		kind:        "cue-definitions"
		package:     "./src"
		skip:        ["*_pins.cue"]
		section:     "reference/definitions/"
		title:       "Definitions"
		description: "Every OPM definition type, generated from the CUE schema in core."
		weight:      1
		pages: [
			{file: "modules-and-instances", title: "Modules and instances", description: "The module an author publishes, the instance that deploys it, and the identity the instance hands its components.", definitions: ["#Module", "#ModuleInstance", "#InstanceIdentity"]},
			{file: "components", title: "Components", description: "The component a module is built from, and the names it computes for itself.", definitions: ["#Component", "#ComponentNames"]},
			{file: "resources-traits-and-blueprints", title: "Resources, traits and blueprints", description: "The three primitives a catalog defines and a component attaches.", definitions: ["#Resource", "#Trait", "#Blueprint"]},
			{file: "transformers", title: "Transformers", description: "The transformer that turns a matched component into platform objects, and the context it renders with.", definitions: ["#ComponentTransformer", "#TransformerContext"]},
			{file: "catalogs-and-platforms", title: "Catalogs and platforms", description: "The catalog that publishes contracts and transformers, and the platform that admits catalogs.", definitions: ["#Catalog", "#Platform", "#CatalogEntry", "#ContractInventory"]},
			{file: "publish-gates", title: "Publish gates", description: "The definitions a publishing tool unifies an artifact against before it publishes.", definitions: ["#IdentityPackage", "#CatalogMemberFQNGate", "#TraitOptionalGate"]},
			{file: "secrets-and-config", title: "Secrets and configuration", description: "The secret type module authors put on sensitive values, and the Secret and ConfigMap schemas catalogs build on.", definitions: ["#Secret", "#SecretType", "#SecretLiteral", "#SecretK8sRef", "#AutoSecrets", "#SecretSchema", "#ConfigMapSchema"]},
			{file: "names-paths-and-versions", title: "Names, paths and versions", description: "The constraint types for names, module and package paths, versions, keys and labels.", definitions: [
				"#NameType", "#ObjectNameType", "#ServiceNameType", "#SnakeNameType",
				"#ModulePathType", "#PackagePathType", "#ArtifactRef",
				"#MajorVersionType", "#APIVersionType", "#APIVersionGated", "#VersionType",
				"#ContractFQNType", "#ImplFQNType", "#FQNType",
				"#UUIDType", "#LabelsAnnotationsType",
			]},
		]
		exclude: {
			"#BlueprintMap":        "map shorthand"
			"#ComponentMap":        "map shorthand"
			"#ModuleMap":           "map shorthand"
			"#ModuleInstanceMap":   "map shorthand"
			"#ResourceMap":         "map shorthand"
			"#TraitMap":            "map shorthand"
			"#TransformerMap":      "map shorthand"
			"#KebabToPascal":       "string helper"
			"#KebabToCamel":        "string helper"
			"#DiscoverSecrets":     "internal step of #AutoSecrets"
			"#GroupSecrets":        "internal step of #AutoSecrets"
			"#ContentHash":         "naming helper for transformers"
			"#SecretContentHash":   "naming helper for transformers"
			"#ImmutableName":       "naming helper for transformers"
			"#SecretImmutableName": "naming helper for transformers"
			"#BundleFQNType":       "types #Bundle, which core does not define"
		}
	}, {
		// The authored pages ship in the same bundle (docs-kit DESIGN decision
		// 20). The exclude keeps refgen's committed pages out while the site
		// still reads core from git; both go at G2-switch.
		kind: "markdown", dir: "docs/site", exclude: ["reference/definitions/"]
	}]
}
```

`citations` stays at its default, `strip`, which is refgen's rule ("Contributor-only text never reaches a page"). `strip` removes a citation in canonical form (`0010:D21`) but not prose such as "enhancement 0011's publish gates" or a list of bare `D21, D25`; the two comments that hold such prose (`src/catalog.cue:100-108`, `src/identity_package.cue:139-143`) are reworded in section 1, in a doc-comment-only commit (`SPEC_IMPACT=none`), and the parity check looks for any other. The entries the bundle generates MUST equal refgen's committed pages without their marker comments; a difference is either fixed in docs-kit before G2-core or accepted as a planned difference in C17's parity record (docs-kit `add-cue-definitions-extractor` task 2.2). Section 1 checks it again at core's adopting commit, because core may change doc comments after docs-kit's parity run.

**As adopted (section 1, docs-kit `v0.4.0`).** `docs-kit.cue` is the config docs-kit's extractor was tested with (`internal/extract/cuedefs/testdata/core-docs-kit.cue` on docs-kit `main`) plus the `markdown` source, so it follows C17 as shipped rather than the block above: it adds `intro` with refgen's index sentence (without it the index would read only "Every definition below belongs to `opmodel.dev/core@v2`."), and `citations` stays unset (the default, `strip`). `skip: ["*_pins.cue"]` stays although the pins moved to `src/pins/` (core PR 103) and the extractor reads only `src/`'s own files: `v2.0.0-beta.1`, the backfill, still carries them in `src/`. The page and exclusion lists equal `tools/refgen/groups.go`'s (checked name by name and description by description).

**Parity at the adopting commit** (branch `ci/publish-definitions-bundle`, on `main` `606498b` plus the comment commit): `task docs:bundle` wrote `out/core/` with 20 pages (9 generated, 11 authored). The nine pages under `out/core/content/reference/definitions/` equal refgen's committed pages byte for byte once refgen's start marker (with its following blank line) and end marker (with its preceding blank line) are removed: no difference, planned or not. No page holds citation prose (`grep -E "enhancement|[0-9]{4}:D[0-9]|D[0-9]+|SPEC\.md|experiment"` over them finds nothing). The two reworded comments never reached a page (one is a `// WHY` block, the other a non-doc comment inside `#Catalog`'s spec, which the extractor drops), so the reword is for the citation rule, not the output.

### D2. Two placement lists until G2-switch

Between adoption and G2-switch a new exported definition must be placed in both `tools/refgen/groups.go` (else `task docs:reference:check` fails) and `docs-kit.cue` (else `task docs:bundle:check` fails, C17 D3). Both checks run in `task check`, so neither list can be forgotten; keeping the same page is a review matter. `openspec/config.yaml`'s tasks rule names both lists for that window, and the retirement at G2-switch reduces it to `docs-kit.cue`.

### D3. Publishing

`docs.yml` is catalog_opm's with `project: core` and the tag form `vX.Y.Z`. Its dispatch comment states the backfill floor: release mode builds a tag's `src/` and `docs/site/` with `main`'s config, which works for `v2.0.0-beta.1` and later (`src/cue.mod/module.cue` and `*_pins.cue` exist there; C17 D3 downgrades unplaced or unknown names to warnings for a config from outside the tree).

`release.yml` gains, after `publish-cue`:

```yaml
  publish-docs:
    name: Publish the core docs bundle
    needs: [release-please, publish-cue]
    # Runs only when the module reached GHCR: a failed publish-cue skips it,
    # and docs.yml's release mode recovers a release without a bundle.
    if: needs.release-please.outputs.release_created == 'true'
    permissions:
      contents: read
      packages: write
      id-token: write
    # Pinned by docs-kit release tag, not a SHA: the signing certificate names
    # publish.yml at this ref, and the site trusts only docs-kit's v* tags
    # (docs-kit C5, C9). Moves with .opm-docs-version in one PR.
    uses: open-platform-model/docs-kit/.github/workflows/publish.yml@vX.Y.Z
    with:
      project: core
      mode: release
      tag: ${{ needs.release-please.outputs.tag_name }}
```

`vX.Y.Z` is the first docs-kit release that meets G2-core, written into `.opm-docs-version` and every `publish.yml` ref together. The job runs in the workflow run of the push that merged the release PR, never on `release: published` (C5, docs-kit DESIGN decision 9). The workflow's top-level `permissions` (`contents: write`, `pull-requests: write`, `packages: write`, `actions: write`) stay; the job narrows them.

### D4. Local tasks

`Taskfile.yml` gains catalog_opm's four tasks with `--project core`; `.tasks/opm-docs.sh` is copied byte for byte; `.gitignore` gains `/out/` and `/.bin/`. `task check` runs `docs:bundle:check` (pins agree, then `opm-docs check --project core`, which builds and lints without publishing). The check needs network access for the opm-docs download on first use, as catalog_opm's does.

### D5. What the site sees, and when

Nothing changes on the site at adoption: v1.0 reads core from git until gate G2-switch, when opmodel.dev's `pull-reference-bundles` switches it to bundles. From G2-switch, v1.0 shows the `docs/core` bundle of the core version the cli pins, so an authored fix on `main` reaches the site only through the next release or a docs revision (`docs.yml` dispatch `mode: revision`, C3 "Docs revisions"), which is dispatched by hand (automation: core#101). `AGENTS.md`'s new paragraph says so.

### D6. Retiring refgen at G2-switch and G2-edge

**Gate.** G2-switch holds (opmodel.dev#38, 2026-10-04: v1.0 reads core 2.0.0-beta.2 from its bundle). G2-edge is opmodel.dev `add-edge-build` section 2 merged: the site's `sources-main` job, which checks every repository's `main` together, then reads core's `main` from its `edge` docs bundle instead of from a `main` checkout. Retiring earlier would leave that job reading a `docs/site/` without `reference/definitions/`, failing every `main` page that links a definition page until the edge build lands (owner decision 2026-10-04 on `pull-reference-bundles` OQ1: the edge build, not a narrower check).

Delete `tools/refgen/` (with `go.mod`, `go.sum`, tests), `docs/site/reference/definitions/`, the `docs:reference`, `docs:reference:check` and `refgen:test` tasks and their place in `task check`, `ci.yml`'s "Setup Go", "Test the reference generator" and "Verify the definitions reference is up to date" steps, and the `exclude` with its comment in `docs-kit.cue`. The `markdown` source becomes `{kind: "markdown", dir: "docs/site"}`. The `Taskfile.yml` comments that explain the committed pages go with them: the "Generated definitions reference" block and the last sentence of the "Docs bundle" block ("Until opmodel.dev reads the bundle, ..."). `src/INDEX.md`'s hand-maintained tree loses `tools/refgen/` (`task generate:index:check` stays green). Released bundles are unaffected: they were built with the exclude and the extractor's pages.

## Research & Decisions

### The bundle the cli pins: a backfill of `v2.0.0-beta.1`

**Context**: Gate G2-pins needs a `docs/core` bundle for the core release the cli's pinned library names. The cli's `main` pins library `v1.0.0-beta.1`, whose `DefaultSchemaModule` is `opmodel.dev/core@v2.0.0-beta.1`. One releasable commit has landed on core's `main` since that tag: `606498b` `perf(pins)` (core PR 103), which moved the pins into `src/pins/`. Release PR core#106 (`2.0.0-beta.2`) is open for it. This change adds no releasable commit (`ci:`, `docs:` and one `chore:`).
**Explored**: `git log v2.0.0-beta.1..main` (one releasable commit, `606498b` `perf(pins)`, with release PR core#106 open); the tree at `v2.0.0-beta.1` (`src/cue.mod/module.cue`, `*_pins.cue`, `docs/site/` present, no `reference/definitions/`); C5 release mode (config from `main`, sources from the tag) and C17 D3 (unplaced or unknown names are warnings for a config from outside the tree); `AGENTS.md` (a byte-identical schema is never `feat:` or `fix:`, no `release-as`).
**Decision**: the owner's (2026-10-03): the first `docs/core` bundle is the release-mode backfill of `v2.0.0-beta.1`, dispatched once section 1 is on `main`; the library needs no re-pin. A fresh core release is optional and publishes through `publish-docs` whenever one is cut. **Merge order with core#106 (`2.0.0-beta.2`):** this change's PR (core#107) merges first, so the `v2.0.0-beta.2` release run already has `publish-docs` and publishes its bundle. If core#106 merges first, dispatch `gh workflow run docs.yml --ref main -f mode=release -f tag=v2.0.0-beta.2` once core#107 is on `main`. Either way the cli's pin is still `v2.0.0-beta.1`, so its backfill stays. Section 1 dry-runs the backfill locally first (`opm-docs build --release v2.0.0-beta.1 --source <tag worktree>` with `main`'s config).
**Rationale**: the backfill needs no release and keeps the pins the cli already has. Its cost: the bundle shows beta.1's doc comments and authored pages, which predate the readable doc comments of core PRs 88 to 92. A docs revision (`mode: revision`, one comment-only or Markdown-only commit at a time) can bring later fixes into that bundle; revisions are manual for now (core#101, tracked in docs-kit#16).

**Dry run (section 1).** In a scratch worktree of `v2.0.0-beta.1` (commit `4f9b245`), run from this change's checkout with `main`'s config and opm-docs `v0.4.0`:

```text
.bin/opm-docs build --project core --release v2.0.0-beta.1 --source <beta.1 worktree> --config docs-kit.cue --out <scratch>
```

Exit 0, 20 pages (the nine reference pages and the eleven authored pages beta.1's `docs/site/` holds; the tree has no `reference/definitions/`, so the `exclude` matches nothing, which a backfill ignores), version `2.0.0-beta.1`, `source.ref` `v2.0.0-beta.1`, 11 pages with an `edit` path. `opm-docs lint --bundle` of the result: OK. Three C17 D3 warnings, all "has no summary" (doc comment missing or holding nothing a reader sees): `#Component` (`src/component.cue`), `#SecretType` (`src/schemas.cue`), `#LabelsAnnotationsType` (`src/types.cue`); each keeps an empty summary. No unplaced or unknown names. This matches C17's parity record ("three warnings").

### `publish-docs` gating

**Context**: catalog_opm gates on a `published` output of its publish job, with `always()`. core's `publish-cue` has no such output.
**Decision**: `needs: [release-please, publish-cue]` with `if: release_created == 'true'`, so a failed `publish-cue` skips the docs (default `success()` on needs).
**Rationale**: A bundle for a version GHCR does not hold would document a module nobody can fetch; the dispatch recovers a skipped bundle.

### Exclude by directory

**Decision**: `exclude: ["reference/definitions/"]` (a directory pattern, C6), not the nine file names.
**Rationale**: refgen owns the whole directory; a page it adds or removes before G2-switch needs no config edit.

## Risks / Trade-offs

- Parity drift between docs-kit's recorded parity run and core's adopting commit: section 1 checks it (task 1.6) and stops for a docs-kit fix rather than accept an unplanned difference.
- Site freshness changes at G2-switch (D5): authored fixes on `main` no longer appear on the next site build; they need a manual docs revision (core#101). The workspace `AGENTS.md` rule "A docs-only fix in `core` ... cuts no release: `opmodel.dev` builds their docs from ... `main`" stops being true then; docs-kit's orchestration schedules that workspace edit at G2-switch.
- The backfilled bundle shows `v2.0.0-beta.1`'s older doc comments until a revision or a new release replaces it.
- The two placement lists can disagree on a page between sections 1 and 3 (D2).
