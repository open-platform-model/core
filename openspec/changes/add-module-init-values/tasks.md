## 1. Add `initValues` to `#Module`

One section: the schema edit, its SPEC.md section and the pins cannot land apart (Principle II), and design.md carries no unverified assumption (the spike is recorded in § Research & Decisions).

- [ ] 1.1 Read `.claude/skills/core-schema-edit/SKILL.md` before touching `src/*.cue`
- [ ] 1.2 In `src/module.cue`, add `initValues?: _` directly after `debugValues`, with the doc comment and separate `// WHY` block from design.md § Shape (doc comment at most 6 lines, no enhancement reference in it); verify `task vet` and `task docs:check` are green
- [ ] 1.3 Add `src/module_init_values_pins.cue` with one pin per spec scenario (design.md § Pins): concrete and non-concrete `initValues` validate, the disjunction reads back, non-conforming `initValues` validates, both fields keep their own content, module and instance uuids are unchanged, an instance deploying a module with non-concrete `initValues` validates. Record the `initValuez` MUST-FAIL case commented out with the error `task vet` printed when it was uncommented once; verify `task vet` is green
- [ ] 1.4 Update `SPEC.md` § 3.2 `#Module`: add `initValues?: _` to Shape; add Constraints (optional and open, MAY be non-concrete, NOT asserted against `#config`; a module setting it requires a core release that ships it; inert for `fqn`, `uuid` and `debugValues`); add Rationale bullets "Why a dedicated field instead of reusing `debugValues`" and "Why `initValues` is not unified with `#config`" (text from `enhancements/0016/schemas/spec.md`); verify `task spec:check` is green
- [ ] 1.5 Add `initValues` beside `debugValues` in the `#Module` walkthrough of `docs/constructs.md`, saying `opm instance init` reads it first and falls back to `debugValues`
- [ ] 1.6 Run `task generate:index`, review the regenerated `src/INDEX.md`, and hand-add `module_init_values_pins.cue` to its Project Structure tree; verify `task generate:index:check` is green
- [ ] 1.7 `task check` green, then commit `feat(module): add optional initValues to #Module`
