## Context

Follow-up to the archived `doc-comment-sweep`. Same mechanism, same harness (code identity vs `main`, `cue fmt` idempotence, blank line after every WHY block, strict `task docs:check`). Sites and the SPEC.md bullets they duplicate were enumerated before editing: § 2.1 Rationale lines 130-134, § 3.1 Rationale lines 360-367.

## Decisions

### D1. State a rationale once

A WHY block keeps only what SPEC.md cannot hold: measured evaluator behaviour on a named cue version, refuted spellings, `Was:` history. Anything else that a SPEC.md Rationale bullet already says collapses to that bullet's title in the closing pointer. Shared rules live on one definition; the others carry a two-line `// WHY: see <owner>` pointer. Alternative rejected: keep the duplicates and add a parity check; there is no mechanical way to compare prose across a `.cue` comment and a Markdown bullet, so drift would still be caught only by review.

### D2. Sites

`#nameConstraint`: `resource.cue` keeps the full block; `trait.cue` and `blueprint.cue` carry a three-line pointer to `#Resource.#nameConstraint` and SPEC.md § 2.1. `fulfilment`: keeps the value table, the "declaration, not an enforcement" paragraph and the k8up/Velero false-negative measurement; drops the derivation and closed-enum paragraphs (SPEC.md:130-132). `resourceName`: keeps the cue v0.17.1 validated-default paragraph; the default/ceiling paragraph becomes three bullet titles (SPEC.md:364-366). `_matchLabelsAreDerived`: keeps the measured `close()` sentence; length-comparison and fragment arguments become the SPEC.md:360 pointer. `_nameFits`: the two refuted spellings compressed to one sentence each; the full refutation is SPEC.md:367. Dropped-sentence rule: every dropped sentence was checked to exist in the cited bullet before dropping; none was deleted from the system.

### D3. `backup` stays, marked hypothetical

Alternatives: rename every occurrence to an obviously fictional contract (~60 edits including pins FQNs and their commented expected-error transcripts, which would then need re-running); substitute a real member (none carries `fulfilment: "provider"` or trait-level `optional: true`, so the substitution would itself be false). Chosen: one full sentence at the first SPEC.md mention (§ 2.1), a parenthetical at each other introduction point, and "a catalog" replacing "`catalog_opm`" where the text claimed the catalog declares it. `identity_pins.cue` untouched: its `backup` FQNs are fixture values, not claims about a catalog.

### D4. Commit shape

Comment-only commits carry `SPEC_IMPACT=none` with a `Spec-Impact: none (...)` trailer naming the SPEC bullets. The `backup` commit stages SPEC.md and needs no bypass. The `resource.cue` commit carries its `backup` parenthetical because it sits inside the rewritten `fulfilment` block.

## Risks / Trade-offs

- [A dropped sentence was not actually in SPEC.md] -> checked line by line against the printed bullets before editing; the diff is small enough to re-read in review.
- [A future author re-inflates a WHY block] -> D1 is in both rule sources; `docs:check` still bounds the doc comment but not the WHY block, by design.

## Open Questions

None.
