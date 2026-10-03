## Why

Core's seven `*_pins.cue` files (3,301 lines, 379 hidden top-level declarations, 272 distinct fields) are in package `core`, so they are part of every build of that package. The library's schema loader (`library/opm/schema/loader.go`) builds `opmodel.dev/core@v2` as the main instance, and `BuildInstance` finalizes the whole root, hidden fields included. Measured on a copy of `main` at 7c6aba8 (cue v0.17.1, harness in design.md): that build retains 74.7 MB and takes 0.17-0.24 s here, against 2.8 MB and under 11 ms with the pins out of the package. Published `v2.0.0-beta.1` measured the same: 76.3 MB, 0.43-0.48 s. The operator pays this at startup and holds the memory for its whole life (`verifyCoreSchema`, `opm-operator/cmd/main.go`), and cli `mod vet` and `publish` pay it on every run.

The pin files' header comments say the opposite: that an importing package never evaluates the pins, "so they gate this repo without costing a consumer anything". That holds only when nothing finalizes the package root.

The owner decided on 2026-10-03 (kernel plan, task j2): "core moves its pins into a src/pins/ subpackage (core release, consumers pick it up on the core pin bump)." A subdirectory package that imports `core` is never loaded unless something imports it, and nothing does. No consumer then parses or evaluates the pins, whatever way it builds `core`. Plain `cue vet ./...` from `src/` still vets the pins with no tag, so the gate cannot be skipped silently.

## What Changes

- The seven pin files move from `src/` to `src/pins/` under their current names and become package `pins`, importing `opmodel.dev/core@v2`. Every reference to a core definition or to `OPMNamespace` gains a `core.` prefix. That includes the commented-out MUST-FAIL bodies, so they still fail as recorded when uncommented in place. No pin reads one of core's hidden fields (checked: the `._x` hits are all in comments), so no pin needs rewriting beyond the prefix.
- Each pin file's header comment is rewritten. The "costs a consumer nothing" claim is replaced by the structural reason it now holds: nothing imports package `pins`.
- `SPEC.md`: the two links to `src/identity_pins.cue` and `src/component_names_pins.cue` point at `src/pins/`. No section's content changes.
- `AGENTS.md`, `openspec/config.yaml` (Principle IV), the `core-schema-edit` skill and the "Check against" notes in `docs/site/` name `src/pins/` as the place pins live. Principle IV says "Single Package". It gains one sentence: the published schema is still the one `core` package, and `src/pins/` is a test-only package that nothing imports.

Package `core` is unchanged: no definition, constraint or default moves, and `task docs:reference` and `src/INDEX.md` stay byte-identical. Under Principle I this is neither MAJOR nor MINOR. It does not use the `@v2` beta break licence and forces no `catalogs/opm` major. The move lands as a `perf:` commit, because it cuts the evaluation cost every consumer pays when it builds core. That commit cuts a `-beta.N+1` core release, as the owner decided ("core release").

PR title (one-PR mode, the squash title release-please reads): `perf(pins): move the schema pins into a src/pins subpackage`.

## Capabilities

### New Capabilities

- `schema-pins`: where core's schema pins live, which builds evaluate them (core's own vet), and which never do (any consumer's build of `core`).

### Modified Capabilities

None. `definitions-reference` keeps its scenario "A fixture definition is never a candidate" unchanged: the generator globs `src/*.cue` without recursing, so it never reads `src/pins/`.

## Impact

- **library**: no code change. The cost drops once `DefaultSchemaModule` (`library/opm/schema/loader.go`) is bumped to the release this change cuts, which is the routine core pin bump the release cascade carries. Follow-up outside this repo: `library/docs/site/diagnostics/colliding-contracts.md` names `core/src/platform_contracts_pins.cue` in a "Check against" note. That path goes stale and is fixed on the library's next docs pass.
- **cli**, **opm-operator**: no code change. They get the saving through the library bump and their own core pin bump (cli `DefaultCorePin` moves with its library bump in one PR). Comments in `cli/internal/publish/catalog_gates*.go` name `identity_package_pins.cue` by file name only and stay correct.
- **catalog_opm**, **modules**: no action. They import core and reference definitions, so they never evaluated the pins. Hidden fields are package-private, so no consumer could reference a pin.
- **The published module** still ships the pin files (now under `pins/`), because `cue mod publish` packs the whole module directory. They are bytes in the zip that no load reads.
- **Core's own CI** pays the same cost as before. `task vet` builds package `pins`, which builds core.
