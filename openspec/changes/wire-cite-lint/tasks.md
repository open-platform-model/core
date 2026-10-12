## 1. Pin

- [x] 1.1 Move the `cascade-notify` reference in `release.yml` from `0f9c6ac2` to `2b66da51fede4332969c324b069012632d8edea9`; replace `.tasks/cascade/wiring-check.sh` with the copy at that SHA; `task cascade:wiring:check` passes. Commit `ci(deps): pin the cascade to .github 2b66da5`.

## 2. Wire

- [ ] 2.1 Add the `cite-lint` job to `ci.yml`; declare `{file: ci.yml, kind: cite-lint}` in `wiring-check.yaml`; `task cascade:wiring:check` passes. Commit `ci: call the shared cite-lint workflow`.
- [ ] 2.2 Add `task cite-lint` to `Taskfile.yml` and list it in `AGENTS.md`; it reports 0 findings. Commit `build: add task cite-lint`.

## 3. Verify and archive

- [ ] 3.1 `openspec validate wire-cite-lint --strict`, `task check`, `task cite-lint`, actionlint and zizmor on the changed workflows.
- [ ] 3.2 Review, fix, archive on the branch.
