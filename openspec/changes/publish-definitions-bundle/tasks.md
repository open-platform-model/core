Delivery: one PR per section (proposal.md). Each section has its own gate; do not start a section before its gate holds. Gates are defined in docs-kit `docs/orchestration.md`.

## 1. Adopt docs-kit

Gate G2-core: docs-kit's `add-cue-definitions-extractor`, `add-authored-docs` and `generalize-build-assembly` are released (their release PRs merged by the owner). Use the first docs-kit release that carries all three as `vX.Y.Z` below.

- [ ] 1.1 `.opm-docs-version`: `vX.Y.Z` on one line. `.tasks/opm-docs.sh`: copy catalog_opm's byte for byte. `.gitignore`: `/out/` and `/.bin/`.
- [ ] 1.2 `Taskfile.yml`: `tools:opm-docs`, `docs:bundle` (`--project core --out out`), `docs:pins:check`, `docs:bundle:check`, as catalog_opm's `Taskfile.yml` has them; `task check` runs `docs:bundle:check` after `docs:reference:check`.
- [ ] 1.3 `docs-kit.cue` at the repository root exactly as design.md D1 (lists moved verbatim from `tools/refgen/groups.go`, `exclude: ["reference/definitions/"]` on the `markdown` source). Verify: `task docs:bundle` writes `out/core/` and `task docs:bundle:check` passes.
- [ ] 1.4 `.github/workflows/docs.yml`: catalog_opm's with `project: core`, tag examples `vX.Y.Z`, `publish.yml@vX.Y.Z`, the backfill floor `v2.0.0-beta.1` in the dispatch comment (design.md D3). Verify: `actionlint` clean.
- [ ] 1.5 `.github/workflows/release.yml`: the `publish-docs` job after `publish-cue` (design.md D3). Verify: `actionlint` clean; `task docs:pins:check` passes with every ref.
- [ ] 1.6 Parity at this commit: diff `out/core/content/reference/definitions/` against `docs/site/reference/definitions/` with refgen's marker comments removed. Verify: no difference beyond those docs-kit's C17 parity record lists; record the result (commit and diff summary) in design.md D1. An unlisted difference stops the section: report it to docs-kit instead of committing.
- [ ] 1.7 `AGENTS.md`: a "Docs bundles" paragraph under "Release & publishing" (what publishes when: PR check, edge on `main`, a bundle per release after `publish-cue`; preview with `task docs:bundle` or `opm-docs serve`; recover a release without a bundle with `gh workflow run docs.yml --ref main -f mode=release -f tag=vX.Y.Z`; fix a released page with `mode=revision`; after the site reads the bundle, an authored fix reaches it only by a release or a revision), the new tasks in "Build And Dev Commands", and the two placement lists of design.md D2. `openspec/config.yaml`: validation gate 6 `task docs:bundle:check`, and the tasks rule naming both `tools/refgen/groups.go` and `docs-kit.cue` until section 3.
- [ ] 1.8 `openspec validate publish-definitions-bundle --strict` passes; `task check` green, then commit `ci(docs): publish the core docs bundle with docs-kit`.

## 2. Publish the first release bundle

Gate: section 1 is merged. This section's deliverable is a publishing operation (the owner's), so its steps are the implementation.

- [ ] 2.1 Owner: release core. Either the next core release carries the bundle (`publish-docs` runs after `publish-cue`), or, if the owner needs the bundle before anything releasable lands, dispatch the backfill `gh workflow run docs.yml --ref main -f mode=release -f tag=v2.0.0-beta.1` (design.md "The release that carries the first bundle"). Record which in design.md.
- [ ] 2.2 Owner: check `ghcr.io/open-platform-model/docs/core` is public and linked to `open-platform-model/core` on its first push (change it in the package settings if not).
- [ ] 2.3 Verify the full, release, minor and major tags of the published version: `cosign verify` with docs-kit C9's identity flags, or `opm-docs pull` with a scratch `bundles.cue` that names `core` under `docs`, anonymously. Verify: every tag verifies.
- [ ] 2.4 Record in design.md the release (or backfill) run URL, the published version and digest, and the verification. Then report the version to the library's release cascade: the library's next release must pin it (`DefaultSchemaModule`) for gate G2-pins.
- [ ] 2.5 `openspec validate publish-definitions-bundle --strict` passes; `task check` green, then commit `docs(openspec): record the first core docs bundle`.

## 3. Retire tools/refgen

Gate G2-switch: opmodel.dev's `pull-reference-bundles` section 2 is merged (v1.0 reads core from bundles).

- [ ] 3.1 Delete `tools/refgen/` and `docs/site/reference/definitions/`.
- [ ] 3.2 `Taskfile.yml`: delete `docs:reference`, `docs:reference:check`, `refgen:test` and their comment block, and their two lines in `task check`. `.github/workflows/ci.yml`: delete the "Setup Go", "Test the reference generator" and "Verify the definitions reference is up to date" steps and their comment.
- [ ] 3.3 `docs-kit.cue`: the `markdown` source becomes `{kind: "markdown", dir: "docs/site"}` (no `exclude`). Verify: `task docs:bundle:check` passes and `out/core/content/reference/definitions/` still holds nine pages.
- [ ] 3.4 `AGENTS.md`, `README.md`, `openspec/config.yaml`: core is CUE only again (Purpose, Repository Layout, Technology Standards, the refgen rows of "Build And Dev Commands"); validation gate 5 becomes `task docs:bundle:check`; the tasks rule names only `docs-kit.cue`. `src/INDEX.md`: drop `refgen/` from the hand-maintained tree. Verify: `grep -rn "refgen\|docs:reference" --exclude-dir=archive .` finds nothing outside `openspec/changes/`.
- [ ] 3.5 `openspec archive publish-definitions-bundle --yes`; then set `openspec/specs/definitions-reference/spec.md`'s Purpose to the bundle-built reference. Verify: `openspec validate --specs --strict` passes for `docs-bundle` and `definitions-reference`.
- [ ] 3.6 `task check` green, then commit `ci(docs): retire tools/refgen and its committed pages`.
