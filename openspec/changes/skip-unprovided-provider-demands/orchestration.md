# Orchestration: skip-unprovided-provider-demands

This file is the brief for the worker agent that implements this change and for the supervisor that stitches the change set together.

## Change set

Four OpenSpec changes, planned together on 2026-09-29, each in its own repo. Together they retire the local default platform (`~/.opm/platform/`) and let a render skip provider-fulfilled contracts that nothing on the platform provides. No enhancement entry backs them (user decision 2026-09-29), so none carries an `enhancement.yaml`.

| ID | Repo | Change | Branch | Wave | Starts when | Merges when |
| --- | --- | --- | --- | --- | --- | --- |
| A | core | `skip-unprovided-provider-demands` | `docs/skip-unprovided-provider-demands` | 1 | now | first |
| B | library | `render-skips-unprovided-provider-demands` | `feat/render-skips-unprovided-provider-demands` | 1 | now | after A |
| C | cli | `retire-local-default-platform` | `feat/retire-local-default-platform` | 1 | now | independent of A and B |
| D | cli | `add-skip-unprovided-flag` | `feat/add-skip-unprovided-flag` | 2 | C merged and B's branch pushed | after B is released |

What each hands on:

- **A** states the rule in `core/SPEC.md` (§2.1, §3.1) and the `contract-fulfilment` capability. SPEC-only: the published CUE is unchanged, so there is no core release and no consumer pin moves.
- **B** implements A's rule in the kernel and publishes the interface below in a library release.
- **C** changes the platform precedence every render-bearing cli command uses; D builds on it.
- **D** exposes B's switch as `--skip-unprovided`.

## Interface B → D

The contract D consumes. B may refine names only by reporting the change under `deviations`; D codes against what B reports under `surface`.

```go
package kernel // github.com/open-platform-model/library/opm/kernel

type RenderInput struct {
	// ...existing fields unchanged...

	// SkipUnprovided renders what the platform can when a component demands
	// a provider-fulfilled contract that no enabled catalog provides (zero
	// providers). Off, the default, refuses such a render as today.
	SkipUnprovided bool
}

type RenderDiagnostics struct {
	// ...existing fields unchanged...

	// Skipped is every demand the render skipped under
	// RenderInput.SkipUnprovided, in build order. Always empty when the
	// switch is off.
	Skipped []SkippedDemand
}

// SkippedDemand is one provider-fulfilled demand skipped because nothing on
// the platform provides it.
type SkippedDemand struct {
	Component        string   // the demanding component
	FQN              string   // the demanded contract key
	Kind             string   // "resource" or "trait"
	DefinedBy        string   // registry key of the enabled catalog listing the key; "" when none
	Alternatives     []string // same-base keys implemented at another apiVersion
	ComponentOmitted bool     // true on every row of a component that rendered nothing (it has a skipped resource demand)
}
```

```go
package errors // github.com/open-platform-model/library/opm/errors

type UnresolvedDemand struct {
	// ...existing fields unchanged...

	// Unprovided is true when the demanded contract is provider-fulfilled
	// and no enabled catalog provides it: exactly the demands
	// RenderInput.SkipUnprovided would skip.
	Unprovided bool
}
```

The rule behind it (A states it, B enforces it):

1. The switch is the caller's, per render. Off, nothing changes.
2. A demand is skippable when its contract declares `fulfilment: "provider"` and zero enabled catalogs carry a transformer requiring that key. A provider that exists but did not match, a catalog-fulfilled demand, and an over-subscribed contract still refuse.
3. A skipped trait demand: the component renders every pair it matched, and the trait produces nothing.
4. A skipped resource demand: the component renders nothing at all (a partly satisfied component never renders), and it is not reported as unmatched. Every skipped row of that component carries `ComponentOmitted`; a frontend words "not rendered" once per component from it.
5. Every skipped demand is reported. Nothing is skipped silently.
6. Optional traits are unaffected: an unhandled optional trait was already a warning.

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

1. **Wave 1.** Launch workers for A, B and C in parallel, each with this change's `orchestration.md` as its brief.
2. **Check each report.** Compare `deviations` and `surface` against `design.md` and the interface above. Send a worker back with a precise ask rather than fixing its branch yourself.
3. **Finalize A, B, C.** For each, in the worktree: `openspec archive <change> --yes`, commit the archive (`chore(openspec): archive <change>`), push, open the PR per the repo's `AGENTS.md`. Merge order: A before B; C independently. After B merges, merge the library release PR that release-please opens and note the released version.
4. **Wave 2.** Once C is merged and B's branch is pushed, launch D's worker. Until B is released it develops against B's pushed head as a Go pseudo-version. Once B is released, tell D's worker the version; it rebases on `origin/main`, pins the release, reruns its gates and pushes. Then finalize D as in step 3.
5. **Follow-ups.** Run the out-of-repo follow-ups each change's `orchestration.md` lists, after the merge they wait on.

Every PR follows its repo's `AGENTS.md`: a body of at most 250 words, no bare `@name`, only the plain co-author trailer. Merging, releasing and pushing to `main` need the user's go-ahead.

## This change (A)

- **Repo and branch:** `core`, branch `docs/skip-unprovided-provider-demands`, worktree `core/.claude/worktrees/skip-unprovided-provider-demands`.
- **Setup in the worktree:**
  - `core` is pure CUE, and every task runs from the worktree root.
  - Export `CUE_REGISTRY` and `OPM_REGISTRY` as the workspace root `AGENTS.md` Registry Policy gives them.
  - Run `task hooks:install` once, so the SPEC.md co-update pre-commit hook is active in the worktree. The hook passes a `SPEC.md`-only commit.
  - The section gate is `task check`. `task fmt:check` diffs the git index, so stage before running it.
- **Waits on:** nothing. Wave 1.
- **Hands off:** the normative rule in `SPEC.md` §2.1 (`fulfilment: "provider"`, the zero-providers exception), §3.1 Constraints (the skip bullet) and §3.1 Rationale, plus the `contract-fulfilment` capability requirement "A render's caller may skip unprovided provider-fulfilled demands". B cites these sections from its kernel code and specs. Report the exact bullet wording under `surface`.
- **Release:** none. The commit is `docs(spec):`, the published CUE is byte-identical, and release-please opens no release for it. No consumer pin moves.
- **Follow-ups outside this repo:** none.
- **Follow-ups in this repo, after D merges:** update `docs/site/concepts/how-matching-works.md` and `docs/site/concepts/platforms-and-catalogs.md`, which say an unresolved provider demand always refuses, to name the cli's `--skip-unprovided`. This is a plain docs PR, not part of this change.
