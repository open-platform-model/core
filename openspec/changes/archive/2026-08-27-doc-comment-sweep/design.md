## Context

See proposal.md for motivation and `openspec/changes/archive/2026-08-27-doc-comment-gate/design.md` for the parser facts (one blank line detaches a comment; `cue fmt` preserves it; every hover surface keys on the same flag). The convention and its example live in `CLAUDE.md` § Doc comments and `.claude/skills/core-schema-edit/SKILL.md` § Writing comments; this design does not restate them.

Constraints: code bytes MUST NOT change; `SPEC.md` MUST NOT change (an edit there makes the commit a spec change and defeats `Spec-Impact: none`); every commit MUST leave `task check` green; the gate stays warn-only until the last task so intermediate commits never fail.

## Goals / Non-Goals

**Goals:**

- Zero sites reported by `task docs:check`, then strict.
- Every doc comment reads as the contract for that field on its own.
- No rationale lost: every sentence that leaves a doc comment is either in a `// WHY` block or already present in `SPEC.md`.

**Non-Goals:**

- Improving or correcting the content of any comment. If a comment is found to be wrong, note it in the PR and leave it; fixing prose is a separate `docs:` change, and fixing behavior is a schema change.
- Adding rationale to `SPEC.md`.
- Touching trailing same-line comments, `package` docs, or the pins files.
- Reformatting anything `cue fmt` does not already produce.

## Decisions

### D1. Split rule, applied identically at every site

The doc comment keeps, in this order and only as far as 6 lines allow: what the field is; what a consumer must satisfy or what the value is derived from; a `See SPEC.md § N.M` pointer when the construct is tracked. Everything else moves into one `// WHY` block above the doc comment, separated by one blank line (D8), opened with `// WHY <topic>:` and otherwise verbatim, paragraph breaks kept as empty `//` lines. One block per field; a field with two rationale paragraphs gets one block with two paragraphs, not two blocks.

**Alternative rejected**: rewriting the rationale while moving it. Any rewrite is a content change hiding inside a relocation commit and cannot be verified mechanically.

### D2. Pointer instead of `// WHY` only when `SPEC.md` already carries the same argument

Where the moved text is a near-verbatim duplicate of a `SPEC.md` Rationale bullet (measured: `component.cue` `resourceName`, `_nameFits`, `_matchLabelsAreDerived`; `resource.cue` `fulfilment`; `trait.cue` `optional`), the `// WHY` block is reduced to `// WHY: see SPEC.md § N.M Rationale, "Why ...".` naming the bullet. "Near-verbatim" means the SPEC bullet states the same claim and the same measurement; if the comment carries a fact the SPEC bullet lacks (a cue version, an experiment number, a refuted spelling), the block keeps that fact.

**Alternative rejected**: always keeping the full text in the file. Two copies of an argument drift, and `SPEC.md` is the gated one.

### D3. Hidden fields get the same treatment

`_matchLabelsFromPrimitives`, `_matchLabelsAreDerived`, `_nameConstraints`, `_nameFits`, `_keyVersion` are hovered by every contributor and are the densest sites. Same split; their doc comment states what the hidden field asserts, and the `// WHY` block keeps the "IF THIS FIRES" and "spellings that read as equivalent are wrong" material.

### D4. Definition-level docs (`#Catalog`, `#IdentityPackage`, `#Subscription`, `#Platform`, `#ComponentTransformer`, the `*Type`s)

A definition's doc comment is what `INDEX.md` and the docgen use as its description. Keep the one-paragraph "what it is" and the key invariant; the `// WHY` block goes above the definition's doc comment like any other (D8).

### D5. Mechanical verification, per commit and at the end

- Code identity: `diff <(sed -E '/^[[:space:]]*\/\//d' before) <(sed -E '/^[[:space:]]*\/\//d' after)` is empty for every file. Full-line comments are the only lines the sweep may touch, so stripping them must leave identical text. Trailing comments are not stripped and therefore also verified unchanged.
- Content preservation: the number of `//` lines per file does not decrease, except by the exact count of lines replaced by a D2 pointer, which the commit message states.
- `cue fmt` idempotent on the result; `task check` green (vet, INDEX regenerated, SPEC inventory unchanged, `docs:check` count falling).

### D6. Two passes, as requested

Pass one does the split file by file. Pass two is a fresh read of every touched file after pass one is complete, with three questions per site: does the doc comment state the contract without the `// WHY` block; did any sentence disappear (compare `git diff` hunks, not memory); is the blank line above every `// WHY` block present. Pass two fixes what it finds in a single follow-up commit per file rather than amending, so the review can see what the second pass caught.

### D7. Commit granularity

One `docs(<file-stem>):` commit per file, `SPEC_IMPACT=none`, trailer `Spec-Impact: none (comment relocation only)`; one `chore(tasks):` commit for the strict flip and wording; one `docs(index):` commit if `src/INDEX.md` changes independently, otherwise regenerated in the last file commit. One PR.

### D8. `// WHY` blocks sit ABOVE the doc comment, not below the field

**Context**: The gate change (`2026-08-27-doc-comment-gate`, D1) placed notes below the field, arguing that a blank-separated note above reads as the previous field's and could silently reattach. Pass-one review (2026-08-27) rejected the first half: to a human reader every comment above a field belongs to the field below, wherever the blank line sits. The second half is moot: closing the blank line merges note and doc into one over-limit block, which `docs:check` reports.
**Explored**: Both placements on all 51 sites; `cue fmt` stability and `docs:check` for each.
**Decision**: Rationale, blank line, contract, field. Natural reading order. Amends the gate change's D1; `CLAUDE.md`, the `core-schema-edit` skill and the script header change wording in this change, and `catalog_opm` takes the same wording fix before its own sweep.

## Risks / Trade-offs

- [A first sentence rewritten for length changes the `INDEX.md` row and the docgen description] -> intended; review the regenerated `INDEX.md` diff explicitly (task 6.2).
- [The blank line between a `// WHY` block and its doc comment dropped] -> `docs:check` reports the merged block as an over-limit doc; pass two checks the blank line by hand.
- [A D2 pointer references a SPEC bullet that later gets reworded] -> pointers name the bullet's "Why ..." lead-in, which the `core-schema-edit` format keeps stable.
- [Review fatigue across 51 sites] -> one commit per file, verification lines in each commit message, second pass as separate commits.

## Migration Plan

None for consumers. Rollback is `git revert` of the PR; nothing depends on the layout.
