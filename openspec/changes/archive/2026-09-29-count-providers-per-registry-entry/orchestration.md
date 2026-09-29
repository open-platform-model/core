# Orchestration: count-providers-per-registry-entry

This file is the brief for the worker agent that implements this change and for the supervisor that stitches the change set together.

## Change set

Four OpenSpec changes, planned together on 2026-09-29, each in its own repo. Together they make the render build's provider count the only count: core computes it once as `#contracts.providedBy`, the library render reads it instead of its own guard, and the operator and cli name the providing catalogs from it. No enhancement entry backs them (they correct the delivery of 0015:D2/D18, and 0015 is being closed as delivered), so none carries an `enhancement.yaml`.

| ID | Repo | Change | Branch | Wave | Starts when | Merges when |
| --- | --- | --- | --- | --- | --- | --- |
| A | core | `count-providers-per-registry-entry` | `feat/count-providers-per-registry-entry` | 1 | now | first; release cut after |
| B | library | `read-provider-count-from-core` | `feat/read-provider-count-from-core` | 2 | A released | after A is released |
| C | opm-operator | `single-source-provider-count` | `fix/single-source-provider-count` | 3 | B's branch pushed | after B is released |
| D | cli | `single-source-provider-count` | `fix/single-source-provider-count` | 3 | B's branch pushed | after B is released and the cli `deps:update` commit is on main |

What each hands on:

- **A** publishes `#ContractInventory.providedBy: [#ContractFQNType]: [...#ModulePathType]` (sorted registry keys), recounted `overSubscribed`/`unfulfilled`, in core 2.0.0-alpha.12 (actual tag reported under `surface`).
- **B** reads it in the render build (single source), decodes it, floors core, and publishes the interface below in a library release.
- **C** and **D** consume B's release.

## Interface B → C, D

The contract C and D consume. B may refine names only by reporting the change under `deviations`; C and D code against what B reports under `surface`.

```go
package platform // github.com/open-platform-model/library/opm/platform

type ContractInventory struct {
	// ...existing fields unchanged...

	// ProvidedBy maps every provider-fulfilled contract FQN some enabled
	// transformer requires (defined by an enabled catalog or not) to the
	// sorted registry keys (path@major) of the enabled entries whose
	// transformers require it. OverSubscribed is exactly its keys with two
	// or more entries; a key a defined provider contract lacks is Unfulfilled.
	ProvidedBy map[string][]string `json:"providedBy"`
}

// Contracts() refuses a platform whose #contracts lacks providedBy, naming
// the field and core 2.0.0-alpha.12.
```

```go
package errors // github.com/open-platform-model/library/opm/errors

// Returned (wrapped) by Kernel.Render before staging, and by Contracts(),
// when the platform module pins a core release predating a field the kernel reads.
type PlatformCoreTooOldError struct { Platform, Field, Since string }
```

`schema.DefaultSchemaModule` = `opmodel.dev/core@v2.0.0-alpha.12`. `OverSubscribedContract{Key, Catalogs}` and the render refusal text are unchanged.

The rule behind it (A computes it, B reads it, C and D print it):

1. Which transformers count: every transformer of every enabled registry entry, iterated per entry. Only required demands (`requiredResources`, `requiredTraits`) count; optional demands and `requiredLabels` never do.
2. Fulfilment is read from the transformer's own requirement (`req.fulfilment == "provider"`), never from the defining catalog's member; counting never depends on whether an enabled entry defines the contract.
3. The key is the registry key, path with major. Two adapters in one entry are one provider; two majors of one catalog are two; two entries are two whether or not any enabled entry defines the contract.
4. `overSubscribed` is every `providedBy` key with more than one entry. `unfulfilled` is every defined provider-fulfilled resource or trait with no `providedBy` key; a contract no enabled catalog defines is never unfulfilled.
5. The render reads the same values: `match.#providers = platform.#contracts.providedBy`; the over-subscription rows are `{key, catalogs: providedBy[key]}` for every key in `overSubscribed`, iterating `providedBy` unconditionally (a presence fallback is fail-open on older cores, measured); `gate: match.resolved & platform.#contracts.routable`.

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

1. **Wave 1.** Launch the worker for A, with this change's `orchestration.md` as its brief.
2. **Check each report.** Compare `deviations` and `surface` against `design.md` and the interface above. Send a worker back with a precise ask rather than fixing its branch yourself.
3. **Finalize each change.** For each, in the worktree: `openspec archive <change> --yes`, commit the archive (`chore(openspec): archive <change>`), push, open the PR per the repo's `AGENTS.md`. Merge order: A, then B, then C and D. After A merges, merge the core release PR that release-please opens and note the released version; after B merges, do the same for the library release PR.
4. **Wave 2.** Once A is released, launch B's worker with the core version. Then run the workspace root `task deps:update` and land its per-repo output (`fix(deps)` / `test(fixtures)` per the workspace commit skill); cli's must be on main before D merges.
5. **Wave 3.** Once B's branch is pushed, launch C's and D's workers. Until B is released they develop against B's pushed head as a Go pseudo-version. Once B is released, tell each worker the version; it rebases on `origin/main`, pins the release, reruns its gates and pushes. Then finalize C and D as in step 3.
6. **Follow-ups.** Run the out-of-repo follow-ups each change's `orchestration.md` lists, after the merge they wait on.

Every PR follows its repo's `AGENTS.md`: a body of at most 250 words, no bare `@name`, only the plain co-author trailer. Merging, releasing and pushing to `main` need the user's go-ahead.

## This change (A)

**Worktree setup (core).**

- Branch `feat/count-providers-per-registry-entry` from `origin/main`, worktree at `core/.claude/worktrees/count-providers-per-registry-entry`.
- Export the registry mapping from the workspace root `AGENTS.md` (`CUE_REGISTRY` and `OPM_REGISTRY` routing `opmodel.dev` and `testing.opmodel.dev` to GHCR). Core has no dependencies, so nothing is pulled, but the Taskfile expects the variables.
- Every raw `cue` call runs from `src/`; prefer the `task` wrappers. Install the pre-commit hook (`task hooks:install`) so the SPEC co-update gate runs locally.

**Hazards.**

- Red first, never committed red. Task 1.2 must fail `task vet` on the three readouts (`routable=true` against the expected `routable=false`) before `src/platform.cue` changes; record that output in the report under `gates`. The section commit carries pins and fix together.
- The `providedBy` pins cannot be written before the field exists: `#ContractInventory` is closed, so they fail as "field not allowed", which proves nothing about the bug. They go in after task 1.4.
- Pin files force evaluation: a pin that only unifies an unevaluated expression with a literal asserts nothing (see the header of `src/platform_contracts_pins.cue`). Task 1.5 flips one literal to prove the new pins bite.
- The bug-shape provider transformers must require ONLY `backup`. Reusing `_pinInventoryK8upSchedule` (which also requires the catalog-fulfilled container) in a second major would pair it with the base `deployment` transformer in `comparable` and change the readout.
- Doc comments stay at six lines or fewer (`task docs:check`); enhancement citations go only in `// WHY` blocks, never in the doc comment.
- `SPEC.md` line numbers in `tasks.md` are as of `origin/main` 4c68be0; locate by the quoted text if they have moved.
- The commit is `feat(platform)!:` with a `BREAKING CHANGE:` footer. Commit messages are not Markdown: write every path major glued to its path (`opmodel.dev/catalogs/k8up@v2`) and never a bare at-sign followed by a name. No body line may start with a word followed by an opening parenthesis (the squash body reaches release-please).

**Waits on:** nothing. Wave 1.

**Hands off to B (`read-provider-count-from-core`):**

- The field `#ContractInventory.providedBy` and its rule (the interface section above), and the recounted `overSubscribed` and `unfulfilled`.
- The three pin platforms (`_pinInventoryTwoMajors`, `_pinInventoryDefinerDisabled`, `_pinInventoryDefinerAbsent`): B reuses their shapes for its `platform_two_majors` and `platform_definer_disabled` render fixtures.
- The released tag, which the supervisor reads from the release-please PR after merge. Expected `v2.0.0-alpha.12`; if another core release lands first, every "since", `DefaultSchemaModule` value and pin in B, C and D uses the actual tag.

**Follow-ups outside this repo (supervisor):**

1. After A is released: launch B, then run the workspace root `task deps:update` (re-pins `cli/hack/platform`, `cli/examples`, the CLI templates, `catalog_opm`, `modules`, `opm-modules` and the operator sample Platform to the new core; it republishes `modules` and `opm-modules` through their `fix(deps)` commits).
2. File a core issue for the pre-existing, measured conflict when two majors of a contract's DEFINING catalog are enabled together: `#contracts.defined` and `definedBy` conflict (catalogVersion `"1.0.0"` vs `"2.0.0"`; `opm@v1` vs `opm@v2`), which makes the whole platform value bottom (measured during review: `#composedTransformers` and `routable` read the conflict too, on today's core and the new one alike), so nothing on that shape acquires, renders or routes. Out of scope here, and unchanged by it.
3. The personal `opm-kind-demo` platform re-pin to the new core, after B is released (hand-written platforms are refused by B's core floor until re-pinned).
