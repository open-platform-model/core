## Why

A `#Platform` names its catalogs with a `version!` string, and a version string is inert: nothing in a CUE build resolves it, so the kernel resolves it out of band (one OCI pull per subscription), indexes the transformers in Go, and hands the result back on a `MaterializedPlatform` twin. Enhancement 0019 collapses the render to one CUE build per render (D9), and that build can only have an answer if the platform participates in dependency resolution the way every other module does: by import. D5 reshapes the registry entry to carry the imported catalog whole and derive everything else from it; D17 removes `#matchers`, whose only reason to exist was the Go step that filled it.

This change is `core-registry-import`, implementing `enhancements/0019` D5 and D17 (with the D13 tripwire clauses that live in the schema). The core-schema delta is pre-drafted in `enhancements/0019/schemas/{target.cue,spec.md}` and exercised by `examples.cue` there; this change lands it in `src/platform.cue` and `SPEC.md` §3.4.

## What Changes

- **BREAKING** `#Subscription` is removed. It is closed around `enable` + `version!`, so the new entry shape is inexpressible as a unification onto it (measured, `enhancements/0019/experiments/02-platform-authority-mvs`); removal, not extension.
- `#CatalogEntry` is added: `{enable: bool | *true, #catalog: #Catalog}` with two derived, never-authored readouts: `version: #catalog.metadata.version` and `#transformers: #TransformerMap & #catalog.#transformers`. An expected `version` MAY be stamped at platform-generation time; it unifies with the readout, so wrong bytes become a build conflict naming the entry (D13's tripwire).
- `#Platform.#registry`'s value type becomes `#CatalogEntry`, and the pattern constraint binds the map key into the embedded catalog: `[Path=#ModulePathType]: #CatalogEntry & {#catalog: metadata: modulePath: Path}`. Key-versus-import drift becomes inexpressible rather than detectable.
- **BREAKING** `#Platform.#composedTransformers` stops being an optional kernel-filled slot and becomes a derived, non-optional fold over enabled entries (comprehension copy per entry, never a unification of one entry's map into another's: the D25 provenance stamp refuses foreign members).
- **BREAKING** `#Platform.#matchers` is removed outright (D17). Nothing replaces it in core; the render build's matching glue builds its own buckets from `#composedTransformers`, in a shape core's list-valued buckets never matched.
- `SPEC.md` §3.4 co-update (Definition, Shape, Constraints, Rationale) under `core-schema-edit`, following the pre-draft in `enhancements/0019/schemas/spec.md`.

## Classification

**BREAKING, absorbed on the `@v2` alpha line** as a `feat(platform)!:` alpha increment (Principle IV). This relies on `@v2` still being pre-release: `#Subscription` and `#matchers` are removed and `#composedTransformers` changes from optional-filled to required-derived, all of which would be v3 events after `2.0.0` graduates. 0019's Phase B ordering assumes the slice lands while the line is still alpha; saying so here is the explicit statement Principle IV requires.

## Downstream consumers

- **`library`** (the load-bearing one): the release this change ships in is **unconsumable by the current kernel**. `opm/materialize` reads `#Subscription.version!` to pull builds and fills `#matchers`; both are gone. The library MUST NOT re-pin core to this release until its 0019 Phase B wave lands (platform-as-module input, single-build render, materialize deletion, matching in-build per D9/D10). Until that wave, `library` stays pinned to the prior alpha. Its `testdata/parity` platform fixture and kernel integration fixtures rewrite from `version!` subscriptions to catalog imports in the same wave.
- **`cli`**: authors the on-disk platform module (`./opm`). The `DefaultPlatformTemplate` seed writes `#registry` entries in subscription form today and moves to the import form (plus a `cue.mod` dependency on the catalog) when `cli` re-pins alongside the library wave.
- **`opm-operator`**: the Platform CR keeps its typed coordinate fields (0019 D6); the operator gains the platform-package generation step (CR → CUE module on disk, catalog import + optional expected-`version` stamp). Lands operator-side after the library wave; the sample Platform manifest and `test/fixtures` platforms move with it.
- **`catalog_opm` / `modules`**: no impact as artifacts. `#Catalog` is unchanged; catalogs are what platform modules now import, and modules never author platforms.
- **`opmodel.dev`**: generated schema reference picks up the reshape on its next `task generate`.

## Principle V

`#CatalogEntry` replaces a definition rather than adding beside one; both derived fields exist because an authored copy would be a second answer to a question the imported bytes already answer. `#matchers` is a net removal of published surface.

## Capabilities

### New Capabilities

- `platform-registry`: what a `#Platform` declares about the catalogs it admits, stated against the import model. It carries every requirement `platform-subscription` held, restated in entry vocabulary (`cue.mod` is the committed source that selects a build; one entry per catalog path), plus new requirements for the key-to-import binding, the derived transformer fold, and the absence of a reverse index.

### Removed Capabilities

- `platform-subscription`: retired, not narrowed. Every requirement it held was phrased against `#Subscription.version!`, a construct this change removes, so a directory named for it misdescribes what it holds. Its subject moves whole to `platform-registry`; each removed requirement names its successor. The change sets `retire_capabilities: true` so the sync deletes the main spec.

### Modified Capabilities

- `primitive-keying`: the "every FQN map key is typed by the role it holds" requirement loses its `#Platform.#matchers` bucket clauses and scenario, which named a map D17 removes; the demand-map and transformer-map clauses are unchanged.

## Impact

- `src/platform.cue`: `#Subscription` removed, `#CatalogEntry` added, `#Platform` reshaped (`#registry` value type + key binding, `#composedTransformers` derived, `#matchers` deleted). Doc comments and WHY blocks rewritten to the import model.
- `SPEC.md` §3.4 (same commit, `core-schema-edit` protocol).
- `.tasks/spec-tracked.txt`: `#CatalogEntry` added as a tracked construct (it is a top-level published definition, not a helper); `#Subscription` was never tracked, so no removal line.
- `src/INDEX.md`: regenerate (`task generate:index`) — one definition added, one removed.
- `src/platform_and_match_pins.cue`, `src/identity_package.cue`, `src/identity_package_pins.cue`, `src/types.cue`, `docs/adapters.md`: the subscription-shaped pins are deleted and the prose that named `#Subscription` / `#matchers` is rewritten to the import model. See design.md § Files and tracked constructs.
