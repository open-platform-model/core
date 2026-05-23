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

## Workflow

When editing a `core/src/*.cue` file:

1. Make the schema change.
2. Update the corresponding section in `core/SPEC.md`:
   - Shape kept in sync with the CUE.
   - Constraints adjusted to match the new schema.
   - Rationale explains *why* any non-obvious change exists. New constraint → new bullet. Removed constraint → either delete the bullet or note the removal if removal itself needs explanation.
3. Run `task spec:check` from `core/` — verifies inventory match.
4. Run `task check` — runs fmt, vet, INDEX freshness, and `spec:check`.
5. Stage the `.cue` change(s) and `SPEC.md` together in one commit.

## Verification gates (mechanical, cannot skip without explicit override)

- **Local pre-commit hook** — refuses any commit that stages `*.cue` without `SPEC.md` unless `SPEC_IMPACT=none` is set. Install with `task hooks:install`.
- **`task spec:check`** — three-direction inventory check, wired into `task check`. Catches: allowlist entries with no section in SPEC.md; allowlist entries not defined in any `.cue` file (stale allowlist after rename); SPEC.md references not defined in any `.cue` file (stale section after rename).
- **CI co-update gate** — `.github/workflows/ci.yml` rejects PRs that change `*.cue` without `SPEC.md` unless the PR body contains `Spec-Impact: none`.

## Subagent note

If you are a subagent dispatched to edit `core/src/*.cue`, the parent agent's CLAUDE.md is not loaded into your context. Read this skill in full before making changes. The mechanical gates will block your commit if you skip the SPEC.md update — saving you a wasted iteration but only if you have the format ready when you write it.
