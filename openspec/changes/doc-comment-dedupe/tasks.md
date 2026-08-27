## 1. Rule

- [x] 1.1 `CLAUDE.md` § Doc comments tier 2: state a rationale once
- [x] 1.2 `.claude/skills/core-schema-edit/SKILL.md` § Writing comments: same sentence

## 2. Collapse duplicated WHY blocks (comment-only, `SPEC_IMPACT=none`)

- [x] 2.1 `src/trait.cue` and `src/blueprint.cue` `#nameConstraint`: pointer to `#Resource`; fix the `§ 2.2` / `§ 3.3 Rationale` pointers
- [x] 2.2 `src/component.cue` `resourceName`, `_matchLabelsAreDerived`, `_nameFits`
- [x] 2.3 `src/resource.cue` `fulfilment`; re-wrap the over-long line

## 3. `backup` marked hypothetical

- [x] 3.1 `SPEC.md` § 2.1 (full sentence), § 2.2 and § 3.1 (short form); "`catalog_opm` declares" becomes "a catalog"
- [x] 3.2 `src/trait.cue`, `src/resource.cue`, `src/types.cue`, `src/platform_and_match_pins.cue` parentheticals; `identity_pins.cue` untouched

## 4. Verification

- [x] 4.1 Every touched `src/*.cue` code-identical to `main` (comments and blank lines stripped); `cue fmt` idempotent; blank line after every WHY block
- [x] 4.2 `task check` (fmt, vet, INDEX, spec:check, strict docs:check)
- [x] 4.3 `grep -n hypothetical SPEC.md src/*.cue` lists the introduction points only
