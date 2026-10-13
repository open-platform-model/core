# Commit types and release impact

Covers which Conventional Commits type to use in core, what version each type releases, and the
scoped-breaking-change syntax trap.

Releases are driven entirely by commit message types (Conventional Commits). Use the right type — a misclassified commit will either cut a release nobody needs or hide a change consumers needed to see.

| Commit type                       | Version bump                    | In changelog | Use for                                                       |
| ---                               | ---                             | ---          | ---                                                           |
| `feat:`                           | minor                           | yes          | new construct, new field, additive schema surface             |
| `fix:`                            | patch                           | yes          | wrong constraint, broken default, definition behaving wrong   |
| `perf:`                           | patch                           | yes          | schema compile-time / evaluation cost improvements            |
| `revert:`                         | patch                           | yes          | undo of a prior released change                               |
| `feat!:` / `feat(scope)!:` with a `BREAKING CHANGE:` footer (the migration note) | prerelease (advances `-beta.N` on `@v2`) | yes | removing/renaming a definition, tightening a published constraint; a break typed `feat:` or `fix:` is refused |
| `refactor:`                       | none                            | hidden       | moving files, renaming internal-only identifiers, restructuring |
| `docs:`                           | none                            | hidden       | README, design notes, comments — anything consumers don't see  |
| `style:`                          | none                            | hidden       | formatting-only changes (run `task fmt`)                       |
| `chore:`, `test:`, `ci:`, `build:` | none                           | hidden       | Taskfile, hooks, workflows, repo tooling                       |

**Rule of thumb:** if the published CUE schema is byte-identical before and after the change, it is *not* a `feat:` or `fix:`. File moves, directory restructures, doc tweaks, Taskfile edits, CI hardening — none of these warrant a release. They get `refactor:`, `docs:`, `chore:`, etc., and release-please skips them.

Examples:

- Moving `*.cue` files between directories with no content change → `refactor:`
- Adding a new `#Component` or expanding a definition's field set → `feat:`
- Tightening a regex constraint already in a published definition → `feat!:` (consumers may now fail validation)
- **With a scope, the `!` goes after the scope: `feat(identity)!:`.** The form `feat!(identity):` is NOT valid Conventional Commits syntax — release-please fails to parse it, silently classifies the commit as non-user-facing, and cuts no release (measured 2026-08-10: core PR 45 merged as `feat!(identity): …` and release-please reported "No user facing commits found"). The commit-msg hook does not catch this; check the subject by eye.
- Loosening a regex constraint → `fix:` (was rejecting things it should have accepted)
- Editing `SPEC.md` only → `docs:`
- Editing `Taskfile.yml`, hooks, workflows → `chore:` or `ci:`

If a window between releases contains only hidden-type commits, no release PR is opened. If it mixes one `feat:` with several `refactor:`/`chore:`, a release is cut but the changelog only lists the `feat:`.
