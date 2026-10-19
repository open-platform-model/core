## 1. Rewrite the 34 long requirements (core-B1 and core-B2, 14 specs)

Per spec: read the requirement and its scenarios on `main`; pick the form (design); write the ledger into `design.md`; write `specs/<spec>/spec.md` as a delta; run the byte-equal command (guide checklist item 3) for each rewritten requirement; run the grep for the old header; run the gate in a scratch copy with the running `N`. One delta file per spec; a spec is done when its requirements show no long-requirement warning.

- [x] 1.1 `artifact-identity` (1), `definitions-reference` (1), `docs-bundle` (1), `instance-identity` (1)
- [x] 1.2 `name-constraints` (1), `platform-registry` (1), `transformer-context` (1); gate run, `N` = 7
- [ ] 1.3 `schema-pins` (2), `primitive-keying` (3), `catalog-contracts` (3); gate run, `N` = 15
- [ ] 1.4 `contract-fulfilment` (4), `platform-contract-inventory` (7); gate run, `N` = 26
- [ ] 1.5 `release-cascade` (3), `schema-release` (5); gate run, `N` = 34
- [ ] 1.6 Review the clause tables and the ledger: every old scenario is in a new place; no `**Key**:` line, level 5 heading or fenced block in a changed body; no stale reference; each new body has SHALL or MUST and scenarios in both directions where the behavior has a rejection
- [ ] 1.7 `task check` green in a scratch copy of the worktree named `core`, then commit `docs(openspec): split the long requirements of the core specs` (one commit per task 1.1 to 1.5 is allowed)

## 2. Write the Purpose of `cite-lint`

- [ ] 2.1 Replace the placeholder under `## Purpose` in `openspec/specs/cite-lint/spec.md` with real text; the three requirements stay as they are
- [ ] 2.2 Gate run in a scratch copy: the `cite-lint` warning is gone; `task check` green, then commit `docs(openspec): write the Purpose of cite-lint`

## 3. Add the pinned OpenSpec gate

- [ ] 3.1 `Taskfile.yml`: variable `OPENSPEC_VERSION: 1.14.1`, task `openspec:install` (`npm install -g --ignore-scripts`), task `openspec:check` (version precondition, `openspec validate --all --strict --no-interactive`), wired last into `check` and its description
- [ ] 3.2 `.github/workflows/ci.yml`: after the wiring step in job `ci`, a SHA-pinned `setup-node` step, `task openspec:install`, `task openspec:check`; no new permission, no secret
- [ ] 3.3 Run `task cascade:wiring:check` and `task openspec:check`; record the release age of 1.14.1 against the cooldown rule; `task check` green in the scratch copy named `core`, then commit `ci: gate the main specs with openspec validate --strict`

## 4. Final gate (LAST=1)

- [ ] 4.1 Run the gate of guide section 6 with `LAST=1`, `N` = 34: `validate split-long-requirements --strict` exits 0, archive exits 0, `validate --specs --strict` exits 0, no "Archive would refuse" line, no new ERROR item; also `openspec validate --all --strict` exits 0 (core has no other open change)
- [ ] 4.2 Run the review checklist of the guide (items 1 to 14) and record each result in the report
- [ ] 4.3 Archive the change on the branch (`openspec-archive-change`), `task check` green in the scratch copy named `core`, then commit `docs(openspec): archive split-long-requirements`
