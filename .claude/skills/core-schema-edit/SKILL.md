---
name: core-schema-edit
description: Required protocol for any edit to core/src/*.cue files. Documents the SPEC.md four-part section format, the rule that schema changes co-commit with SPEC.md updates, and the spec:check gate.
user-invocable: true
---

# Core Schema Edit Protocol

## When this applies

Any task that adds, modifies, renames, or removes a top-level CUE definition in `core/src/*.cue` that is listed in `.tasks/spec-tracked.txt`. The allowlist is the source of truth for which constructs require documentation; current entries include `#Resource`, `#Component`, `#Module` (more added as SPEC.md grows).

Helper types — collection maps (`*Map`), constrained-string types (`*Type`), label constants (`#Label*`), name transformers (`#KebabTo*`), and internal pipeline helpers (`#AutoSecrets`, `#DiscoverSecrets`, `#GroupSecrets`, `#OpmSecretsComponent`, `#ContentHash`, `#SecretContentHash`, `#ImmutableName`, `#SecretImmutableName`, `#TransformerContext`, `#SecretsResourceFQN`) — are out of scope. If you add a new top-level construct that ISN'T a helper, add it to `.tasks/spec-tracked.txt` and write its SPEC.md section in the same commit.

## Core rule

**Every change to a tracked construct's behavior MUST update `core/SPEC.md` in the same commit.**

| Schema change | SPEC.md update |
| --- | --- |
| New tracked construct | Add a new `## N.M #ConstructName` section (four parts — see below). |
| Renamed construct | Rename the section header and every in-text reference. |
| Modified constraint (added / removed / loosened / tightened) | Update the Constraints list AND add a *Why* paragraph in Rationale explaining the change. |
| Modified field set | Update the Shape block. |
| Removed construct | Delete the section. If downstream consumers may search for the old name, leave a "Removed in vN.M (see #Replacement)" stub. |

Genuinely spec-neutral edits (whitespace, doc-comment typo fixes, formatting only) bypass the local gate with:

```bash
SPEC_IMPACT=none git commit ...
```

Document the reason in the commit body with a `Spec-Impact: none (reason)` trailer. For PRs that need the CI gate bypassed, put `Spec-Impact: none` in the PR body with the same justification.

## The SPEC.md section format

Every tracked construct gets a section with **four parts**, in this order:

### Definition

One paragraph of prose. What the construct is and where it sits in the type system. No code.

### Shape

The CUE definition, simplified for readability if helpful. Field-level inline `//` commentary is fine. End with `Implementation: [file.cue](file.cue)` linking to the source.

### Constraints

Bulleted list. Each item uses RFC 2119 keywords (MUST, MUST NOT, SHOULD, MAY) and describes observable behavior or invariants — not implementation details.

### Rationale

Bulleted list. Each item leads with **"Why X."** and answers a question a future contributor would actually ask. Two flavors are most valuable:

- **Positive rationale** — *Why X is required.* Anchor in the consequence the requirement enforces.
- **Negative rationale** — *Why we don't allow Y.* Anchor in the class of bug or wrong model the prohibition prevents.

Avoid vacuous rationale ("for flexibility," "for consistency"). If the *why* fits in those words, the constraint probably doesn't need to exist.

End the section with a "See also" subsection linking the tutorial counterpart in `docs/` and structural relationships to peer constructs.

## Writing comments

A `//` block that ends on the line directly above a field or definition is its doc comment. Hover in the LSP, `Value.Doc()`, `cue def` and `task generate:index` all replay it verbatim, so it is consumer-facing text. One blank line ends the block: a comment separated from the field by a blank line is not a doc comment, and `cue fmt` keeps that blank line.

Three tiers, in this order of preference:

| Tier | Where | What goes there |
| --- | --- | --- |
| Doc comment | directly above the field, at most 6 lines | the contract: what it is, what a consumer must satisfy, optionally `See SPEC.md § N.M` |
| `// WHY ...` block | above the doc comment, separated by one blank line | rationale that must stay next to the code: measured cue behavior, refuted spellings, `Was:` history |
| `SPEC.md` Rationale | the construct's section | the full argument (the Core rule above already requires it) |

State a rationale once. A WHY paragraph that restates a SPEC.md Rationale bullet collapses to the bullet's title in the closing pointer; when several definitions share one rule (`#nameConstraint` on the three primitives), one carries the WHY block and the others a two-line pointer to it.

Before (everything is hover text):

```cue
	// Per-component resource-name override. Defaults to the
	// instance-qualified name `<instance>-<component>` (enhancement 0019
	// D16); an explicit value wins via the disjunction-default cascade.
	//
	// The default branch is deliberately NOT unified with a type: on cue
	// v0.17.1 a failed validated default degrades to a bare `incomplete
	// value` that never names the offending string. The error() arm is
	// reported only when every other arm fails.
	resourceName: *"\(#instance.name)-\(name)" | #ObjectNameType | error("...")
```

After (hover shows three lines; the rationale stays in the file, directly above, and reads first):

```cue
	// WHY the default branch is NOT unified with a type: on cue v0.17.1 a
	// failed validated default degrades to a bare `incomplete value` that
	// never names the offending string. The error() arm is reported only when
	// every other arm fails (enhancement 0019 D16; SPEC.md § 3.1 Rationale).

	// Per-component resource-name override. Defaults to the
	// instance-qualified name `<instance>-<component>`; an explicit value
	// wins and must be a DNS subdomain (#ObjectNameType). See SPEC.md § 3.1.
	resourceName: *"\(#instance.name)-\(name)" | #ObjectNameType | error("...")
```

`task docs:check` (part of `task check`) fails on every doc comment over 6 lines; `*_pins.cue` fixture files are exempt, hidden `_` fields in schema files are not. Never fix a report by deleting a blank line; split the block and keep the contract as the attached part.

## Workflow

When editing a `core/src/*.cue` file:

1. Make the schema change.
2. Update the corresponding section in `core/SPEC.md`:
   - Shape kept in sync with the CUE.
   - Constraints adjusted to match the new schema.
   - Rationale explains *why* any non-obvious change exists. New constraint → new bullet. Removed constraint → either delete the bullet or note the removal if removal itself needs explanation.
3. Run `task spec:check` from `core/` — verifies inventory match.
4. Run `task check` — runs fmt, vet, INDEX freshness, `spec:check`, and the `docs:check` limit.
5. Stage the `.cue` change(s) and `SPEC.md` together in one commit.

## Verification gates (mechanical, cannot skip without explicit override)

- **Local pre-commit hook** — refuses any commit that stages `*.cue` without `SPEC.md` unless `SPEC_IMPACT=none` is set. Install with `task hooks:install`.
- **`task spec:check`** — three-direction inventory check, wired into `task check`. Catches: allowlist entries with no section in SPEC.md; allowlist entries not defined in any `.cue` file (stale allowlist after rename); SPEC.md references not defined in any `.cue` file (stale section after rename).
- **CI co-update gate** — `.github/workflows/ci.yml` rejects PRs that change `*.cue` without `SPEC.md` unless the PR body contains `Spec-Impact: none`.

## Subagent note

If you are a subagent dispatched to edit `core/src/*.cue`, the parent agent's CLAUDE.md is not loaded into your context. Read this skill in full before making changes. The mechanical gates will block your commit if you skip the SPEC.md update — saving you a wasted iteration but only if you have the format ready when you write it.
