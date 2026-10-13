# core: where do I go?

Router only. Facts and rules are in `AGENTS.md`.

| Task | Read first | Then |
| --- | --- | --- |
| Edit a schema definition (`src/*.cue`) | `.claude/skills/core-schema-edit/SKILL.md` (required) | `SPEC.md` for the definition, `src/INDEX.md` to find it |
| Add or change a schema pin or publish gate | `src/pins/` | `SPEC.md`, section 5.1 |
| Write or fix a `//` comment in CUE | `references/doc-comments.md` | `.tasks/doc-check.sh` |
| Choose a commit type, or write a breaking change | `references/commit-types.md` | `references/versioning-beta.md` |
| Release, beta policy, GA, `Release-As` | `references/versioning-beta.md` | `references/release-publishing.md` |
| A failed publish, a cascade notify or the wiring check | `references/release-publishing.md` | `RELEASING.md` at the workspace root |
| Add a definition to a docs page, or fix a released page | `references/docs-bundle.md` | `docs-kit.cue` |
| Change a site page | `docs/site/` | `STYLE.md` at the workspace root |
| Run, format or vet | `Taskfile.yml` | `AGENTS.md`, the Commands section |
| Start a feature change | `openspec/config.yaml` | `.claude/skills/openspec-new-change/SKILL.md` |
| Deliver or cite an enhancement | `references/enhancements.md` at the workspace root | `openspec/config.yaml`, the `references:` entry |
| Commit, open a PR or write GitHub text | `references/git-text.md` at the workspace root | |
