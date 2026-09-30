# Orchestration: fold-colliding-contract-keys

This file is the brief for the worker agent that implements this change and for the supervisor that stitches the change set together. The same text sits in every change of the set; only the title and the "This change" section differ.

## Change set

Five OpenSpec changes, planned together on 2026-09-30, in four repos. Four of them do one job:

- core stops failing to evaluate a platform that enables two majors of one catalog sharing contract keys. It folds only the keys with exactly one enabled definer and reports the rest as `collisions` and `collidingEntries`, with `routable` false.
- The library turns a collision into a typed render refusal and decodes it in `Contracts()`.
- The operator and cli name the collision.

The fifth (E) is independent: it makes the operator's build-compatibility verdict deterministic on a platform carrying two majors of one catalog. The fix is an interim safety net and does not add side-by-side majors; enhancement 0026 D9 later makes two majors legitimate through per-resolution builds (0026 OQ17 and 05-risks recommend both fixes independent of 0026). No change claims a 0026 decision, so none carries an `enhancement.yaml`.

| ID | Repo | Change | Branch | Wave | Starts when | Merges when |
| --- | --- | --- | --- | --- | --- | --- |
| A | core | `fold-colliding-contract-keys` | `feat/fold-colliding-contract-keys` | 1 | now | first; release cut after |
| E | opm-operator | `index-build-compat-by-major` | `fix/index-build-compat-by-major` | 1 | now | any time, independent of A to D |
| B | library | `refuse-colliding-contracts` | `feat/refuse-colliding-contracts` | 2 | A released | after A is released |
| C | opm-operator | `name-contract-collisions` | `fix/name-contract-collisions` | 3 | B's branch pushed | after B is released |
| D | cli | `name-contract-collisions` | `fix/name-contract-collisions` | 3 | B's branch pushed | after B is released |

What each hands on:

- **A** publishes, in core `2.0.0-alpha.13` (actual tag reported under `surface`):
  - `#ContractInventory.collisions: [...#ContractFQNType]`: sorted keys with more than one enabled definer.
  - `#ContractInventory.collidingEntries: [#ContractFQNType]: [...#ModulePathType]`: the sorted registry keys defining each.
  - `routable: len(overSubscribed) == 0 && len(collisions) == 0`.
- **B** reads them in the render build and in `Contracts()`, raises a typed refusal, moves `DefaultSchemaModule` to A's tag, and publishes the interface below in a library release.
- **C** and **D** consume B's release.
- **E** consumes nothing and hands on nothing.

## Interface B -> C, D

The contract C and D consume. B may refine names only by reporting the change under `deviations`; C and D code against what B reports under `surface`.

```go
package platform // github.com/open-platform-model/library/opm/platform

type ContractInventory struct {
	// ...existing fields unchanged...

	// Routable is true exactly when OverSubscribed and Collisions are both empty.
	Routable bool `json:"routable"`

	// Collisions lists, ascending, every contract key more than one enabled
	// registry entry's catalog lists. Such a key is in none of DefinedBy,
	// RequiredBy, Unfulfilled or Comparable, so Fulfilled and Discriminated
	// can read true while Collisions is non-empty; Routable is false.
	Collisions []string `json:"collisions"`

	// CollidingEntries maps each Collisions key to the sorted registry keys
	// (path@major) of the enabled entries listing it.
	CollidingEntries map[string][]string `json:"collidingEntries"`
}

// Contracts() decodes an absent collisions/collidingEntries as empty: every
// core before A's tag fails to evaluate a colliding platform at acquire.
```

```go
package errors // github.com/open-platform-model/library/opm/errors

type ContractCollision struct {
	Key      string   `json:"key"`
	Catalogs []string `json:"catalogs"` // sorted registry keys, path@major
}

// Raised (joined, first) by the render gate, platform-wide, under SkipUnprovided too.
type ContractCollisionsError struct{ Contracts []ContractCollision }

// Raised only when #contracts.routable is false and no over-subscription or collision row explains it.
type NotRoutableError struct{}
```

`kernel.RenderDiagnostics.Collisions []oerrors.ContractCollision` (sorted by key) and `RenderDiagnostics.Routable bool`. `schema.DefaultSchemaModule` = A's tag. `schema.ProvidedBySince` (the floor) is unchanged. `UnresolvedDemand.Colliding []string` is diagnostic only.

The rule behind it (A computes it, B reads it, C and D print it):

1. A definer is an ENABLED registry entry whose catalog lists the key in `#resources`, `#traits` or `#blueprints`. A disabled entry never counts.
2. A key with exactly one definer folds into `defined` and `definedBy` as before. A key with more is a collision: it is in `collisions` and `collidingEntries` and in none of `defined`, `definedBy`, `requiredBy`, `unfulfilled` or `comparable`. `providedBy` and `overSubscribed` are unaffected and can co-occur with a collision.
3. `routable` is false while any collision exists. `fulfilled` and `discriminated` can still read true (the stated limitation), so no consumer reads either as safe while `collisions` is non-empty.
4. The render refuses a colliding platform with `ContractCollisionsError`, whatever the instance and whatever `SkipUnprovided` says. Its rows are `{key, catalogs: collidingEntries[key]}` for every key in `collisions`, guarded on presence. Absence is provably empty: an older core fails to evaluate such a platform. A `routable` false that no row explains raises `NotRoutableError`.
5. The operator words it as reason `ContractCollisions`, ahead of `OverSubscribedContracts` and `ComparablePredicates`. The cli prints a colliding-contracts section and counts collisions in the routable verdict and the exit message.

## Worker protocol

One worker agent per change, in its own git worktree of the change's repo.

1. Create the worktree from fresh `origin/main`, on the branch named in the change set: from the repo root, `git fetch origin`, then `git worktree add .claude/worktrees/<change> -b <branch> origin/main`, then work inside that directory. Read the repo's `AGENTS.md` and `openspec/config.yaml` first; they bind. The repo-specific setup in this file comes next.
2. Run the repo's apply workflow on the change: `openspec instructions apply --change <change> --json`, then `tasks.md` section by section. The commit task that closes each section is the only commit you make.
3. After the last section is green, push the branch: `git push -u origin <branch>`. Do not archive the change, open a PR, merge, tag or release; the supervisor does.
4. On a blocker, stop and report it. Do not widen scope, and do not edit another repo; a design question goes in the report.
5. End with exactly this block as your final message:

```text
change:      <ID> <repo>/<change>
branch:      <branch> @ <head sha> (pushed: yes|no)
sections:    <n>/<total> committed
commits:     <sha> <subject>   (one line per commit)
gates:       <command> -> pass|fail   (one line each; name every failing or skipped test)
surface:     <what the next change consumes: exported symbols, flags, SPEC sections, output strings>
deviations:  <every departure from design.md or this file, with the reason; "none">
supervisor:  <what only the supervisor can do: a release, a pin bump, merge order, a decision; "none">
follow-ups:  <work found outside this change's repo; "none">
```

## Supervisor protocol

1. **Wave 1.** Launch the workers for A and E, each with its change's `orchestration.md` as its brief.
2. **Check each report.** Compare `deviations` and `surface` against `design.md` and the interface above. Send a worker back with a precise ask rather than fixing its branch yourself.
3. **Finalize each change.** For each, in the worktree: `openspec archive <change> --yes`, commit the archive (`chore(openspec): archive <change>`), push, open the PR per the repo's `AGENTS.md`. Merge order: A, then B, then C and D; E whenever it is green. After A merges, merge the core release PR that release-please opens and note the released version; after B merges, do the same for the library release PR.
4. **Wave 2.** Once A is released, launch B's worker with the core version. Do NOT run the workspace root `task deps:update` yet. Run it once B is released, and land its per-repo output (`fix(deps)` / `test(fixtures)` per the workspace commit skill). This departs from the previous set on purpose: a kernel older than B renders a colliding platform pinned to A's core (duplicate objects, measured), so no workspace platform moves to A's core before a refusing kernel exists.
5. **Wave 3.** Once B's branch is pushed, launch C's and D's workers. Until B is released they develop against B's pushed head as a Go pseudo-version. Once B is released, tell each worker the version; it rebases on `origin/main`, pins the release, reruns its gates and pushes. Then finalize C and D as in step 3.
6. **Follow-ups.** Run the out-of-repo follow-ups each change's `orchestration.md` lists, after the merge they wait on.

Every PR follows its repo's `AGENTS.md`: a body of at most 250 words, no bare `@name`, only the plain co-author trailer. Merging, releasing and pushing to `main` need the user's go-ahead.

## This change (A)

**Release class.** `feat(platform):`, one commit carrying pins, fix, SPEC and spec delta, with no `!`. Every platform that evaluates today reads the same value in every field (the full pin suite passes unchanged, measured). Only inputs that failed to evaluate change. `proposal.md` Impact must still state the redefined published invariant (`routable` was exactly `overSubscribed` empty) and the old-kernel render hazard.

**Worktree setup (core).**

- Branch `feat/fold-colliding-contract-keys` from `origin/main`, worktree at `core/.claude/worktrees/fold-colliding-contract-keys`.
- Export the registry mapping from the workspace root `AGENTS.md`, in two lines. Core has no dependencies, so nothing is pulled, but the Taskfile expects the variables.
- Every raw `cue` call runs from `src/`; prefer the `task` wrappers. Install the pre-commit hook (`task hooks:install`) so the SPEC co-update gate runs locally.

**Hazards.**

- **Red first, never committed red.** Write the two-major pin first, pinning ONLY existing fields (`#contracts.routable: false`, `#composedTransformers` length). It must fail `task vet` on unpatched `src/platform.cue` with the `metadata.catalogVersion` and `definedBy` conflicts. Record that output under `gates`. Pins on `collisions` or `collidingEntries` fail as "field not allowed" before the field exists, which proves nothing; add them after the fold.
- The fold is experiment 06's `core.patch` (enhancements `0026/experiments/06-collision-tolerant-fold`, on enhancements main 6b94e1c). Apply its logic, not its `FOLD PROBE` markers, and diff the result against `probe/platform.cue`.
- Keep `_pinInventoryReadout` untouched so the existing readout literals stay byte-identical; add a `_pinInventoryCollisionReadout` helper.
- The limitation pins (`requiredBy` lacks the key, `fulfilled: true`, `discriminated: true`) pin a known blind spot on purpose. Label them so a future fix updates them deliberately.
- Pin files force evaluation (see the header of `src/platform_contracts_pins.cue`); flip one new literal to prove the new pins bite.
- Doc comments stay at six lines or fewer (`task docs:check`); enhancement citations go only in `// WHY` blocks.
- Commit messages are not Markdown: glue every major to its path (`opmodel.dev/catalogs/opm@v5`), never a bare at-sign followed by a name, and no body line starting with a word followed by an opening parenthesis.
- The spec delta MODIFIES four requirements, not three: "Over-subscription counts providing registry entries, not transformers" states the old `routable` invariant and is corrected with its scenarios verbatim (`design.md` § Research & Decisions). The Purpose line of `openspec/specs/platform-contract-inventory/spec.md` is edited directly in the section commit (task 1.10).

**Waits on:** nothing. Wave 1.

**Hands off to B:** the two fields, the routable expression, the collision pin shapes, and the released tag (expected `v2.0.0-alpha.13`; the actual tag wins everywhere).

**Follow-ups outside this repo (supervisor):**

1. After A is released: launch B. Hold `task deps:update` until B is released (step 4).
2. In enhancements: walk 0026 OQ17 to a resolution citing A to E once they land (`enhancement-open-questions`), and decide whether to log the landings with `task delivery:log` in explicit mode without decisions.
