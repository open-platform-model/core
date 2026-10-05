Before editing any `src/*.cue` file, load `.claude/skills/core-schema-edit/SKILL.md`. All raw `cue` commands run from `src/`. Line numbers were taken at `origin/main` 8dbb7e7, so re-check them before editing.

## 1. Bind the component attachment maps

`#ResourceMap`, `#TraitMap` and `#BlueprintMap` bind each entry's `metadata.fqn` to its key. In the same commit, core's short-key pins are rewritten so that `task vet` stays green.

- [ ] 1.1 Change `src/resource.cue:172`, `src/trait.cue:165` and `src/blueprint.cue:122` to the shapes in `design.md` § The component maps (`[FQN=string]: #X & {metadata: fqn: FQN}`). `#ResourceMap` gets the doc comment and its WHY block. `#TraitMap` and `#BlueprintMap` get a short doc comment that points to it. Each comment is at most 6 lines, with no enhancement reference. Then verify that `cue vet .` passes (package core alone).
- [ ] 1.2 In `src/pins/component_names_pins.cue`, re-key every `#resources: container:` (:118, 131, 142, 151, 164, 175, 185) as `(_pinNameContainer.metadata.fqn):`, and do the same in the commented must-fail twins (:203, 215, 227, 238, 250, 262). Uncomment each twin in place, one at a time, and run `cue vet ./...`. Where a path in the recorded error changes, update the recorded text to what the tool printed. Comment the twin out again.
- [ ] 1.3 In `src/pins/platform_and_match_pins.cue`, re-key `container:` and `volumes:` (:118-119) and `#resources: container:` (:330) by `(_pinMatchContainer.metadata.fqn)` and `(_pinMatchVolumes.metadata.fqn)`. Change the read-backs at :151-152 to index `[_pinMatchContainer.metadata.fqn]` and `[_pinMatchVolumes.metadata.fqn]`. Re-key the commented twins (:463, 489, 514, 537) and re-measure them as in 1.2.
- [ ] 1.4 Under a new banner "Attachment keys equal the member's fqn" in `src/pins/platform_and_match_pins.cue`, add:
  - A positive pin per map (resource, trait, blueprint): a component keyed by fqn, read back by an interpolation of the entry's `metadata.fqn`.
  - A bind-fill pin: a member that leaves `fqn` unset, attached under its contract key, whose read-back `metadata.fqn` equals the key. Add this pin to the `cue export ./pins -e '[...]'` list in `Taskfile.yml`'s `vet` task, so that an unbound map leaves the read-back incomplete and `task vet` fails.
  - Three commented must-fail cases: `_failShortResourceKey` (`container:`), a trait under another trait's fqn, and a blueprint under another blueprint's fqn. Record the error that each prints when uncommented in place. Quote the first line, and say that follow-on `field not allowed` lines exist where they do.

  Mutation check: remove the bind from `#TraitMap` only, confirm that `task vet` fails, then restore it.
- [ ] 1.5 Update `SPEC.md` §3.1 `#Component`:
  - Shape: the three map lines carry a comment saying that the key is bound to the member's fqn.
  - Constraints: add a bullet saying that every `#resources`, `#traits` and `#blueprints` key MUST equal the entry's `metadata.fqn`, and that a differing key fails with `conflicting values "<key>" and "<fqn>"` at `<map>.<key>.metadata.fqn`. A short key such as `container` is refused. A blueprint-contributed entry keyed by fqn validates. The binding derives nothing from `name` or `modulePath`.
  - Rationale: add "Why an attachment key must equal the member's fqn". Every reader treats the key as identity: `#Platform.#contracts`, and the render build's demand match by key. A short key validated and then demanded a contract nobody supplies. The key stays `string` so that the error names both strings.

  Then verify that `task spec:check` passes.
- [ ] 1.6 Run `task generate:index`, then review the three map rows in `src/INDEX.md`, which now carry descriptions. `docs-kit.cue` already excludes the three maps as "map shorthand", so no placement change is needed. Verify that `task generate:index:check` passes.
- [ ] 1.7 Run `task fmt` and stage the files. Then `task check` must pass, because `fmt:check` diffs the git index. Commit `feat(component)!: bind attachment map keys to the member's fqn`, with a `BREAKING CHANGE:` footer that names the component maps and the `(X.metadata.fqn): X` fix.

## 2. Bind the catalog contract maps

`#Catalog.#resources`, `#traits` and `#blueprints` bind each member's `metadata.fqn` to its key. `#transformers` is unchanged (SD13).

- [ ] 2.1 In `src/catalog.cue`, rewrite the three contract-map patterns as `[K=#ContractFQNType]` and add `fqn: K` beside the stamps (`design.md` § The catalog maps). Update the `#resources` doc comment ("never fqn" becomes "binds fqn to the key") and the `#traits` and `#blueprints` doc comments if they repeat it. In the file header, the paragraph "It does NOT stamp `metadata.fqn`" stays true for `#transformers`. Add one sentence saying that the contract maps bind fqn to the key. Then verify that `cue vet .` passes.
- [ ] 2.2 In `src/pins/catalog_pins.cue:99-116`, replace `_pinContractKeyNotCompared` and its read-back with:
  - a commented must-fail case `_failContractKeyMismatch` that records the conflicting-values error (re-run in place under that name; `design.md` has the text measured at planning);
  - a positive read-back pin for each of the three maps, keyed by fqn;
  - commented must-fail cases for a mis-keyed resource member and a mis-keyed blueprint member.

  Rename the banner to "A contract key must equal its member's fqn". Grep `src/pins/` for any other contract-map entry that does not key by fqn, and re-key it.
- [ ] 2.3 Update `SPEC.md` §3.6 `#Catalog`:
  - Constraints: replace the bullet "The contract maps do NOT stamp or bind `metadata.fqn` ..." with the bind rule (key MUST equal `metadata.fqn`, a differing key fails with `conflicting values` naming both, the key stays `#ContractFQNType`, `#CatalogMemberFQNGate` still checks fqn against the identity package at publish). The `#transformers` bullets stay.
  - Shape: show `fqn: K` in the three contract-map patterns.
  - Rationale: rework "Why the pattern stamps `modulePath` + `catalogVersion` but not `fqn`" (the transformer stamp still does not; the contract maps bind it to the key, which derives nothing), and add "Why contract keys are bound and transformer keys are not" (owner decision j3 covers attachment maps; all published transformers already match; binding them is a later tightening).
  - §2.1 Rationale "Why `fqn` is authored rather than computed": add one sentence saying that the attachment maps now also refuse a key that disagrees with fqn.

  Then verify that `task spec:check` passes.
- [ ] 2.4 Run `task generate:index` if a doc comment changed. Run `task fmt` and stage the files, then `task check` must pass. Commit `feat(catalog)!: bind contract member keys to the member's fqn`, with a `BREAKING CHANGE:` footer that names the catalog maps.

## 3. Apply the publish gates as non-hidden pins and correct the rule-1 text

This is the wave-1 follow-up folded in by SD14. The posture gate gets its teeth under plain `task vet`.

- [ ] 3.1 Rename the seven gate applications without their `_` prefix, and update every reference: `pinGateTraitPostureRequired` and `pinGateTraitPostureAdvisory` (`src/pins/platform_and_match_pins.cue`), and `pinGateResource`, `pinGateResourceGA`, `pinGateTrait`, `pinGateBlueprint` and `pinGateTransformer` (`src/pins/identity_package_pins.cue`, including the read-backs at :153-188). Then verify that `cue vet ./...` and `cue vet -c ./...` both pass from `src/`.
- [ ] 3.2 Rewrite the pin comments:
  - Replace the "THESE PINS ARE HIDDEN, WHICH COSTS RULE 1 ITS TEETH" paragraph in `platform_and_match_pins.cue` with the non-hidden rule: the gate pins are regular fields, plain `task vet` fails an unstated posture, and `-c` names it.
  - Amend the file headers of `platform_and_match_pins.cue` and `identity_package_pins.cue`, and of `identity_pins.cue` if it states the rule for every pin ("every value here is a HIDDEN top-level field"), to name the gate-pin exception.
  - Re-run the commented `failGateUnstated` case in place under both `cue vet ./...` and `cue vet -c ./...`, and confirm that the recorded block matches the output.
- [ ] 3.3 In the `src/trait.cue` `#TraitOptionalGate` RULE 1 comment (around :150-155), replace "visible only under `cue vet -c` ... a catalog author's plain `task vet` does not" with what is measured: plain `cue vet` exits 1 with the generic "some instances are incomplete" message, and `cue vet -c` names the field. Keep the comment within the doc-comment limit. Check the WHY paragraph "IT MUST BE UNIFIED INTO A NON-HIDDEN VALUE" and keep it if it is still true.
- [ ] 3.4 Update `SPEC.md` §5.1:
  - Shape: the RULE 1 comment no longer says "Visible only under `cue vet -c`".
  - Constraints: "Rule 2 fails under plain `cue vet`; rule 1 does not" becomes "plain `cue vet` exits non-zero on rule 1 without naming the field; `-c` names it, which is why publish runs it".
  - Rationale: "Why the two rules are stated separately" no longer says that plain vet does not report rule 1.

  Grep `SPEC.md` and `docs/` for any other "plain `cue vet`" claim about rule 1 and fix it. Then verify that `task spec:check` passes.
- [ ] 3.5 Run `task generate:index:check`. The renamed pins add no INDEX row, because the generator reads `#` definitions only. Run `task docs:check`. Run `task fmt` and stage the files, then `task check` must pass. Commit `test(pins): apply the publish gates as non-hidden pins and correct the rule-1 vet text`.

## 4. Document appliesTo as unchecked and re-vet the consumers

- [ ] 4.1 In `SPEC.md`, the `appliesTo` text stays as is: unchecked, surfacing at render. Add a pointer to core#99 (open: enforce or drop) in §2.2 Constraints (around :216) and Rationale (:220), §3.1 Constraints (:336) and §3.3 Constraints (:552). Do not change `src/trait.cue`'s `appliesTo!` field.
- [ ] 4.2 In the "What enforces this" outline comments of `docs/site/concepts/platforms-and-catalogs.md` and `docs/site/concepts/components-and-blueprints.md`, add the line "An attachment or contract map key equals the member's fqn: cue (conflicting values)". Add `core/src/resource.cue` to the "Check against" list where it is missing. Verify that `task docs:bundle:check` passes.
- [ ] 4.3 Re-vet the consumers against this branch's build, in scratch copies only (`mktemp -d` under the session scratchpad), and never commit to those repos.
  - Serve the branch's core under a throwaway version that never reaches GHCR. Use `task publish VERSION=...` to `localhost:5000`, or `cue mod registry` in scratch. Route `opmodel.dev/core` to that registry and resolve the rest from GHCR. If the module graph asks for older core versions, copy them in. Any equivalent module override is acceptable.
  - Then bump each scratch consumer's core requirement and vet it:
    - catalog_opm `src/` (`task vet` or `cue vet ./...`);
    - each module in `/var/home/emil/dev/open-platform-model/modules`;
    - each module in `/var/home/emil/dev/open-platform-model/opm-modules` (read only);
    - every CUE module under the test data and fixture directories of library, cli and opm-operator (find each `cue.mod/`);
    - `opm-operator/modules/opm_operator`.

  For each consumer, record the path, the core version vetted against, the command and the result.
- [ ] 4.4 Classify every failure by cause. For a key-to-fqn conflict, check whether the member belongs to a PUBLISHED catalog release, that is, under `opmodel.dev/catalogs/*` on GHCR.
  - **OWNER STOP (0021:D7:R5):** a published mis-keyed member does not get fixed here. Finish this section, record its exact path and release, and report it FIRST. The merge waits for the owner's sign-off.
  - An unpublished mis-key in a fixture or a module is listed for a follow-up in its own repo. It is not fixed here.
  - A failure with another cause, such as a registry fetch or a pre-existing break, is recorded as unrelated, and the same vet is re-run against `origin/main`'s core to confirm it.
- [ ] 4.5 Write the results into `design.md` § Re-vet against this build.
- [ ] 4.6 `task check` must pass. Commit `docs: point appliesTo at core#99 and record the consumer re-vet`. This section stages no `*.cue` file, so the SPEC.md co-update hook does not fire.
