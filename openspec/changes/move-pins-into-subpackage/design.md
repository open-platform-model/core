## Context

See proposal.md for why. Current state at `main` 7c6aba8:

- `src/` holds the seven pin files beside the schema, all `package core`: `catalog_pins.cue` (214 lines), `component_names_pins.cue` (271), `identity_package_pins.cue` (396), `identity_pins.cue` (649), `module_init_values_pins.cue` (110), `platform_and_match_pins.cue` (623), `platform_contracts_pins.cue` (1038). They declare hidden top-level fields only, no `#Definition`. Two of them import `strings`.
- Nothing outside the pin files reads a pin: the only non-pin hits are prose in `src/identity_package.cue:64`, `src/blueprint.cue:106` and `src/transformer.cue:34`, which name a pin file or field in a comment.
- No pin reads one of core's hidden fields. Core has no top-level hidden field outside the pin files. The `._leaf`-style paths in the pin files appear only in comments that record MUST-FAIL errors. A hidden constraint nested inside a definition (`_leaf`, `_nameFits`) still fires when another package unifies with that definition.
- Vet, fmt and publish run `cue vet ./...` and `cue fmt ./...` from `src/` (Taskfile `vet`, `fmt`, `fmt:check`, `publish`, `publish:branch`; `release.yml` line 100), so they already recurse into subdirectories.
- The tooling selects pin files in three ways, none of which this change has to touch:
  - `.tasks/doc-check.sh` finds files recursively and excludes `*_pins.cue` by name. It is byte-identical with catalog_opm's copy.
  - `tools/refgen/defs.go` globs `src/*.cue` without recursing and also skips `*_pins.cue`.
  - `.tasks/spec-check.sh` globs `src/*.cue` for `#Definition:` lines, and the pins declare none.

No construct in `.tasks/spec-tracked.txt` changes and none is newly tracked. The only `SPEC.md` edits are two link targets (§3.1 `#Component` Rationale at line 369, §3.2 `#Module` Rationale at line 476). Those links are why the move commit carries `SPEC.md` without the `SPEC_IMPACT=none` escape.

## Goals / Non-Goals

**Goals:**

- No consumer's build of `opmodel.dev/core@v2`, main instance or import, loads, parses or evaluates a pin.
- Plain `task vet` keeps gating every pin, with no tag and nothing to forget.
- Every recorded MUST-FAIL error stays true when its case is uncommented in place.

**Non-Goals:**

- `@if(pins)` tagging. The owner chose the subpackage. `@if` keeps the files parsed (about 1.2 MB and 10 ms per load) and makes a plain `cue vet` skip them silently.
- The library loader stub (building core through an in-memory instance that aliases its definitions). The owner did not choose it.
- Having the library loader call `val.Err()`. That is the wave-1 sibling library change `fix-duplicate-identity-and-schema-error-memo`, which makes `OCILoader` fail on an errored core build. The two are complementary: once both land, a broken pin cannot fail a consumer's schema load, because the pins are outside core.
- catalog_opm's `_test*` fields, `vet:fixtures` in its PR CI and its `@if(fixtures)` split. Those are the catalog_opm half of the same owner decision and are planned there.
- Renaming the pin files. Keeping `*_pins.cue` keeps both name-based exclusions (`doc-check.sh`, `refgen`) correct with no edit to the shared `doc-check.sh`.
- Rewording the comments in `src/blueprint.cue`, `src/transformer.cue` and `src/identity_package.cue` that name a pin file or a pin. The file names stay unique in the module, and editing a schema file would regenerate the definitions reference for no gain.

## Decisions

### D1. Package `pins` in `src/pins/`, importing core by its module path

Every moved file starts:

```cue
package pins

import (
	"opmodel.dev/core@v2"
)
```

Files that already import `strings` keep it in the same block. The import path names the root package of this same module, so it resolves locally with no `cue.mod` change and no registry access. A reference to a core construct becomes qualified:

```cue
// before (package core)
_pinModuleV2: #Module & {
	metadata: name: "postgres"
}
_pinObjectNameDots: "\(#ObjectNameType & "zfs.csi.openebs.io")"
#catalogs: [...#Catalog]

// after (package pins)
_pinModuleV2: core.#Module & {
	metadata: name: "postgres"
}
_pinObjectNameDots: "\(core.#ObjectNameType & "zfs.csi.openebs.io")"
#catalogs: [...core.#Catalog]
```

The names to qualify are core's top-level labels: every `#Definition` declared in a non-pin `src/*.cue` file, plus `OPMNamespace`. Field labels inside a pin, such as `#resources:` or `#catalogs:`, are not core references and stay as they are. The rewrite also covers the commented-out MUST-FAIL bodies, because they exist to be uncommented in place. Prose mentions in backticks stay unqualified.

**Unknown reference fails loudly.** A missed reference is a CUE error ("reference "#NameType" not found"), so `task vet` finds every miss. The prototype's line-based rewrite missed four, inside string interpolations and after `...`.

### D2. Header comments state the structural reason

The claim in every header ("an importing package never does — so they gate this repo without costing a consumer anything", and the companions' "while an importing package never does") is replaced. `identity_pins.cue` carries the full statement and the other six keep their pointer to it:

```cue
// Every value here is a HIDDEN top-level field of package `pins`, which
// imports `core` and which nothing imports. `task vet` (`cue vet ./...` from
// src/) builds this package and fails on a conflict; no consumer ever loads it,
// whether it imports core or builds core as the main instance, so the pins
// cost a consumer nothing. They also add no row to src/INDEX.md.
```

Wording is final at implementation. The underscore-filename note and the MUST-FAIL convention stay. The exception at the bottom of `identity_pins.cue`, the missing required field measured with `cue export`, also stays, but its recorded command changes. `cue export -e '_failMissingAPIVersion' ./...` from `src/` would now also export package `core`, which has no such field, so the command becomes `cue export -e '_failMissingAPIVersion' ./pins`. It is re-run in place and the recorded output is updated if it differs.

The same applies to every other recorded `cue export` command in the pin files (`identity_package_pins.cue`, `platform_and_match_pins.cue` twice, `platform_contracts_pins.cue`): a `./...` or `./` target fails with `reference "_x" not found` once the field lives in package `pins`, so each becomes `./pins` and is re-run in a scratch copy.

The paragraph in `platform_and_match_pins.cue` that explains why its gate pins stay hidden ("a non-hidden top-level field in this package SHIPS to every consumer") is rewritten too: in package `pins` that reason no longer holds. The gate stays hidden because `task vet` runs without `-c` and the pin shape stays uniform; a non-hidden form checked with `cue vet -c` is now possible but out of scope.

### D3. The vet gate is unchanged, and proven to still bite

`Taskfile.yml`, `release.yml` and `ci.yml` need no edit: `cue vet ./...` from `src/` loads `./pins` as its own instance and evaluates it. Proven on the prototype: a `zz_broken_pins.cue` holding `_pinBroken: 1 & 2` in `src/pins/` fails `cue vet ./...` with `_pinBroken: conflicting values 2 and 1`, while `cue vet .` (core alone) passes. The implementation repeats this on a scratch copy of the finished tree, never in the worktree.

## Research & Decisions

### Does the subpackage keep the pins' behaviour?

**Context**: The verdict that compared `@if(pins)` with a subpackage left the subpackage untested. Its open question was whether any pin reads a core hidden field, which would be unreachable from another package.

**Explored**: A scratch copy of `src/` at 7c6aba8 with the seven files moved and rewritten as in D1 (`scratchpad/exp/j2-sub/`).

- `cue vet ./...` passes in about 0.19 s.
- The broken-pin proof in D3 fails as it should.
- Two MUST-FAIL cases uncommented under the new package give the recorded errors word for word:
  - `_failLeafMismatch.metadata._leaf: conflicting values false and true`
  - `_failNoMajor.metadata.fqn: invalid interpolation: invalid value "opmodel.dev/modules/postgres" (out of bound …)`

  Hidden labels from core are printed unqualified. Only the source positions differ, and the recorded errors carry none.
- `task generate:index` output is unchanged apart from the module name and the repo directories the scratch copy lacks. `pins/` adds no section because it declares no definition.

**Decision**: Package `pins` in `src/pins/` as in D1.

**Rationale**: The owner chose it. The prototype confirms that the move changes no pin's meaning and no recorded error, and that the gate stays tag-free.

### What the move saves a consumer

**Context**: The owner asked for the main-instance load of core measured before and after.

**Explored**: The j2 experiment harness (`scratchpad/exp/pins/harness`, cuelang.org/go v0.17.1, go1.26.5) runs `load.Instances` then `cuecontext.New().BuildInstance`, then `LookupPath(#IdentityPackage)` (the cli vet follow-up). It reads `runtime.MemStats` after `runtime.GC()` with the value kept alive, in a fresh process per run, 5 runs each.

| Build | Time, prototype on a quiet machine (ms) | Time, implementation under load (ms) | Retained heap (HeapAlloc) | Allocated |
|---|---|---|---|---|
| core as main instance, before (pins in `core`) | 174-241, median 183 | 965-1880, median 1071 | 74.7 MB | 103.5-104.1 MB |
| core as main instance, after (pins in `src/pins/`) | 6.5-10.6, median 7.9 | 60-221, median 119 | 2.8 MB | 3.6 MB |
| package `pins` as main instance, after (what `task vet` builds) | 167-188 | 868-1482, median 1156 | 74.5 MB | 103.3-103.7 MB |

The implementation rows were measured on scratch copies of `src/` at 7c6aba8 (before) and of the finished tree (after), five fresh runs of each, interleaved so the load of other jobs on the machine hit all three alike; the `pins` build reported no error. An earlier uninterleaved before batch gave 558-810 ms, median 694. Times depend on the machine and its load; the ratio holds (about 9x here, about 23x quiet). The same build of published `v2.0.0-beta.1` took 0.43-0.48 s in the earlier runs. The memory figures are deterministic to ±0.1 MB and match the prototype. The cost does not disappear: it moves to core's own vet, the one place that should pay it.

**Decision**: Ship the move as a `perf:` commit.

**Rationale**: The published schema is byte-identical in meaning, and the measured effect is evaluation cost, which is the case the commit table in `AGENTS.md` gives to `perf:`. The commit cuts the core release the owner asked for.

## Risks / Trade-offs

- [A missed `core.` qualification] → it cannot pass silently: an unqualified `#X` in package `pins` is an unresolved reference, and `task vet` fails on it.
- [A commented MUST-FAIL body left unqualified] → it would fail as "reference not found" instead of the recorded error when uncommented. Mitigation: the rewrite covers comment code lines too (D1), the diff is reviewed for every `#Name` that stays unqualified in a comment, and every commented MUST-FAIL case is uncommented one at a time in a scratch copy by script, asserting no `reference "#..." not found` and the recorded first error (task 1.4).
- [Someone adds a new pin to `src/*.cue` in package `core`] → it would vet and quietly bring the cost back. Mitigation: `AGENTS.md`, Principle IV and the `core-schema-edit` skill name `src/pins/` as the only place for pins. No mechanical guard is added, because the owner's decision did not ask for one.
- [A consumer imports `opmodel.dev/core@v2/pins`] → it would pay the cost. Nothing does, and hidden fields cannot be referenced across packages, so an import would gain the importer nothing.
