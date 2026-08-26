## 1. `.tasks/doc-check.sh`

- [ ] 1.1 Write the script per design (header comment in `spec-check.sh` style, `LC_ALL=C`, `src/` scan excluding `cue.mod/` and `*_pins.cue`, awk run counter, field-label match per D4, `--strict` / `DOC_CHECK_STRICT=1`, summary line).
- [ ] 1.2 Verify against `main`: reports exactly the over-6 sites in schema files, none from `*_pins.cue`, none from `package` or `let` lines; exits 0 without `--strict` and 1 with it.
- [ ] 1.3 Verify no false positives on a scratch file containing a detached `// WHY` block below a field, a multi-paragraph doc using an empty `//` line, and a trailing same-line comment.

## 2. `Taskfile.yml` and `ci.yml`

- [ ] 2.1 Add `docs:check` and append it to `check` after `spec:check`.
- [ ] 2.2 Add the CI step after "Verify SPEC.md inventory matches CUE".

## 3. Rule text

- [ ] 3.1 `CLAUDE.md`: "Doc comments" subsection under CUE Style Guidelines (three tiers, 6-line limit, blank line detaches, `// WHY` below the field, pins exempt); add `task docs:check` to the Build And Dev Commands table and to the `task check` description line.
- [ ] 3.2 `.claude/skills/core-schema-edit/SKILL.md`: "Writing comments" section with the three tiers and one before/after example lifted from `src/component.cue` `resourceName`.

## 4. Validation

- [ ] 4.1 `task check` passes (fmt, vet, INDEX, SPEC inventory unchanged; `docs:check` prints its report and exits 0).
- [ ] 4.2 Confirm `src/` is untouched (`git status` shows no `src/` changes) so the SPEC co-update gates do not fire.
