## Context

See proposal.md, Why. The dialect contract and its lint are in `orchestration.md` section 4 and 4.1. This change is row S2 of that set.

State on `origin/main` 7d91a66 (2026-09-30):

- `docs/site/` holds 11 pages: 10 under `concepts/`, 1 under `authoring/`. There is no `index.md`, no `_index.md`, no `.mdx`, no figure, no link, no code fence and no image.
- Every page opens with the same front matter: `title`, `description`, `type`, then a two-line `sidebar:` / `  order: N` block on lines 5 and 6.
- The lint (sha256 `dae9717a...973c6b`) reports 13 findings: `sidebar:` at line 5 of all 11 pages, and `:::` at lines 23 and 25 of `concepts/application-and-platform-models.md`.
- `src/` is untouched. No `src/*.cue` file, no construct in `.tasks/spec-tracked.txt`, no `SPEC.md` section and no `src/INDEX.md` line moves. No construct is newly tracked. No definition changes its closedness, defaults or required fields.

## Goals / Non-Goals

**Goals:**

- The lint reports no finding on `docs/site`.
- The page order is unchanged: the page-order helper prints the same output for `origin/main` and for the branch.
- core's gates stay green.

**Non-Goals:**

- Building or rendering the site. S workers never build it; A section 1 proves the dialect renders on fixtures, and A renders these pages from its section 2 on.
- Prose, title, description or `type` changes, and new pages.
- A `docs/site` lint in core's CI. That is a 0018:D13 follow-up, not part of this set.
- Editing `orchestration.md`, the lint, or any other repo.

## Decisions

### The edits

All edits are in `docs/site/`. Line numbers are on `origin/main`. The weight edit removes one line, so after it the aside sits one line higher (22 to 25) and the stale path sits on line 68.

**Weights.** In each file, lines 5 and 6 (`sidebar:` and `  order: N`) become one line, `weight: N`, with the same N:

| File | N |
| --- | --- |
| `authoring/define-module-configuration.md` | 22 |
| `concepts/application-and-platform-models.md` | 29 |
| `concepts/modules-and-instances.md` | 30 |
| `concepts/components-and-blueprints.md` | 31 |
| `concepts/resources-and-traits.md` | 32 |
| `concepts/how-matching-works.md` | 33 |
| `concepts/platforms-and-catalogs.md` | 34 |
| `concepts/versions.md` | 35 |
| `concepts/identity-and-names.md` | 36 |
| `concepts/who-owns-an-instance.md` | 37 |
| `concepts/what-enforces-a-rule.md` | 38 |

**Aside.** In `concepts/application-and-platform-models.md`, lines 23 to 25:

```markdown
:::note[Direction]
The platform model is meant to describe a whole platform: its global settings, the controllers and APIs it is built from, and the services it offers to teams. No design exists yet.
:::
```

become:

```markdown
> [!NOTE]
> **Direction**
>
> The platform model is meant to describe a whole platform: its global settings, the controllers and APIs it is built from, and the services it offers to teams. No design exists yet.
```

The blank line before (22) and after (26) stays. The planning comment on line 27 ("Direction note rules (0018:D3) ...") is unchanged: it names no Starlight syntax.

**Stale path.** In `authoring/define-module-configuration.md` line 69, inside the planning comment, `opmodel.dev/site/content/docs/reference/definitions/index.md` becomes `opmodel.dev/site/content/docs/reference/definitions/_index.md`. Every other repo path in core's planning comments (about 150, across core, opm, catalog_opm, cli, library, opm-operator and enhancements) resolves on its repo's `origin/main`, checked with `git cat-file -e` on 2026-09-30. So this is the only stale path.

The recipe was dry-run on a copy of `origin/main`'s `docs/site`: the lint prints `opm-dialect-lint: OK`, the page-order diff is empty, and the diff has 13 hunks in 11 files.

### Interface relied on (`orchestration.md` section 6)

This change adds no interface name. It relies on these, all owned by A:

- `task lint:sources` and check 2 (the source lint, committed as `opmodel.dev/site/scripts/lint-sources.sh`, byte-identical to 4.1). It reads core through `OPM_SRC_CORE`, mounted read-only at `/src/core`.
- Check 3 (front-matter validation in Hugo): `title`, `description`, and `type` on leaf pages.
- `_partials/sidebar.html` and `_partials/opm/section-children.html`: both order by `weight`, then title. This is what the `weight` values feed.
- Check 8 (reserved prefixes): core has no page under `docs/reference/cli/` or `docs/reference/definitions/`.
- Check 10 (no planning comment in any published output): every core page carries `<!-- ... -->` planning comments, and A keeps them out of the HTML, `llms.txt` and the Markdown outputs.
- `_partials/opm/source.html`: the "Edit" link maps each page to `core` `docs/site/<path>` on `edit/main`.

`layouts/_markup/render-link.html` is not exercised: core's pages carry no links.

## Research & Decisions

### Keep each order number as the weight

**Context**: Hugo orders a section by `weight`, then title. Sections mix pages from several repos.
**Explored**: The Authoring section interleaves three repos on `origin/main`: opm `your-first-module` 10, catalog_opm `choose-a-blueprint` 20 and `attach-a-trait` 21, core `define-module-configuration` 22, catalog_opm `use-a-raw-kubernetes-resource` 23, cli `publish-a-module` 24. Concepts is core-only (0018:D8), numbered 29 to 38.
**Decision**: `weight` MUST equal the old `order`. The weights MUST NOT be renumbered.
**Rationale**: Renumbering one repo would reorder a shared section. The unchanged page-order diff is the proof that nothing moved, and it only works if the numbers are copied.

### The direction note becomes a NOTE alert with a bold title

**Context**: The aside is the page's direction note, "a marked block" under 0018:D3. The adjacent planning comment says "Direction note rules (0018:D3)".
**Explored**: Section 4 of the contract allows NOTE, TIP, IMPORTANT, WARNING or CAUTION, alone on the marker line, with a title as a bold first line. The titled marker `> [!NOTE] Direction` and the foldable `> [!NOTE]-` are forbidden because github.com and Hextra render them differently. A plain blockquote would not be a marked block.
**Decision**: `> [!NOTE]`, then `> **Direction**`, then `>`, then the body, prefixed `> `.
**Rationale**: NOTE keeps Starlight's `note` type. The bold line keeps the "Direction" title in the only form both renderers agree on.

### The stale path names the post-migration file

**Context**: The planning comment points the author at the definitions section overview in opmodel.dev.
**Explored**: On opmodel.dev `origin/main` the file is `site/content/docs/reference/definitions/index.md`. A turns the nine site section files into `_index.md` (plan-final, A); Hugo reads an `index.md` as a leaf bundle.
**Decision**: The path MUST become `opmodel.dev/site/content/docs/reference/definitions/_index.md`, as plan-final's S recipe says.
**Rationale**: The comment should stay correct after the migration. Between this merge and A's merge it names a file that does not exist yet. That is acceptable: comments are not built, and A merges soon after.

### No repo rule or doc file changes

**Context**: O4 asks each S change to update the repo's rule and doc files that describe the Starlight or Astro format.
**Explored**: `grep -rniI -e starlight -e astro -e '\.mdx' -e sidebar -e ':::' -e 'docs/site' -e 'opmodel.dev/site'` over the repo, outside `docs/site/` and the archive, finds only Mermaid `:::` class markers in `docs/definition-types.md` (not a site page). research R3 agrees: `AGENTS.md` lines 130 and 139 describe `docs/` as schema design notes, `openspec/config.yaml` line 26 speaks of the spec, and CI's `task docs:check` is the CUE doc-comment check.
**Decision**: Touch no file outside `docs/site/`.
**Rationale**: There is no Starlight rule to rewrite. Adding a new pointer to the workspace page rules would be new scope, not a rewrite (see Open Questions).

### One section, and no spike

**Context**: core's config asks for a spike first when design.md carries an unverified assumption.
**Explored**: The lint runs over the whole tree. A partial conversion leaves it red. The recipe was dry-run on a copy of `origin/main` (lint OK, order unchanged).
**Decision**: One section, one commit: `docs(site): adopt the hugo page dialect`.
**Rationale**: No assumption is left to verify inside core. The one open fact, that Hugo renders the dialect, is proven by A section 1, which gates this merge, not this implementation.

### Gates in a worktree

**Context**: `orchestration.md` section 10 names `task check` for core. Its `generate:index:check` step compares `src/INDEX.md` with a fresh run of `.tasks/generate-index.sh`.
**Explored**: The script sets the index title from the repo directory's name (`MODULE_LABEL=$(basename "$REPO_DIR")`). In the planning worktree `task check` fails only on line 1: `# core — Definition Index` against `# plan-hugo — Definition Index`. In the change's worktree the name is `adopt-hugo-page-dialect`, so `task check` fails the same way on an untouched tree. The other four steps pass.
**Decision**: The worker runs `task -d <wt> fmt:check vet spec:check docs:check`, and checks the index with the title line normalised: `bash <wt>/.tasks/generate-index.sh <wt> | sed '1s/^# [^ ]* /# core /' | diff - <wt>/src/INDEX.md`. Both are measured green on 7d91a66. The report lists these commands on its `gates` lines and names the substitution under `deviations`, because it differs from section 10.
**Rationale**: This change touches no `src/` file, so `src/INDEX.md` cannot go stale. A title-only failure is a worktree artifact, not a finding. No known failure covers it. Section 10's core row lists one quirk only: `task fmt:check` diffs the working tree against the git index. Trap 31 ("core index diff") points back to section 10, so it means that git-index quirk, not this `src/INDEX.md` title line. Launch waits on the supervisor's ruling; see Open Questions.

## Risks / Trade-offs

- [The old Astro build on opmodel.dev `main` degrades or fails after this merges] → Accepted by the owner (O4); the site is not live. The supervisor tells the owner once S1 to S6 have merged.
- [A new core page in the old dialect after this merge breaks A's build] (`orchestration.md` section 11, trap 27) → The lint names file and line; fix the page, never the lint. No core change that adds `docs/site` pages is open on 7d91a66.
- [An invalid `type` silently picks another layout] (trap 2) → The edit leaves `type` untouched; the lint checks it.
- [`index.md` is a leaf bundle] (trap 1) → core has none and adds none.
- [Shortcodes expand inside code fences] (trap 13) → core has neither.
- [`task fmt:check` diffs the working tree against the git index] (section 10) → Stage the edits before the gates. No `.cue` file changes, so the step stays green.
- [`.claude/worktrees/` is not gitignored in core] (trap 24) → Stage explicit paths only.
- [Ticked boxes leave this change's `tasks.md` modified, so a commit of the pages alone leaves a dirty tree] → Tasks 1.5 to 1.7 count `tasks.md` as the twelfth path, stage it with the pages, and tick 1.7 just before the commit, so the section ends with checked boxes and a clean tree (Principle VI).
- [The owner's main checkout is stale] (trap 25) → Work in the change's own worktree from `origin/main`; read skills from it.
- [The history-rewrite hook refuses a branch update by the usual rewrite] (trap 34) → Update the branch by merging `origin/main`.
- [No existing core tag can be built] (trap 36) → Out of scope. The first post-merge tag needs another releasable commit or a `Release-As:` footer (change B and the owner).
- [The weight step runs before the aside step and shifts line numbers] → Locate the aside and the path by their text, not by line number.

## Migration Plan

Merge as one squash PR after A section 1 is green. Rollback is a revert of that commit; no consumer pins it.

## Open Questions

- Should `orchestration.md` section 10 list the `generate:index:check` worktree title failure as known for core, with the title-normalised diff as its substitute? Trap 31 does not cover it (see "Gates in a worktree"). The supervisor rules before launch: either a planning commit adds the quirk to section 10's core row in every copy of `orchestration.md`, or the launch message confirms the substitution. Launch waits on that ruling, because the orchestration header says a worker stops when this file and its change's artifacts disagree, and task 1.1 stops without it. The ruling changes neither the edits nor the task breakdown.
- Should core's `AGENTS.md` name `docs/site/` beside `docs/` (lines 130 and 139) and point at the workspace page rules, as S1 does for opm's `docs/STYLE.md`? plan-final gives S2 no such edit, so it stays out unless the supervisor adds it.
