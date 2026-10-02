## 1. Doc comments the reference can use

Doc-comment edits only; no constraint, default or closedness changes, so the commit uses `SPEC_IMPACT=none`.

- [x] 1.1 `src/component.cue`, `src/schemas.cue`, `src/types.cue`: add doc comments to `#Component`, `#SecretType` and `#LabelsAnnotationsType`
- [x] 1.2 `src/module_instance.cue`, `src/transformer.cue`, `src/types.cue`: rewrite the `#ModuleInstance`, `#ComponentTransformer` and `#VersionType` doc comments as sentences
- [x] 1.3 `src/platform.cue`, `src/catalog.cue`, `src/component.cue`, `src/schemas.cue`: drop the stale `resources/config/*.cue` paths, the pointer to a WHY block, the future-work promise on `#Platform.type` (kept in its WHY block), the `Materialize` and `#CatalogFQNType` history and a "see below"
- [x] 1.4 `task generate:index` (definitions table only; the tree changes in section 2)
- [x] 1.5 `task check` green, then commit `docs(core): give the public definitions readable doc comments` with `SPEC_IMPACT=none`

## 2. Generate the definitions reference

- [x] 2.1 `tools/refgen/`: Go module on `cuelang.org/go` v0.17.1; parse `src/*.cue` (fixtures excluded), inclusion list in `groups.go`, comment filtering, entry rendering, marker splicing and `-check`
- [x] 2.2 `tools/refgen/refgen_test.go`: cleaning, sentence and label rules, Markdown escaping, and a dialect check over a full render
- [x] 2.3 `Taskfile.yml`: `docs:reference`, `docs:reference:check` and `refgen:test`, the last two in `task check`; `.github/workflows/ci.yml`: pinned `actions/setup-go` and both steps
- [x] 2.4 `task docs:reference`; review every page; `task generate:index` for the new directories
- [x] 2.5 `AGENTS.md`, `openspec/config.yaml`, `README.md`: name `tools/refgen/` as the one Go program and the new tasks and gate
- [x] 2.6 Build opmodel.dev against this tree (`task build`, `task lint:sources` in the worktree whose placeholder yields); check heading IDs against every fragment link
- [x] 2.7 `task check` green, then commit `docs(site): generate the definitions reference from the CUE source`

## 3. Review fixes

- [x] 3.1 `tools/refgen`: leave hidden fields and hidden-only comprehensions out of the spec part (elision first); drop a comment group that opens with `WHY`
- [x] 3.2 `src/*.cue`: present-tense wording, rewritten one-line summaries, all-caps emphasis lower-cased on published comment lines, contributor rationale moved into WHY blocks
- [x] 3.3 `task docs:reference`, `task generate:index`; `task check` green, then commit `docs(core): state the published doc comments in present tense and plain case`
