## Why

opmodel.dev's Reference tab has a placeholder at `/docs/reference/definitions/` that other pages already link. The workspace page rules (`STYLE.md`, "Site Pages") say reference facts are generated in the repository that owns their source, committed under `docs/site/reference/` with a staleness check, and that a generated entry states only what its source proves. core owns every definition, so the definitions reference is generated here.

Owner decisions (2026-10-02): the reference is generated from the CUE definitions' own doc comments plus their shape in source, not projected from `SPEC.md`; core definitions carry no `metadata.description`, so an entry's summary is its doc comment's first sentence; every entry follows one order (summary, at a glance, spec, example, notes, served by, enforcement), omitting a part with nothing derivable; enforcement is tagged only where derivable (a schema constraint is enforced by CUE).

## What Changes

- A Go generator, `tools/refgen/` (its own Go module on `cuelang.org/go` v0.17.1, the version `cli` and `library` use), parses `src/*.cue` with `cue/parser`, without evaluating, and writes `docs/site/reference/definitions/`: a section page (`_index.md`, URL `/docs/reference/definitions/`) and eight group pages of `type: reference`.
- An inclusion list in `tools/refgen/groups.go` places every exported top-level definition of a non-fixture file on one page or excludes it with a reason. The generator refuses to run when a definition is in neither, so a new one cannot be left out silently.
- Doc comments are filtered deterministically: `// WHY` blocks never reach a page (they are not doc comments), and enhancement citations, `SPEC.md` pointers and experiment references are stripped from what is left.
- Doc-comment edits in `src/` (no schema change): doc comments for `#Component`, `#SecretType` and `#LabelsAnnotationsType`, which had none; rewrites of `#ModuleInstance`, `#ComponentTransformer` and `#VersionType`, whose comments read badly as prose; and removal of stale file paths, a pointer to a rationale block, a promise of future work and two lines of rename history.
- Tasks `docs:reference`, `docs:reference:check` and `refgen:test`, the last two wired into `task check` and CI (`ci.yml` gains a pinned `actions/setup-go` step).
- `AGENTS.md`, `openspec/config.yaml` and `README.md` stop calling the repo Go-free: the schema is pure CUE, and the reference generator is the one Go program, never part of the published module.

## Capabilities

### New Capabilities

- `definitions-reference`: the generated definitions reference, what it includes, what each entry states, and the check that keeps it in step with `src/`.

### Modified Capabilities

None.

## Impact

**Release classification: `docs:`, no release.** No definition, constraint, default or closedness changes; only doc comments in `src/*.cue` and `src/INDEX.md` move, so the published module's bytes change in comments alone and ride the next release. Principle I's breaking test does not apply, nothing relies on the beta break licence, and no `catalogs/opm` major is involved. Principle V: no schema surface is added.

**SPEC.md.** No tracked construct changes behaviour, so no section moves; the doc-comment commit uses the `SPEC_IMPACT=none` escape and the PR body carries `Spec-Impact: none`.

**Downstream consumers:**

| Consumer | What it has to do |
| --- | --- |
| `opmodel.dev` | Its placeholder at `docs/reference/definitions/_index.md` must yield to a source page (`placeholder: true`); that change is in flight separately. Once both land, the site builds these pages. |
| `library`, `cli`, `opm-operator`, `catalog_opm`, `modules` | Nothing. Doc comments are not part of any contract. |

**Constitution.** The Technology Standards in `openspec/config.yaml` said "CUE only. No Go"; they now scope CUE-only to the schema and name `tools/refgen/` as the one Go program, as the owner decision to keep generators in the owning repository requires.
