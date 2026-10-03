## Context

core publishes `opmodel.dev/core@v2` from `src/` on each release-please release (`release.yml` job `publish-cue`). Its site pages are `docs/site/` (authored concepts and authoring pages) plus `docs/site/reference/definitions/` (nine pages written by `tools/refgen` and checked by `task docs:reference:check`, `Taskfile.yml` lines 74-103, `ci.yml` lines 52-64). opmodel.dev's v1.0 is a line version: it reads core's `docs/site/` from `main` while `main` still releases the minor (`opmodel.dev/site/versions.conf`).

docs-kit contracts read: C5 (`publish.yml`, its modes and caller permissions), C6 (`docs-kit.cue`, `markdown` `include`/`exclude`), C9 (signing identity, tag-pinned `publish.yml`), C12 (`.opm-docs-version`, the local tool install), C14 (repository commands; core runs none), C15 (docs placement, `owns`), C17 (`cue-definitions`). They are defined by docs-kit's `generalize-build-assembly`, `add-cue-definitions-extractor` and `add-authored-docs`. The reference adopter is catalog_opm: `.github/workflows/docs.yml`, `release.yml` job `publish-docs`, `Taskfile.yml` tasks `tools:opm-docs`, `docs:bundle`, `docs:pins:check`, `docs:bundle:check`, and `.tasks/opm-docs.sh`.

No `src/*.cue` file changes, so no construct in `.tasks/spec-tracked.txt` moves and no `SPEC.md` section changes; no definition's closedness, defaults or required fields change.

## Goals / Non-Goals

**Goals:** core's docs bundle with its authored pages and its generated reference at the same URLs as today; publishing on every release; deleting refgen once the site reads the bundle.

**Non-Goals:** new or reworded doc comments; the site's switch; the library and cli releases of the cascade.

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
		// still reads core from git; section 3 deletes both.
		kind: "markdown", dir: "docs/site", exclude: ["reference/definitions/"]
	}]
}
```

`citations` stays at its default, `strip`, which is refgen's rule ("Contributor-only text never reaches a page"). The entries the bundle generates MUST equal refgen's committed pages without their marker comments; a difference is either fixed in docs-kit before G2-core or accepted as a planned difference in C17's parity record (docs-kit `add-cue-definitions-extractor` task 2.2). Section 1 checks it again at core's adopting commit, because core may change doc comments after docs-kit's parity run.

### D2. Two placement lists until section 3

Between sections 1 and 3 a new exported definition must be placed in both `tools/refgen/groups.go` (else `task docs:reference:check` fails) and `docs-kit.cue` (else `task docs:bundle:check` fails, C17 D3). Both checks run in `task check`, so neither list can be forgotten; keeping the same page is a review matter. `openspec/config.yaml`'s tasks rule names both lists for that window, and section 3 reduces it to `docs-kit.cue`.

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

Nothing changes on the site at section 1: v1.0 reads core from git, and the bundle is not pulled until opmodel.dev's `pull-reference-bundles` section 2 (G2-switch). From G2-switch, v1.0 shows the `docs/core` bundle of the core version the cli pins, so an authored fix on `main` reaches the site only through the next release or a docs revision (`docs.yml` dispatch `mode: revision`, C3 "Docs revisions"). `AGENTS.md`'s new paragraph says so.

### D6. Section 3 at G2-switch

Delete `tools/refgen/` (with `go.mod`, `go.sum`, tests), `docs/site/reference/definitions/`, the `docs:reference`, `docs:reference:check` and `refgen:test` tasks and their place in `task check`, `ci.yml`'s "Setup Go", "Test the reference generator" and "Verify the definitions reference is up to date" steps, and the `exclude`. The `markdown` source becomes `{kind: "markdown", dir: "docs/site"}`. `src/INDEX.md`'s hand-maintained tree loses `tools/refgen/` (`task generate:index:check` stays green). Released bundles are unaffected: they were built with the exclude and the extractor's pages.

## Research & Decisions

### The release that carries the first bundle

**Context**: The owner wants a fresh core release rather than a backfill of `v2.0.0-beta.1`, because the doc comments the reference shows were rewritten after that tag (core PRs 88 to 92, among them the change that gave `#Component`, `#SecretType` and `#LabelsAnnotationsType` their doc comments). But every core commit since `v2.0.0-beta.1` is `docs:`, `ci:` or `chore:`, which release-please hides, and this change adds only more of the same.
**Explored**: `git log v2.0.0-beta.1..main` (12 commits, none releasable); `AGENTS.md` ("Commit conventions and release impact": a byte-identical schema is never `feat:` or `fix:`; never add a `release-as` key); docs-kit `docs/orchestration.md` (no `Release-As:` footers: squash merges use a blank body).
**Decision**: Section 2 publishes from the next core release, whatever carries it. If the owner needs the bundle before a releasable commit lands, the fallback is the dispatched backfill `mode: release`, `tag: v2.0.0-beta.1`, which builds (D3) but shows beta.1's older doc comments and authored pages. The choice is the owner's and is recorded in section 2.
**Rationale**: Forcing a release breaks two written rules (commit type by schema bytes; no `release-as`); the backfill is the documented recovery path and works for this tag.

### `publish-docs` gating

**Context**: catalog_opm gates on a `published` output of its publish job, with `always()`. core's `publish-cue` has no such output.
**Decision**: `needs: [release-please, publish-cue]` with `if: release_created == 'true'`, so a failed `publish-cue` skips the docs (default `success()` on needs).
**Rationale**: A bundle for a version GHCR does not hold would document a module nobody can fetch; the dispatch recovers a skipped bundle.

### Exclude by directory

**Decision**: `exclude: ["reference/definitions/"]` (a directory pattern, C6), not the nine file names.
**Rationale**: refgen owns the whole directory; a page it adds or removes before section 3 needs no config edit.

## Risks / Trade-offs

- Parity drift between docs-kit's recorded parity run and core's adopting commit: section 1 checks it (task 1.6) and stops for a docs-kit fix rather than accept an unplanned difference.
- Site freshness changes at G2-switch (D5): authored fixes on `main` no longer appear on the next site build. The workspace `AGENTS.md` rule "A docs-only fix in `core` ... cuts no release: `opmodel.dev` builds their docs from ... `main`" stops being true then; it is a workspace edit outside this change.
- The two placement lists can disagree on a page between sections 1 and 3 (D2).
