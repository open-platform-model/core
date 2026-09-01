# Design: core-registry-import

## Context

See `proposal.md` § Why. The design itself was settled in `enhancements/0019` (D5, D17, with D13's in-schema tripwire clauses); the CUE delta is pre-drafted and exercised in `enhancements/0019/schemas/` (`target.cue`, `examples.cue`, `spec.md` — the SPEC.md pre-draft). This document maps that delta onto this repo's files and protocols; it does not re-litigate the enhancement's decisions.

Current state: `src/platform.cue` defines `#Subscription` (`{enable, version!}`), `#Platform.#registry: [Path=#ModulePathType]: #Subscription`, and two optional kernel-filled slots `#composedTransformers?` / `#matchers?`. The library's `Materialize` step resolves subscriptions over OCI and fills the slots on a Go-side twin.

## Goals / Non-Goals

**Goals**

- Land the D5/D17 reshape in `src/platform.cue` with the `SPEC.md` §3.4 co-update in the same commit (`core-schema-edit` protocol).
- Keep the reshape byte-faithful to `enhancements/0019/schemas/target.cue` where that file states the shape, deviating only where the mirror was simplified (noted per decision below).

**Non-Goals**

- No home for the single-provider guard (enhancement 0010 D32/D37, today `providerGuard` in `library/opm/materialize`). Adding a schema-side guard would be new published surface with an unmeasured shape; 0019 owns the residue (the guard either moves into the render build's matching glue or becomes an 0011 publish gate). This change deletes nothing in `library`; the guard's fate is decided before the library deletes materialize, not here.
- No `#TransformerContext` change (D12 is the separate `core-context-projection` slice).
- No per-transformer selection surface (enhancement 0015).

## Decisions

### The schema delta, verbatim

`src/platform.cue` after the change (doc comments elided here; the real file carries them under the 6-line rule):

```cue
#CatalogEntry: {
	enable: bool | *true

	// The imported catalog, embedded whole.
	#catalog: #Catalog

	// Derived readouts. Neither is authored; a generation-time expected
	// `version` stamp unifies with the readout (D13 tripwire).
	version:       #catalog.metadata.version
	#transformers: #TransformerMap & #catalog.#transformers
}

#Platform: {
	kind: "Platform"

	metadata: {
		name!:        #NameType
		description?: string
		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	type!: string

	// Key binding: an entry keyed at one path carrying a catalog published
	// at another is a build conflict naming the entry.
	#registry: [Path=#ModulePathType]: #CatalogEntry & {#catalog: metadata: modulePath: Path}

	// Derived, non-optional: the fold over enabled entries. Copies per
	// entry (comprehension); never unifies one entry's map into another's.
	#composedTransformers: {
		for _, entry in #registry if entry.enable {
			for fqn, tf in entry.#transformers {(fqn): tf}
		}
	}

	// #matchers: REMOVED (0019 D17).
}
```

## Research & Decisions

### Removal, not extension, of `#Subscription`

**Context**: The entry shape must replace the subscription shape.
**Explored**: `enhancements/0019/experiments/02-platform-authority-mvs` attempted the entry as an extension of `#Subscription`.
**Decision**: Remove `#Subscription`; add `#CatalogEntry`.
**Rationale**: `#Subscription` is closed around `enable` + `version!`, so the entry is inexpressible as a unification onto it (measured). Keeping a deprecated `#Subscription` beside `#CatalogEntry` would leave two authoring surfaces for one question, the shape D5 exists to remove.

### `version` as a derived regular field, `version!` gone

**Context**: The entry needs the build's identity readable (skew diagnostics, Platform CR status) without a second answer to "which build".
**Explored**: authored `version!` beside the import (0019 D5 alternatives, rejected); no version field at all (discards the identity data D7 needs).
**Decision**: `version: #catalog.metadata.version` — a readout. An expected stamp unifies with it.
**Rationale**: computed off the imported bytes it cannot disagree with them; `#Catalog.metadata.version!` is required with no dev default, so an unstamped catalog refuses as incomplete rather than rendering wrong. The stamp's only reachable outcomes are agreement (no-op) and a conflict naming the entry.

### The fold copies per entry; shared FQNs unify at the composed key only

**Context**: `#composedTransformers` must compose several catalogs' maps.
**Explored**: unifying entry maps pairwise (`entryA.#transformers & entryB.#transformers`), measured in `enhancements/0019/experiments/05-match-in-one-build`.
**Decision**: comprehension copy per enabled entry, as shown above.
**Rationale**: the catalog's D25 provenance stamp (`metadata.modulePath: "<catalogPath>/transformers"`, `catalogVersion`) refuses a foreign transformer unified into another catalog's member map, so map-level unification fails on healthy multi-catalog input. Under the comprehension, two entries writing the same composed FQN key still unify at that key: agreement collapses, and genuinely divergent bodies conflict loudly through the same provenance stamps — the same verdicts `library`'s `indexCatalogs` produces today, now with CUE's error surface. Diagnostic quality for that conflict is the render glue's concern (0019 D10), not the schema's.

### `#matchers` removed rather than derived

**Context**: With the maps in the registry, core could derive the reverse index in four lines.
**Explored**: deriving it (`experiments/02`'s schema anticipated this); reshaping it to the set-of-FQNs form the render glue consumes (0019 D17 alternatives).
**Decision**: remove the field outright.
**Rationale**: 0019 D17 — measured 2026-08-20, its only reader is `library/opm/compile/match.go` through the materialized twin, and the in-build matcher builds its own buckets in a different shape (contract FQN → set of transformer FQNs, not lists of values). A derived `#matchers` would be a second index in a shape nothing reads. Consumers fold their own over `#composedTransformers`.

### The `platform-subscription` capability is retired, not reworded

**Context**: The OpenSpec capability holding the registry requirements is named `platform-subscription`, after the construct this change removes.
**Explored**: keeping the name and reshaping its requirements in place (the delta's first form: six ADDED, one MODIFIED, three REMOVED, all under the old capability).
**Decision**: retire `platform-subscription` outright and add `platform-registry` carrying every requirement, with `retire_capabilities: true` in the change's `.openspec.yaml` so the sync deletes the old main spec and its directory.
**Rationale**: after the reshape not one requirement in the capability still mentions a subscription, so the directory name would be the only surviving trace of a construct core no longer publishes — the same two-answers-to-one-question shape D5 removes from the registry, one directory up. Retire-and-add is the documented path (the sync skill's retirement conditions), and it is cheap here because the successor is a rename rather than a split: each removed requirement names the `platform-registry` requirement that carries it, so the archive keeps a readable trail. Discovered during verification, after the schema had landed; the CUE and `SPEC.md` are untouched by it.

### No core-side fixture; the delta's tests live where they already exist

**Context**: `task vet` validates the schema package only; core has no instance-fixture harness (that harness lives in `library`), and a must-fail case cannot be committed as a failing file.
**Explored**: an in-repo `platform_pins.cue` with a minimal two-catalog platform.
**Decision**: no new fixture file in this change.
**Rationale**: `enhancements/0019/schemas/examples.cue` already exercises the exact delta — derived readouts pinned by hidden assertions plus the must-fail cases with the observed cue v0.17.1 error text — and the library's parity and kernel fixtures re-exercise it against the published release when the Phase B wave re-pins. A hand-built valid `#Catalog` inline in core pins would duplicate the catalog's stamping machinery for no added coverage. If a later change wants standing in-repo pins, that is additive.

## Files and tracked constructs

- `src/platform.cue`: the whole delta. Doc comments and both WHY blocks rewritten to the import model (the "scalar version" WHY and the "kernel-filled slots" WHY are both obsolete); each stays within the 6-line doc-comment rule with `SPEC.md § 3.4` pointers.
- `src/platform_and_match_pins.cue` (landed after this design was drafted, with `core-context-projection`): its subscription-shaped section (`_pinPlatform`, the three `_pinSubscription*` readouts, `_pinOneBuildPerPath`, and the three subscription must-fail cases) pins removed behavior and is deleted under the no-new-fixture decision above; the matching, fulfilment and context pins stay. The import-model delta remains exercised by `enhancements/0019/schemas/examples.cue`.
- `openspec/specs/primitive-keying/spec.md` (via a delta in this change): the FQN-map-key requirement enumerated `#Platform.#matchers.resources` / `traits` as contract-keyed maps and carried a matcher-bucket scenario; both fall out with D17. Discovered during implementation; the delta drops those clauses and keeps the rest verbatim.
- `src/identity_package.cue`, `src/identity_package_pins.cue`, `src/types.cue`: comment-only rewrites, each removing a reference to a construct this change deletes. The first two carry the twinned note on why the version/path major relation is asserted only on `#IdentityPackage`; it named `#Subscription` as one of the two places that never asserted it, and now names `#CatalogEntry` in the same role, so the note keeps saying what it said. `types.cue`'s FQN-key table drops its `#Platform.#matchers` row. No schema surface changes in any of the three, and the `SPEC.md` §5.2 Rationale carries the matching rewrite.
- `docs/adapters.md`: the forward-looking `#Platform` paragraph described a reverse matcher index and a `#PlatformMatch` walk over `#matchers`; rewritten to the registry-of-entries shape with matching consuming `#composedTransformers`. Tutorial prose, no normative force.
- `SPEC.md` §3.4: Definition, Shape, Constraints, Rationale rewritten per the pre-draft (`enhancements/0019/schemas/spec.md` §`#CatalogEntry`, §`#Platform`). `#CatalogEntry` is documented inside §3.4 where `#Subscription` is today. Same commit as the CUE (pre-commit hook enforces).
- `.tasks/spec-tracked.txt`: add `#CatalogEntry` (top-level published definition, not a helper). `#Subscription` was never tracked; nothing to remove.
- `src/INDEX.md`: regenerate; review the extracted doc comments.

**Closedness / defaults / required-set callouts** (per this repo's design rules):

- `#CatalogEntry` is a closed definition; `enable` keeps the `*true` default unchanged from `#Subscription`.
- `#Platform.#composedTransformers` changes from optional (absent unless kernel-filled) to always-present derived. A consumer that branched on its absence now always sees a value (empty struct for an empty or fully-disabled registry).
- `#Platform.#matchers` removal makes any declared `#matchers` a field-not-allowed refusal.
- `#registry`'s required-field surface changes: entries no longer require `version!`; they require an embedded `#catalog` for the entry to evaluate complete.

## Risks / Trade-offs

- [The release is unconsumable by the current `library` kernel: `Materialize` reads `version!` and fills `#matchers`] → sequencing, not code: `library` stays pinned to the prior alpha until its 0019 Phase B wave (platform-as-module input, single-build render, materialize deletion) lands; the workspace `task deps:update` run that would bump it is deferred for `library` alone. Stated in the proposal's consumer table and worth repeating in the release notes.
- [The single-provider guard loses its enforcement point when `library` later deletes materialize] → out of scope here (see Non-Goals). This change does not remove the guard and removes nothing outside `src/platform.cue`, so nothing regresses at this release. The residue is real but **thinly tracked**: 0019 records it only as an open consequence in `02-design.md` § What matching costs ("D32/D37's single-provider guard and `indexCatalogs`' cross-build collapse are multi-build machinery. Whether they survive, or become vacuous, follows from the same question"), with no decision and no Open Question carrying it — verified against 0019's `03-decisions.md` and `07-questions.md` on 2026-09-01. `SPEC.md` §2.1 and §3.3 still name materialize as the enforcement point, and stay true until `library` deletes that step. Whoever schedules the library wave should raise the guard's home as an 0019 Open Question first, rather than discovering it when the enforcement point disappears.
- [Alpha-line dependence: three breaking edits absorbed as one `feat(platform)!:` alpha increment] → `@v2` is at `2.0.0-alpha.N`; this must land before a stable `2.0.0` cut or it becomes a v3 event (Principle IV, stated in the proposal's Classification).
- [Error-surface change for composition conflicts: `indexCatalogs`' "transformer %q diverges across selected builds" becomes a raw CUE conflict] → accepted; 0019 D10's verdicts-as-data glue owns match-time diagnostics, and the D13 tripwires (key binding, version stamp) were designed to fail at paths naming the offending entry.

## Migration Plan

One commit: `src/platform.cue` + `SPEC.md` + `.tasks/spec-tracked.txt` + regenerated `src/INDEX.md`, subject `feat(platform)!: carry the catalog in the registry entry, drop #Subscription and #matchers` (scope form per repo rules: `!` after the scope). release-please advances the alpha; CI publishes on the release merge. Rollback before release is a revert; after release, a subsequent alpha increment restoring the old shape (no consumer will have re-pinned, per the sequencing risk above).

Downstream migration is per the proposal's consumer table; no consumer action is required at release time because none re-pins until its own 0019 wave.
