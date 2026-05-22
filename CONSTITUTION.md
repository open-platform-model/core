# Open Platform Model Core Schema Constitution

## Purpose

This document records the principles that govern the OPM core schema — the CUE definitions in `v1alpha2/` that every OPM artifact is typed against.

`core` is the **contract** of OPM. It is not code that runs; it is the shape that all code agrees on. The kernel (`library`), the catalog, the CLI, and the operator all resolve their behaviour against these definitions. A change here propagates to every consumer, so the principles below are written with that blast radius in mind.

## Design Principles

| # | Principle | Summary |
| --- | --- | --- |
| **I** | [Contract Stability](#i-contract-stability) | The schema is a published contract; breaking it breaks every consumer |
| **II** | [Type Safety First](#ii-type-safety-first) | Constrain values at the schema; reject invalid input as early as possible |
| **III** | [Determinism](#iii-determinism) | Equal inputs yield equal artifacts — no hidden or ambient state |
| **IV** | [Self-Contained](#iv-self-contained) | The schema depends only on the CUE standard library |
| **V** | [Versioned Evolution](#v-versioned-evolution) | New shapes land in new version packages, not by mutating released ones |
| **VI** | [Documented Definitions](#vi-documented-definitions) | Every exported definition carries a doc comment and a fixture where behaviour is non-obvious |

---

### I. Contract Stability

`opmodel.dev/core@v1` is consumed by every OPM repository as a published, version-pinned dependency. Once a version is published it is immutable.

- Prefer **additive** change: new optional fields, new definitions.
- A change that removes a field, tightens a type, or alters computed output is **breaking** — it requires a deliberate decision and a coordinated consumer rollout.
- Never assume a consumer; the schema serves the kernel, the catalog, the CLI, and the operator equally.

### II. Type Safety First

The schema is the first and cheapest place to reject bad input.

- Constrain primitives with explicit types and regex bounds (see `v1alpha2/types.cue`) rather than bare `string`.
- Close structs where the field set is known; leave them open (`...`) only where extension is intended.
- Push validation into the schema so consumers inherit it for free instead of re-implementing it.

### III. Determinism

Given identical inputs, the schema MUST compute identical outputs.

- Computed fields (FQNs, UUIDs, content hashes) derive purely from their inputs.
- No reliance on evaluation order, environment, or time.
- These computed properties are exercised by the schema fixture harness in the consuming `library` repo, including a pinned-UUID drift sentinel.

### IV. Self-Contained

The core schema imports only the CUE standard library (`strings`, `list`, `uuid`, `crypto/...`, `encoding/...`).

- `cue.mod/module.cue` carries no external `deps`.
- `cue vet` therefore runs fully offline, with no registry round-trip.
- A new external dependency is an architectural decision, not a convenience.

### V. Versioned Evolution

Schema versions are directories (`v1alpha2/`), each its own CUE package.

- A new generation of shapes lands in a new version package; released packages are not mutated in place.
- The CUE module path is pinned to major `@v1`; publish tags stay within `v1.x.x`.

### VI. Documented Definitions

The schema is read by humans and by `generate-index.sh`.

- Every exported `#Definition` carries a doc comment; its first sentence becomes its `INDEX.md` description.
- Behaviour that is not obvious from the types is exercised by the schema fixture harness in the consuming `library` repo.
- `INDEX.md` is regenerated and reviewed whenever definitions change.
