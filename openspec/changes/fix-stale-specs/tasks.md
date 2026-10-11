## 1. Specs follow the code

- [x] 1.1 `specs/catalog-member-gate/spec.md`: MODIFY "`core` ships the catalog-member gate shape" and "A member's declared path must sit under its catalog's"; keep every scenario name; add three scenarios for the filing rule.
- [x] 1.2 `specs/component-matching/spec.md`: MODIFY "A component's matching identity is exactly what it attaches"; keep every scenario name; add two scenarios.
- [x] 1.3 `openspec validate fix-stale-specs --strict` and `task check` pass (`generate:index:check` differs only in the title line in a worktree folder not named `core`), then commit `docs(openspec): state the filing rule and the matching test as the code does`

## 2. Verify and archive

- [ ] 2.1 `openspec validate --all --strict`; review; fix findings.
- [ ] 2.2 Archive the change on this branch and commit `docs(openspec): archive fix-stale-specs`
