## 1. Pins move into src/pins/

- [ ] 1.1 Measure the "before" row on a scratch copy of the untouched `src/` (`cp -a src <scratchpad>/j2-before`), using the j2 harness (`scratchpad/exp/pins/harness/h -dir <copy> -mode lookup`, 5 fresh runs). Record build time, HeapAlloc and allocated MB.
- [ ] 1.2 `src/*_pins.cue` → `src/pins/` by `git mv`, keeping each file name (design D1). In each file:
  - Replace `package core` with `package pins`.
  - Add `"opmodel.dev/core@v2"` to the import block, beside `strings` where that is already imported.
  - Qualify every reference to a core top-level label with `core.`: every `#Definition` declared in a non-pin `src/*.cue` file, plus `OPMNamespace`. Cover string interpolations, `...` spreads and the commented-out MUST-FAIL bodies. Leave field labels inside a pin (`#resources:`, `#catalogs:`) and prose in backticks unqualified.
  - Review the diff for every core `#Name` left unqualified in a comment code line.
  - Verify: `task vet` passes and, after staging (`fmt:check` diffs the git index), `task fmt:check` is clean.
- [ ] 1.3 Rewrite the header comment of each moved file (design D2). `identity_pins.cue` carries the full statement: hidden fields of package `pins`, which imports `core` and which nothing imports, vetted by `task vet`, never loaded by a consumer. The six companions point to it and drop "while an importing package never does". Change every recorded `cue export` command (`identity_pins.cue`, `identity_package_pins.cue`, `platform_and_match_pins.cue` twice, `platform_contracts_pins.cue`) from `./...` or `./` to `./pins`, re-run each from `src/` against the uncommented case in a scratch copy, and update the recorded output if it differs. Rewrite the `platform_and_match_pins.cue` paragraph on why the gate pins stay hidden for package `pins` (design D2). Verify: `grep -n "cue export .*\./\(\.\.\.\)\?'\?$" src/pins/*.cue` prints nothing, and every hit of `grep -n -i 'importing package' src/pins/*.cue` is the new structural wording.
- [ ] 1.4 Prove the gate on a scratch copy of the finished tree, never in the worktree (design D3):
  - Add `src/pins/zz_broken_pins.cue` holding `_pinBroken: 1 & 2`. `cue vet ./...` from `src/` must fail with `_pinBroken: conflicting values 2 and 1`, and `cue vet .` must pass.
  - In a scratch copy, script an uncomment of every commented MUST-FAIL case one at a time, in place, and assert that no run reports `reference "#..." not found` and that each gives its recorded first error. Fix any recorded error that no longer matches. (`platform_contracts_pins.cue` has no commented case.)
- [ ] 1.5 `SPEC.md`: re-point the links to `src/identity_pins.cue` (§3.2 Rationale) and `src/component_names_pins.cue` (§3.1 Rationale) at `src/pins/`. Verify: `grep -n 'src/[a-z_]*_pins.cue' SPEC.md` prints nothing.
- [ ] 1.6 Measure the "after" rows on a scratch copy of the finished `src/` with the same harness: core as main instance (`-pkg .`), and package `pins` as main instance (`-pkg ./pins -mode err`, which must report no error). Write both rows and the before row from 1.1 into design.md, "What the move saves a consumer", replacing the prototype figures if they differ.
- [ ] 1.7 Run `task generate:index` and `task docs:reference`. Both are expected to leave `src/INDEX.md` and `docs/site/reference/definitions/` unchanged, because `pins/` declares no definition. Review any diff before keeping it.
- [ ] 1.8 `grep -nE "^_" src/*.cue` prints nothing (package `core` declares no top-level hidden field). `task check` green, then commit `perf(pins): move the schema pins into a src/pins subpackage`. The commit carries `SPEC.md` (task 1.5), so it needs no `SPEC_IMPACT=none` escape.

## 2. Repo rules and site notes name src/pins/

- [ ] 2.1 `AGENTS.md`:
  - Repository Layout: add a `src/pins/` line (test-only package `pins`, the schema pins, imports `core`, nothing imports it), and extend the paragraph after the tree to say the same.
  - The two `*_pins.cue` exemption sentences in CUE Style Guidelines stay true by file name. Edit them only to name `src/pins/` where they say where the files live.
- [ ] 2.2 `openspec/config.yaml` Principle IV: add one bullet saying that the published schema is the single `core` package, that pins live in the test-only package `pins` in `src/pins/`, and that a pin never goes in package `core`, because every main-instance build of core would evaluate it. Verify: `openspec validate move-pins-into-subpackage --strict` still passes, since it reads this file.
- [ ] 2.3 `.claude/skills/core-schema-edit/SKILL.md`: where it covers pins and the doc-comment exemption, state that a new pin goes in `src/pins/` as package `pins` and references core as `core.#X`.
- [ ] 2.4 `docs/site/`: in every "Check against" HTML comment, change `core/src/<name>_pins.cue` to `core/src/pins/<name>_pins.cue` (`docs/site/concepts/components-and-blueprints.md`, `identity-and-names.md`, `versions.md`, `what-enforces-a-rule.md`). Verify: `grep -rn 'core/src/[a-z_]*_pins.cue' docs/ AGENTS.md .claude/ openspec/config.yaml` prints nothing.
- [ ] 2.5 `task check` green, then commit `docs: name src/pins as the home of the schema pins`. The section stages no `.cue` file, so the SPEC_IMPACT hook does not fire.
