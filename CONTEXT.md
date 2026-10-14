# core: where do I go?

Router only. Facts and rules are in `AGENTS.md`.

| Task | Read first | Then |
| --- | --- | --- |
| Edit a schema definition (in `src/`) or add an exported one | `.claude/skills/core-schema-edit/SKILL.md` (required) | `SPEC.md`, `src/INDEX.md`, and `docs-kit.cue` to place a new definition on a docs page |
| Add or change a schema pin or publish gate | `src/pins/` | `SPEC.md` |
| Write or fix a `//` comment in CUE | `references/doc-comments.md` | `.tasks/` |
| Choose a commit type, or write a breaking change | `references/commit-types.md` | `references/versioning-beta.md` |
| Release, beta policy, GA, `Release-As` | `references/versioning-beta.md` | `references/release-publishing.md` |
| A failed publish, a cascade notify or the wiring check | `references/release-publishing.md` | `RELEASING.md` at the workspace root |
| Add a definition to a docs page, or fix a released page | `references/docs-bundle.md` | `docs-kit.cue` |
| Change a site page | `docs/site/` | `STYLE.md` at the workspace root |
| Run, format or vet | `Taskfile.yml` | `AGENTS.md` |
| Start a feature change | `openspec/config.yaml` | `.claude/skills/` |
| Deliver or cite an enhancement | `references/enhancements.md` at the workspace root | `openspec/config.yaml` |
| Commit, open a PR or write GitHub text | `references/git-text.md` at the workspace root | |
