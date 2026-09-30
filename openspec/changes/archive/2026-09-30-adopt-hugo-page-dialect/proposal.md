## Why

opmodel.dev moves from Astro + Starlight to Hugo + Hextra, and the owner ruled that the source pages are rewritten to the Hugo dialect now, with no compatibility layer (owner decision O4). core's eleven Concepts and authoring pages under `docs/site/` still use Starlight syntax: a `sidebar:` / `order:` block in every page and one `:::note` aside. The new site's source lint rejects both, so core's pages must change before the site can build them.

core owns every Concepts page (0018:D8), so the whole Concepts section of the new site comes from this repo.

## What Changes

- Every `sidebar:` block with `  order: N` becomes `weight: N`, with the same number, in all 11 pages under `docs/site/`.
- The Starlight aside `:::note[Direction]` ... `:::` in `docs/site/concepts/application-and-platform-models.md` becomes a GitHub alert: `> [!NOTE]`, then `> **Direction**`, then `>`, then the body. It is the page's direction note (0018:D3), so it stays a note.
- One stale planning-comment path in `docs/site/authoring/define-module-configuration.md` moves from `opmodel.dev/site/content/docs/reference/definitions/index.md` to `.../_index.md`, the file the Hugo site uses for that section.
- Nothing else. Titles, descriptions, `type` values (0018:D7:R1), prose and planning comments are unchanged. No page is added, removed or renamed. core has no `index.md`, no `.mdx`, no figures, no links and no code fences under `docs/site/`, so none of the other dialect rules produce an edit.
- No repo rule or doc file needs an edit. `AGENTS.md`, `README.md`, `openspec/config.yaml`, `.claude/skills/` and CI never describe the Starlight or Astro format; `AGENTS.md` lines 130 and 139 describe `docs/` only as schema design notes. The site page rules live in the workspace `STYLE.md` "Site Pages" section (I1a, done).

After this change, the dialect lint from `orchestration.md` 4.1 reports nothing on core's `docs/site`. On `origin/main` (7d91a66) it reports 13 findings: 11 `sidebar:` lines and the two `:::` lines of the aside.

## Capabilities

### New Capabilities

None. `docs/site` pages only; `.openspec.yaml` sets `skip_specs: true`.

### Modified Capabilities

None.

## Impact

**Release classification: `docs:`, no release.** The published CUE module is `src/`. It is byte-identical before and after, so Principle I's breaking test does not apply and nothing relies on the v2 line being in prerelease (Principle IV). `docs` commits are hidden from release-please, so the merge opens no release PR. Principle V: no schema surface is added.

**Downstream consumers:**

| Consumer | What it has to do |
| --- | --- |
| `opmodel.dev` | Change A (`port-site-to-hugo-hextra`) builds these pages from its section 2 on, and lints them before every build. Between this merge and A's merge, the old Astro build on opmodel.dev `main` renders degraded or fails. The owner accepted this (O4); the site is not live. |
| `library`, `cli`, `opm-operator`, `catalog_opm`, `modules`, `opm-modules` | Nothing. No schema value changes, and `docs/site` is not part of the published module. |
| In-flight core changes that add or edit `docs/site` pages | After this merges, any new page must use the new dialect, or A's lint fails the site build. None is open on 7d91a66: `fold-colliding-contract-keys`, the one plan-final listed, merged as core PR 80. |

**Tags.** No core tag cut before this merge can be built by the new site, because every such tag carries `sidebar:` front matter. Because `docs` commits cut no release, core's first tag after this merge needs another releasable commit or a `Release-As:` footer. That is change B's concern (`version-site-from-tags`) and the owner's, not this change's.

**Enhancement 0018.** The change applies 0018:D7 and 0018:D7:R1 (title, description and type stay as declared), 0018:D7:R3 (a page's address still follows from its path) and 0018:D3 (the direction note stays a marked block). It adds no delivery claim, so the change carries no `enhancement.yaml` (supervisor ruling O7).

**Depends on:** starts when this change is planned on main. Merges when verify is green, after A section 1 is green, and before A section 2 (`orchestration.md` section 2, row S2).

**Touches:** `docs/site/**` (11 files, 13 edits), plus this change's own directory under `openspec/changes/`, whose archive rides the PR.
