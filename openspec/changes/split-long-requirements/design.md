## Context

The approved guide (`design/T2.1.md` of the swarm folder, section numbers below) governs every rewrite. This design says how core applies it. Base: `origin/main` at `a015044e`. Measured on that base with OpenSpec 1.14.1: `openspec validate --all --strict` prints 35 WARNING lines. 34 are long requirements in 14 specs (lengths 503 to 2993) and 1 is the placeholder Purpose of `cite-lint`. There is no ERROR and no open change.

Reversibility: high (hours). The change edits spec text and one gate; reverting the PR restores both. No contract, schema, or public interface changes. No trust boundary is added.

## Research & Decisions

### Forms and how core chooses

**Context**: The guide allows four safe forms (a, b, c2, d). OpenSpec checks scenario names only for MODIFIED, not for REMOVED plus ADDED, so the choice decides how much a reviewer must prove by hand.
**Explored**: Guide sections 2 and 3; the inventory of the 34 requirements (lengths, live scenario counts, kind of excess).
**Decision**: Choose per requirement by this table, after reading its text. The inventory kind labels are a heuristic only.

| The excess is | Form |
| --- | --- |
| Rationale, examples, lists or formats around one behavior | a: MODIFIED, shorter body, every live scenario kept verbatim, moved detail in new scenarios |
| Several behaviors, and the live scenarios fit the parent that stays | b: MODIFIED parent plus ADDED requirements under new names, with new scenarios |
| Several behaviors, and the live scenarios belong to different behaviors | c2: REMOVED plus ADDED under new names; the ledger is mandatory |
| A name that must change with no change of rule | d: RENAMED plus MODIFIED under the new name, alone |

**Rationale**: Form a and b keep every old scenario in MODIFIED, where OpenSpec itself rejects a dropped or renamed scenario. c2 is the only form that can lose a scenario silently, so it is the fallback when scenarios cannot stay with the parent. The 13 requirements with 2 or 3 scenarios mostly hold two or three behaviors and fit b or c2; the 6 requirements at 500 to 540 characters (`artifact-identity`, `definitions-reference`, `name-constraints`, `schema-release` "internally coherent", `transformer-context`) are the likeliest form a.

The loopholes of guide section 2 are forbidden: no `**Key**:` line, no heading of level 5 or deeper, no fenced block in a requirement body. `**Reason**:` and `**Migration**:` in REMOVED are the only exceptions.

### Core's own scenario and citation rules

**Context**: `openspec/config.yaml` rules for specs bind every new ADDED requirement.
**Decision**: Each new requirement body keeps SHALL or MUST and states one behavior. Each has scenarios in both directions (a value accepted and a value rejected) where the behavior has a rejection; a scenario added for that reason uses only words and values of the old body and is flagged `new:` for the human. An enhancement id stays beside its reason in words, in the body of the block that carries the rule, never alone, never with a decision number, never in a header. No section, slice or task id is cited. Prose is not hard-wrapped.
**Rationale**: These are the repo's rules; the guide (section 4) names the core one explicitly.

### Batch order

**Context**: One batch of 34 requirements over 14 specs, larger than the guide's 28-requirement cap, because core-B2 (6) is too small to stand alone (guide section 8). The warning count falls by the number of requirements rewritten so far.
**Decision**: Rewrite specs in this order, each spec whole, each ending with its own gate run:
1. The six single-requirement specs of core-B2 and `artifact-identity` (7 requirements). They are the likeliest form a, they prove the flow, and they touch the fewest cross references.
2. `schema-pins` (2), `primitive-keying` (3), `catalog-contracts` (3): the identity and keying group.
3. `contract-fulfilment` (4) and `platform-contract-inventory` (7): the largest in total length, and `contract-fulfilment` is cited by `SPEC.md` and `src/*.cue` prose (grep before every rename).
4. `release-cascade` (3) and `schema-release` (5): the longest bodies (up to 2993), likeliest c2, with the most scenarios per requirement (up to 9).
**Rationale**: Small and simple first lowers the chance of a form error repeating 34 times. The units commit per spec, so a stop at any point leaves a green tree.

### The gate of guide section 6 with core's paths

**Context**: `validate <change> --strict` alone skips long MODIFIED text, so it does not prove the result.
**Decision**: Run the gate block of guide section 6 in a scratch copy of `openspec/` outside the worktree, with `WT` set to the worktree, `CH=split-long-requirements`, and `N` the requirements rewritten so far across all units. Set `LAST=1` only for the final group. Core has no open change of another author, so at `LAST=1` `validate --all --strict` is expected to exit 0 as well. Per spec, also run `openspec validate <spec> --type spec --strict --json 2>&1` and read it. Before each rename, split or c2, run `grep -rn --exclude-dir=archive "<old header>" .` from the worktree root.
**Rationale**: The scratch copy keeps `archive` runs out of the worktree.

### Scenario ledger

**Context**: Guide section 4 requires a table per rewritten requirement.
**Decision**: Each apply unit appends its tables below, before it writes the delta of that spec. Table one: old scenario name, new place (requirement, scenario name), changed text (must be "no" for a moved scenario). Table two (only when a clause leaves the body): old clause, new place. Checklist item 3 of the guide (the byte-equal command) is run per rewritten requirement and its output is kept in the unit report.
The live scenario counts at the base, per requirement, seed the ledger (the names are copied from `main` when a unit starts):

| Spec | Requirement | Length | Live scenarios |
| --- | --- | --- | --- |
| artifact-identity | An artifact declares its complete CUE module path | 539 | 4 |
| catalog-contracts | The catalog stamps provenance onto every listed member | 767 | 3 |
| catalog-contracts | A catalog derives the provider-fulfilled contracts it implements | 1259 | 8 |
| catalog-contracts | A contract member's key equals its fqn | 820 | 4 |
| contract-fulfilment | A provider-fulfilled contract admits exactly one provider | 1264 | 5 |
| contract-fulfilment | Every declared resource is a required demand | 593 | 2 |
| contract-fulfilment | A trait states its own optionality, and the attachment may override it | 721 | 3 |
| contract-fulfilment | A render's caller may skip unprovided provider-fulfilled demands | 1604 | 7 |
| definitions-reference | The definitions reference is generated into the docs bundle | 503 | 2 |
| docs-bundle | core publishes one docs bundle | 589 | 2 |
| instance-identity | An instance FQN cannot be built from a module path | 581 | 1 |
| name-constraints | The component asserts the resolved name against every attached constraint | 520 | 6 |
| platform-contract-inventory | A platform derives its contract inventory from its enabled entries | 628 | 2 |
| platform-contract-inventory | A transformer's match predicate is every required demand it declares | 608 | 2 |
| platform-contract-inventory | Comparable predicates over a shared catalog-fulfilled contract are reported | 645 | 5 |
| platform-contract-inventory | The inventory reports and never refuses | 732 | 3 |
| platform-contract-inventory | The inventory names the registry entries providing each contract | 1566 | 6 |
| platform-contract-inventory | Over-subscription counts providing registry entries, not transformers | 847 | 4 |
| platform-contract-inventory | Contract keys defined by more than one enabled entry are reported as collisions | 1543 | 6 |
| platform-registry | A platform carries no reverse index | 559 | 2 |
| primitive-keying | A catalog member's FQN is authored, not derived | 905 | 3 |
| primitive-keying | FQN map keys are typed by the role they hold | 1473 | 3 |
| primitive-keying | An attachment map key equals its member's fqn | 870 | 5 |
| release-cascade | A published core release notifies its cascade downstreams | 1292 | 5 |
| release-cascade | The notification runs with the cascade App only, and can be switched off | 1227 | 4 |
| release-cascade | The cascade reference is pinned to one `.github` `main` SHA and checked on every PR | 2993 | 9 |
| schema-pins | Schema pins live in a package no consumer loads | 771 | 3 |
| schema-pins | Publish-gate pins are applied non-hidden | 878 | 4 |
| schema-release | The schema is published only by CI, from a reviewed release | 853 | 2 |
| schema-release | A break on a prerelease line advances the prerelease, and only a stable line crosses a major | 2239 | 8 |
| schema-release | The published schema is internally coherent before it is tagged | 510 | 2 |
| schema-release | A line changes prerelease type through a forced carrier commit and goes stable through a visible one | 1121 | 3 |
| schema-release | A release publishes only a version the registry does not hold | 1254 | 4 |
| transformer-context | The context's metadata blocks are projections of the other two inputs | 531 | 2 |

Lengths and counts were measured on `a015044e` with the validator's rule (guide section 2). The sum is 34 rows, equal to the inventory of the exploration report (28 in core-B1, 6 in core-B2).

### The Purpose of `cite-lint`

**Decision**: Replace the placeholder sentence under `## Purpose` in `openspec/specs/cite-lint/spec.md` by text that says what the capability is for, taken from its three requirements: the local `cite-lint` task, the shared CI workflow call, and the wiring check that declares the call. The edit is direct, in the main spec, in its own commit. The three requirements are under 500 characters and stay as they are.
**Rationale**: A Purpose in a delta is read only when a capability is created, so a delta cannot replace this one (the validator message says so).

### The pinned validation gate

**Context**: Core has no OpenSpec task and no OpenSpec CI step. The `ci` job `Validate schema` is the required check, and `.tasks/cascade/wiring-check.sh` guards its shape: it refuses a `run:` step before the wiring step, and a reviewer reads every change to that job as a change to the check.
**Options**: (1) A new separate CI job. It is not a required check, so a red run would not block a merge. (2) A step in `Validate schema`, after the wiring step, calling a Taskfile task. (3) A raw `openspec` call in the workflow with no task. (4) Status quo, no gate.
**Decision**: Option 2.
- `Taskfile.yml` gets `openspec:install` (installs the version of one variable, `OPENSPEC_VERSION: 1.14.1`, with `npm install -g --ignore-scripts @fission-ai/openspec@{{.OPENSPEC_VERSION}}`) and `openspec:check` (precondition: `openspec` found and `openspec --version` equals the pin; command: `openspec validate --all --strict --no-interactive`). `check` calls `openspec:check` last.
- `ci.yml` job `ci` gets, after the wiring step, a `setup-node` step pinned by full commit SHA with a version comment, `task openspec:install`, and `task openspec:check`. The pin lives once, in the Taskfile.
- `OPENSPEC_TELEMETRY=0` is set for the task.
- The step does not use the `LAST=1` rule: it runs `validate --all --strict`, like cli.
**Rationale**: The required job blocks a merge; one pin location cannot drift between local and CI; a task keeps the CI step and `task check` the same command. The installed package 1.14.1 declares no install, postinstall or prepare script (read in its `package.json`), so `--ignore-scripts` costs nothing and removes a code-execution path.
**Trade-offs**: CI needs Node and an npm download on every run, and an npm outage fails the required check. Revisit when a checksum-verified binary exists, or when the pin moves.
**Consequence**: A pin bump is a one-line Taskfile edit plus a skill regeneration. `task check` now needs Node and network on a fresh machine; the precondition message says how to install.

### Repo note: `task check` in a worktree

`.tasks/generate-index.sh:44` titles `src/INDEX.md` from the folder name, so `task check` fails in a worktree whose folder is not named `core`. Apply units run `task check` in a scratch copy of the worktree named `core`, and report the directory.

## Security

Assets: the CI job token and the published schema. Trust boundary: the npm registry, which supplies the OpenSpec CLI to a job that holds `contents: read` only. Threat: a malicious or replaced package version. Mitigations: an exact version, no install scripts run, no secret in the job, and the job token read-only. Baseline: the repo's workflow rules (pinned actions by SHA, least permission). Residual risk: a compromised 1.14.1 tarball would run in a read-only job; the owner is the core maintainer, and a checksum-verified install is the revisit trigger. The release age of 1.14.1 against the cooldown rule of the supply-chain guide is not verified here (no network in this step); the apply unit that adds the install records it.

## Risks

- Scenario loss in form c2 passes the gate silently. Mitigation: the ledger and the byte-equal command per requirement.
- A new ADDED scenario can add a rule. Mitigation: it uses only words and values of the old body, and is flagged for the human.
- The wiring check refuses a workflow shape. Mitigation: the CI step goes after the wiring step; the unit runs `task cascade:wiring:check`.
- Prose elsewhere (`SPEC.md`, `docs/site`) cites a requirement phrase. Mitigation: grep before each rename; `SPEC.md` text is not edited here.

## Scenario ledger tables

Each table lists every live scenario of a rewritten requirement on `main`. Lengths are of the body by the validator's rule. `new:` scenarios are listed after the tables and use only words and values of the old body.

### artifact-identity: An artifact declares its complete CUE module path (539 to 471, form a)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| A module path with a major suffix is accepted | same requirement, same name | no |
| A module path without a major suffix is refused | same requirement, same name | no |
| Underscores are legal in a module path leaf | same requirement, same name | no |
| Hyphens remain legal in non-leaf segments | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| `modulePath` typed `#ModulePathType`, terminal `@vN` required | body, sentence 1, unchanged |
| value is the string of `module:`, registry coordinate and `import` | body, sentence 2, same three carriers |
| `#ModulePathType` admits underscores (leaf is snake_case) | body, sentence 3, with the reason in parentheses |
| `#ModulePathType` admits hyphens in non-leaf segments (organisation stays expressible) | body, sentence 3, with the reason in parentheses |

### definitions-reference: The definitions reference is generated into the docs bundle (503 to 465, form a)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| A new definition is placed | same requirement, same name | no |
| A new definition is left out | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| files matching `*_pins.cue` skipped | new scenario "Pins files are skipped" |
| every other clause | body, unchanged |

### docs-bundle: core publishes one docs bundle (589 to 465, form b)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| The bundle holds both kinds of page | same requirement, same name | no |
| A committed generated page that is not excluded collides | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| `task docs:bundle` SHALL build it into `out/core/` | ADDED "The bundle tasks build and check without publishing", body and new scenario "The build task writes the bundle to out/core" |
| `task docs:bundle:check` SHALL build and lint it without publishing | same ADDED requirement, body and new scenario "The check task publishes nothing" |
| project, placement, ownership, versioning, sources, authored plus generated together, citation | body of the parent, unchanged |

### instance-identity: An instance FQN cannot be built from a module path (581 to 441, form a)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| A module path in the registry-path position is refused | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| `#PackagePathType` is a backstop that cannot fire on its own: `strings.SplitN(modulePath, "@", 2)[0]` carries no `@` under `#ModulePathType` | new scenario "The package path backstop cannot fire on its own"; the body keeps "The `#PackagePathType` backstop is also structural; only the reported error differs" |
| registryPath derived from `#ArtifactRef`, refusal is a conflict against the computed value | body, unchanged in meaning |

### name-constraints: The component asserts the resolved name against every attached constraint (520 to 485, form a)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| Default name admitted by a constraint | same requirement, same name | no |
| Override refused by a constraint | same requirement, same name | no |
| Default refused by a constraint | same requirement, same name | no |
| Overlong default refused by a length-bearing constraint | same requirement, same name | no |
| Two constraints compose | same requirement, same name | no |
| Override that satisfies the constraint is admitted | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| collect every attached `#nameConstraint` into one conjunction, unconditionally | body, "conjoin ... unconditionally" |
| assert the resolved `metadata.resourceName` (default or override, as a string) against the conjunction on a hidden field | body, "against it on a hidden field" |
| conjunction not unified into `metadata.resourceName`, so default, override and refusal behaviour (component-names) is unchanged | body, "The conjunction SHALL NOT be unified ..." |
| two constraints compose by unification with no precedence rule | body, unchanged |

### platform-registry: A platform carries no reverse index (559 to 356 and 202, form c2)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| A declared reverse index is refused | A platform declares no reverse index, same name | no |
| The readiness index is not a matcher bucket | The readiness index is not a matcher bucket, same name | no |

| Old clause | New place |
| --- | --- |
| `#Platform` MUST NOT declare `#matchers` | A platform declares no reverse index, body |
| a declaring value is inert; nothing reads it (closedness does not refuse, measured 2026-09-13 on cue v0.17.1) | same, body |
| consumers MUST derive the index from `#composedTransformers` | same, body |
| `#contracts.requiredBy` is a derived readiness index, not a matcher bucket; glue MUST NOT read it; carries no primitive values | The readiness index is not a matcher bucket, body |

### transformer-context: The context's metadata blocks are projections of the other two inputs (531 to 453, form a)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| The context computes from filled inputs | same requirement, same name | no |
| Transformer-visible values are unchanged | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| `#moduleInstanceMetadata` and `#componentMetadata` computed from the inputs; runtime not required to supply either | body, unchanged |
| field names and value shapes unchanged from the pre-projection context | body, unchanged |
| so a transformer reading any context field observes the same value as before | body, restored ("Field names and value shapes are unchanged, so a transformer reading any context field observes the same value as before"); scenario "Transformer-visible values are unchanged" shows two fields |

### schema-pins: Schema pins live in a package no consumer loads (771 to 487, form b)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| Building core as the main instance does not evaluate the pins | same requirement, same name | no |
| A broken pin is invisible to a consumer's build of core | same requirement, same name | no |
| Package core declares no top-level hidden field | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| every pin declared in package `pins` in `src/pins/`, in `*_pins.cue` | parent body, unchanged |
| package `core` declares no pin and does not import `pins` | parent body, one sentence |
| a build of core does not load, parse or evaluate a pin | parent body, unchanged |
| Source: owner decision, 2026-10-03 | parent body |
| a pin is a hidden field, except an applied publish-gate pin | ADDED "A pin is a hidden field", new scenario "A pin outside the publish gates is hidden" |
| package `pins` imports core and references core only through that import | ADDED "Package pins reaches core only through its import", new scenario "Package pins reaches core through its import" |

### schema-pins: Publish-gate pins are applied non-hidden (878 to 478, form b)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| A posture-gate pin with an unstated posture fails plain vet | same requirement, same name | no |
| The conformant gate pins pass both vets | same requirement, same name | no |
| A hidden gate application checks nothing | same requirement, same name | no |
| spec:check refuses a hidden applied gate pin | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| an applied gate pin is a regular field (SPEC §5.1) | parent body, unchanged |
| the commented incompleteness case `failGateUnstated` is non-hidden, a hidden field is never checked for completeness | parent body, unchanged |
| Source: follow-up (2026-10-03) | parent body |
| a commented MUST-FAIL gate case MAY keep the hidden shape (conflict reported in hidden field; error measured in that shape) | ADDED "A commented MUST-FAIL gate case may keep the hidden shape", new scenario "A hidden commented gate case reports its conflict" |
| `cue vet` checks a regular field for completeness, so plain `task vet` MUST fail on an incomplete pin | ADDED "Plain vet fails an incomplete regular gate pin", new scenario "Plain task vet fails an incomplete regular gate pin" |
| a regular gate field MUST NOT reach a consumer nor add a `src/INDEX.md` row | ADDED "A regular gate pin reaches no consumer", new scenario "A regular gate pin adds no index row and no consumer value" |

The header of this requirement stays: `.tasks/spec-check.sh` prints it.

### primitive-keying: A catalog member's FQN is authored, not derived (905 to 481 and 472, form c2)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| An authored FQN is accepted as written | A catalog member's FQN is authored by the catalog, same name | no |
| An FQN disagreeing with the primitive's own fields is not refused by `core` | A catalog member's FQN is authored by the catalog, same name | no |
| An unset FQN takes its attachment key | An unset FQN in an attachment map takes its key, same name | no |

| Old clause | New place |
| --- | --- |
| `core` does not derive `metadata.fqn`; the catalog authors it from its identity package; nothing computed from `name`, `modulePath`, `apiVersion` | A catalog member's FQN is authored by the catalog, body |
| outside the attachment maps, agreement is not checked by `core`; `#CatalogMemberFQNGate` checks at publish | same, body |
| inside the six attachment maps the key binds `metadata.fqn`; a disagreeing authored value is refused with `conflicting values`; an unset `fqn` takes the key | An unset FQN in an attachment map takes its key, body; the refusal also gets the new scenario "A disagreeing authored FQN in an attachment map is refused" |
| the binding derives nothing from the member's fields; key and fqn both authored | same, body ("MUST NOT derive") |

### primitive-keying: FQN map keys are typed by the role they hold (1473 to 454, form b)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| A build-shaped key is refused in a demand map | same requirement, same name | no |
| A contract-shaped key is refused in a transformer map | same requirement, same name | no |
| A build-shaped key is refused in a catalog contract map | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| no map takes `#FQNType`; contract maps keyed `#ContractFQNType`; implementation maps keyed `#ImplFQNType` (with the map lists) | parent body, unchanged |
| a wrong-form key MUST be refused rather than merely failing to match | parent body; the reason (an unmatched key surfaces as a transformer that renders nothing) moves to new scenario "A wrong-form key is an error, not a silent non-match" |
| `core` binds key to `metadata.fqn` in exactly the six attachment maps (with the two cited requirements) | ADDED "The six attachment maps bind a key to its member's fqn", new scenario "A component attachment map refuses a key that is not the member fqn"; the citation of the catalog requirement uses the new name "A contract map binds each member's fqn to its key" (see catalog-contracts below) |
| demand and implementation maps enforce form only; demand-map key equals fqn is a runtime invariant | ADDED "Demand maps and implementation maps enforce the key form only", new scenario "A demand map key is checked for form only" |
| a transformer map key is checked for form only (gate never reads a `#Catalog` map key); binding `#Catalog.#transformers` is a possible later tightening | ADDED "A transformer map key is checked for form only", new scenario "A transformer map key is not compared with the transformer fqn" |

The ADDED bodies of the last three rows use MUST where the old text stated a fact in the present tense, because an ADDED body needs SHALL or MUST.

### primitive-keying: An attachment map key equals its member's fqn (870 to 484, form b)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| A resource keyed by its fqn is accepted | same requirement, same name | no |
| A short resource key is refused | same requirement, same name | no |
| A trait under another trait's key is refused | same requirement, same name | no |
| A blueprint under another blueprint's key is refused | same requirement, same name | no |
| Entries contributed by an embedded blueprint fragment are accepted | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| the three maps bind every entry's fqn to its key | body, unchanged |
| a differing entry fails `cue vet` with `conflicting values` at `<map>.<key>.metadata.fqn`, naming both | body, unchanged |
| an entry keyed by its own fqn MUST validate as before, by hand or from a catalog wrapper or embedded blueprint | body keeps the rule; the two ways are in scenarios "A resource keyed by its fqn is accepted" and "Entries contributed by an embedded blueprint fragment are accepted" |
| a short key such as `container` MUST be refused | scenario "A short resource key is refused" |
| the binding MUST NOT derive `fqn` from `name`, `modulePath` or `apiVersion` | "An unset FQN in an attachment map takes its key", body (it covers these maps) |
| `#Trait.appliesTo` stays unchecked against the component's resources; core#99 | ADDED "`#Trait.appliesTo` is not checked against the component's resources", new scenario "appliesTo is not checked against the attached resources" |
| Source: owner decision, beta.1 kernel plan walkthrough | body |

### catalog-contracts: The catalog stamps provenance onto every listed member (767 to 492, form b)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| A member authored without provenance receives both stamps | same requirement, same name | no |
| A member filed under a different version segment is refused | same requirement, same name | no |
| A member naming another build is refused | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| stamp `catalogVersion` and `modulePath` (major-free registry path, kind segment, `apiVersion`); omit or agree; divergence fails with `conflicting values` | parent body |
| the kind segments `resources`, `traits`, `blueprints`; the version-segment filing; enhancement 0010 citation | ADDED "A stamped module path files a contract member under its version segment", body keeps the citation, new scenarios "The kind segment names the map" and "The stamped path ends in the member apiVersion" |

### catalog-contracts: A catalog derives the provider-fulfilled contracts it implements (1259 to 434, 80, 178, 258 and 358, form c2)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| Defining a provider contract is not providing it | A catalog derives the provider-fulfilled contracts its transformers require, same name | no |
| Two adapters requiring one provider contract derive it once | The provides field is sorted ascending and holds no duplicates, same name | no |
| A transformer requiring a provider-fulfilled resource contributes it | The provides field is sorted ascending and holds no duplicates, same name | no |
| A catalog-fulfilled required trait does not provide | Optional demands and catalog-fulfilled contracts do not provide, same name | no |
| An optional resource demand does not provide | Optional demands and catalog-fulfilled contracts do not provide, same name | no |
| An optional demand does not provide | Optional demands and catalog-fulfilled contracts do not provide, same name | no |
| A catalog with no transformers provides nothing | Optional demands and catalog-fulfilled contracts do not provide, same name | no |
| An authored value that disagrees is refused | The provides field is derived and never authored, same name | no |

| Old clause | New place |
| --- | --- |
| derive regular field `provides: [...#ContractFQNType]` of every contract named by an own transformer in `requiredResources` or `requiredTraits` with `fulfilment` `"provider"` | A catalog derives the provider-fulfilled contracts its transformers require, body |
| Source: library ADR-012; claim check of enhancement 0015 | same, body |
| sorted ascending, without duplicates | The provides field is sorted ascending and holds no duplicates, body |
| fulfilment read from the transformer's own requirement value, never from the catalog maps; a contract another catalog defines still counts | Fulfilment is read from the transformer's own requirement, body; new scenario "A contract another catalog defines still counts" |
| optional demands, required labels and `"catalog"` requirements MUST NOT contribute; none gives `[]` | Optional demands and catalog-fulfilled contracts do not provide, body |
| derived, never authored; disagreement fails on `provides` with the two CUE errors | The provides field is derived and never authored, body |
| a catalog that authors no `provides` MUST validate unchanged | same, body; new scenario "A catalog that authors no provides validates unchanged" |

### catalog-contracts: A contract member's key equals its fqn (820 to 400, 239 and 252, form c2)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| A member listed under its own fqn is accepted | A contract map binds each member's fqn to its key, same name | no |
| A member listed under another contract's key is refused | A contract map binds each member's fqn to its key, same name | no |
| A mis-keyed resource or blueprint member is refused the same way | A contract map binds each member's fqn to its key, same name | no |
| The transformer map is not bound | The transformer map is not bound to the transformer fqn, same name | no |

| Old clause | New place |
| --- | --- |
| the three contract maps bind every member's fqn to its key; a differing authored fqn fails with `conflicting values` naming both; the key stays `#ContractFQNType` | A contract map binds each member's fqn to its key, body |
| the binding derives no `fqn`; key and fqn both authored; `#CatalogMemberFQNGate` checks at publish | The contract map binding derives no fqn, body; new scenario "The binding derives nothing from the member fields" |
| `#Catalog.#transformers` is not bound by this requirement; Source: owner decision | The transformer map is not bound to the transformer fqn, body |

No other file in this repo cites the three old catalog-contracts headers or the old primitive-keying FQN header (`grep -rn --exclude-dir=archive`); the one citation inside `primitive-keying` is rewritten above.

### contract-fulfilment: A provider-fulfilled contract admits exactly one provider (1264 to 415, form b)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| Two providers for one contract are refused | same requirement, same name | no |
| One provider is accepted | same requirement, same name | no |
| Optional demands do not count as provision | same requirement, same name | no |
| Two majors of one provider catalog are two providers | same requirement, same name | no |
| Providers count when the defining catalog is not enabled | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| exactly one provider; a provider is an enabled registry entry whose transformers require the contract | parent body, unchanged |
| two providers MUST be refused naming both registry keys and the contract key; two remain refused under the skip request; the rule is enforced outside the schema | parent body ("This rule is enforced outside the schema") |
| the count is of registry entries keyed by registry key; two transformers of one entry are one provider; two enabled majors are two; a provider counts whether or not an entry defines the contract | ADDED "The provider count is of registry entries", new scenario "Two transformers of one entry are one provider" (the live scenarios "Two majors ..." and "Providers count ..." stay in the parent) |
| zero providers is an unresolved demand that fails the render unless the caller asked to skip | ADDED "Zero providers are an unresolved demand", new scenario "A contract with no provider fails the render" |
| `core` declares the intent and computes the count once as the inventory, which reports without refusing; stated here because it is what `fulfilment: "provider"` means | ADDED "The contract inventory computes the provider count once", new scenario "The inventory reports the count without refusing" |
| the render build and the generation step refuse on that one count (the inventory's provider count); none keeps its own | ADDED "The render build and the generation step refuse on the one count", new scenario "Consumers refuse on the inventory count" |

### contract-fulfilment: Every declared resource is a required demand (593 to 484, form b)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| An unsupplied resource fails the render | same requirement, same name | no |
| A component with a partially satisfied set does not render | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| every declared resource is a demand; an unsupplied FQN fails the render immediately, except a skipped unprovided provider-fulfilled resource | parent body, unchanged (the citation uses the new name of the skip requirement) |
| a partly satisfied component renders no output for the satisfied part, under the skip request or without it | parent body keeps the rule; "under the skip request or without it" is the two outcomes of the scenario "A component with a partially satisfied set does not render" |
| a resource has no demand-side optionality marker | ADDED "A resource has no demand-side optionality marker", new scenario "A resource carries no optionality marker on the demand side" |

### contract-fulfilment: A trait states its own optionality, and the attachment may override it (721 to 401, form b)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| An unhandled load-bearing trait fails | same requirement, same name | no |
| An unhandled advisory trait warns | same requirement, same name | no |
| A module overrules the catalog in either direction | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| `#Trait` carries `optional: bool`, no `core` default, the catalog states a default | ADDED "A trait carries a posture its catalog states as a default", body, new scenario "Core gives optional no default" |
| `#Component` carries no optionality field | same ADDED, body, new scenario "A component carries no optionality field" |
| a component overrides the posture at the attachment, either direction, without conflict | parent body |
| an unhandled `optional: false` trait fails the render, except a skipped unprovided provider-fulfilled one | parent body (the citation uses the new name of the skip requirement) |

### contract-fulfilment: A render's caller may skip unprovided provider-fulfilled demands (1604 to 413, 368, 118, 187, 381 and 167, form c2)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| Without the request the render still refuses | A skipped resource demand omits the whole component, same name (placed after "A skipped resource omits the whole component", whose component it refers to) | no |
| A provider on the platform is used, not skipped | A render's caller may ask to skip unprovided demands, same name | no |
| A catalog-fulfilled demand still refuses under the request | Only unprovided demands are skippable, same name | no |
| A present provider that did not match still refuses | Only unprovided demands are skippable, same name | no |
| An over-subscribed contract still refuses under the request | Only unprovided demands are skippable, same name | no |
| A skipped trait lets the rest of the component render | A skipped trait demand leaves the rest of its component rendering, same name | no |
| A skipped resource omits the whole component | A skipped resource demand omits the whole component, same name | no |

| Old clause | New place |
| --- | --- |
| the caller MAY ask to skip every unprovided demand (definition); per render, the caller's; without it every render behaves as the other requirements state | A render's caller may ask to skip unprovided demands, body ("MUST be per render", "MUST behave", because an ADDED body needs a keyword) |
| only unprovided demands are skippable; three cases stay refused | Only unprovided demands are skippable, body, unchanged |
| a skipped trait demand leaves the component rendering every pair it matched; the trait renders nothing | A skipped trait demand leaves the rest of its component rendering, body |
| a skipped resource demand leaves the component rendering nothing; a partly satisfied component never renders; not reported as unmatched | A skipped resource demand omits the whole component, body |
| every skipped demand reported (component, contract key, kind; resource report says the whole component rendered nothing); never silent; an optional trait is unaffected | Every skipped demand is reported, body; new scenario "An advisory trait warns with or without the request" |
| enforcement is the kernel's; `core` states the rule; the inventory is unchanged | The kernel enforces the skip rule and the inventory is unchanged, body ("MUST"); new scenario "The inventory does not change under the request" |

The citations of the old name in the three MODIFIED bodies above use the new name "A render's caller may ask to skip unprovided demands". No other file cites the old name as a requirement name (the phrase in `SPEC.md` is prose).

### platform-contract-inventory: A platform derives its contract inventory from its enabled entries (628 to 458, form b)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| Listed members of an enabled catalog are defined | same requirement, same name | no |
| A disabled entry defines nothing | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| derive `#contracts`; `defined`; `definedBy`; a disabled entry contributes nothing | parent body, unchanged |
| a FQN more than one enabled entry lists is in neither map and is reported as a collision | ADDED "A contract FQN listed by more than one enabled entry is in neither map", new scenario "A shared contract FQN is not defined" |
| the inventory is not authorable and no runtime fills it | ADDED "The inventory is derived and never authored", new scenario "The inventory is not authorable" |

### platform-contract-inventory: A transformer's match predicate is every required demand it declares (608 to 351, form b)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| A required trait is part of the predicate, not only labels | same requirement, same name | no |
| An optional demand does not widen the predicate | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| the predicate is the union of required resources, required traits and required label pairs | parent body, unchanged |
| optional demands do not contribute (enhancement 0010 citation) | parent body, unchanged |
| a required label contributes its key and value together | ADDED "A required label contributes its key and value together", new scenario "Different values of one label key are different demands" |
| a transformer declaring no map of a kind demands nothing of that kind | ADDED "A missing demand map is no demand", new scenario "A transformer without a demand map demands nothing of that kind" |

### platform-contract-inventory: Comparable predicates over a shared catalog-fulfilled contract are reported (645 to 396, form b)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| Two catalogs shipping the same adapter are comparable | same requirement, same name | no |
| A strictly narrower predicate is comparable | same requirement, same name | no |
| Differing required label values are not comparable | same requirement, same name | no |
| A distinct required trait is not comparable | same requirement, same name | no |
| A disabled entry's transformer is never paired | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| `comparable` lists every unordered pair with a subset predicate and a shared catalog-fulfilled contract | parent body, unchanged |
| equal predicates give one row; incomparable pairs do not appear | parent body, unchanged |
| a row names both FQNs, distinguishes smaller from larger predicate, names the shared contracts | ADDED "A comparable row names both transformers and the shared contracts", new scenario "A comparable row names its parts" |

### platform-contract-inventory: The inventory reports and never refuses (732 to 375, form b)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| An over-subscribed platform still evaluates | same requirement, same name | no |
| A platform with comparable predicates still evaluates | same requirement, same name | no |
| Two majors with shared keys still evaluate | same requirement, same name | no |

| Old clause | New place |
| --- | --- |
| neither report makes the platform fail to evaluate; offenders are named in the lists (enhancement 0015 citation) | parent body, unchanged |
| a platform whose entries list one contract key evaluates, key in `collisions` | ADDED "A shared contract key is a collision, not a conflict", new scenario "Entries listing one key evaluate with a collision" |
| the generation step decides whether `routable: false` or `discriminated: false` withholds a package; `fulfilled: false` gates nothing | ADDED "The generation step decides whether a report withholds a package", new scenario "An unfulfilled platform gates nothing" |

### platform-contract-inventory: The inventory names the registry entries providing each contract (1566 to 492, 227, 304, 413 and 217, form c2)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| One provider entry through two adapters is one key | A providedBy list holds each registry key once, ascending, same name | no |
| Two majors of one catalog are two keys | providedBy maps a provider-fulfilled contract to its providing registry keys, same name | no |
| Providers of a contract no enabled entry defines are listed | providedBy is derived from the transformers alone, same name | no |
| A contract nobody provides has no key | A providedBy key is present exactly when an enabled entry provides the contract, same name | no |
| A disabled entry provides nothing | A providedBy key is present exactly when an enabled entry provides the contract, same name | no |
| A provider-fulfilled resource requirement folds through the catalog's provides | providedBy equals the fold of the catalogs' provides, same name | no |

| Old clause | New place |
| --- | --- |
| `providedBy` maps each provider-required contract FQN to the registry keys of the providing enabled entries | providedBy maps a provider-fulfilled contract to its providing registry keys, body |
| Source: enhancement 0015 (exposing the paths a refusal names) | same, body |
| ascending-sorted registry keys (`path@vN`); each key at most once per contract | A providedBy list holds each registry key once, ascending, body |
| derived per registry entry over every enabled entry's transformers; independent of who defines the contract; fulfilment read from the transformer's own requirement | providedBy is derived from the transformers alone, body |
| equals the fold of `#catalog.provides`; a transformer on the entry's own readout is outside the fold (core#119); Source: library ADR-012 | providedBy equals the fold of the catalogs' provides, body |
| a key is present exactly when an enabled entry provides; optional demands, required labels, catalog-fulfilled requirements, blueprints and disabled entries do not contribute | A providedBy key is present exactly when an enabled entry provides the contract, body |

### platform-contract-inventory: Over-subscription counts providing registry entries, not transformers (847 to 405, 345 and 100, form c2)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| Two catalogs providing one contract is over-subscription | Over-subscription lists the contracts with more than one providing entry, same name | no |
| Two providers of an undefined contract are over-subscription | Over-subscription lists the contracts with more than one providing entry, same name | no |
| One catalog providing through two transformers is one provider | Over-subscription counts registry keys, not transformers, same name | no |
| Two majors of one provider catalog are over-subscription | Over-subscription counts registry keys, not transformers, same name | no |

| Old clause | New place |
| --- | --- |
| `overSubscribed` lists every `providedBy` key with more than one registry key, including a contract no entry defines; Source: enhancement 0015, two titles | Over-subscription lists the contracts with more than one providing entry, body |
| the counting key is the registry key; two majors count as two, two transformers of one entry as one; Source: enhancement 0010 is the rule counted | Over-subscription counts registry keys, not transformers, body |
| `routable` is true exactly when `overSubscribed` and `collisions` are empty | A platform is routable when nothing is over-subscribed or colliding, body; new scenarios "Routable is true with no over-subscription and no collision" and "Routable is false with an over-subscription or a collision" |

### platform-contract-inventory: Contract keys defined by more than one enabled entry are reported as collisions (1543 to 428, 345, 141, 133, 183 and 308, form c2)

| Old scenario name | New place (requirement, scenario name) | Changed text? |
| --- | --- | --- |
| Two majors sharing keys report every shared key as a collision | Collisions list the contract keys with more than one definer, same name | no |
| A key only one major lists is folded as before | A colliding key leaves the other inventory fields, same name | no |
| A platform with one enabled major is unchanged | A platform without collisions derives as before, same name | no |
| A disabled second major defines nothing | A definer of a contract key is an enabled registry entry that lists it, same name | no |
| A collision and an over-subscription are reported together | A collision and an over-subscription may be reported together, same name | no |
| Fulfilled and discriminated can read true while a collision exists | A colliding platform may read fulfilled and discriminated true, same name | no |

| Old clause | New place |
| --- | --- |
| a definer is an enabled entry whose catalog lists the key; a disabled entry never counts; Source: enhancement 0026 | A definer of a contract key is an enabled registry entry that lists it, body |
| `collisions` sorted ascending; `collidingEntries` maps each such key, and no other, to sorted registry keys; `routable` false while `collisions` is non-empty | Collisions list the contract keys with more than one definer, body |
| a colliding key absent from `defined`, `definedBy`, `requiredBy`; not in `unfulfilled` or any `comparable` row | A colliding key leaves the other inventory fields, body |
| `providedBy` and `overSubscribed` unaffected; a collision and an over-subscription MAY be reported together | A collision and an over-subscription may be reported together, body |
| a platform with no colliding key derives empty `collisions` and `collidingEntries` and every other field as before | A platform without collisions derives as before, body |
| `fulfilled` and `discriminated` MAY read true on a colliding platform; a consumer MUST treat non-empty `collisions` as overriding both; `routable` is false | A colliding platform may read fulfilled and discriminated true, body |

No other file cites these old headers as requirement names (`grep -rn --exclude-dir=archive`; a comment in `src/pins/platform_contracts_pins.cue` uses the phrase "reports and never refuses" in prose).

### Strength changes and repeated Source lines (review of unit 1)

An ADDED body needs SHALL or MUST, so these present-tense statements of the old text are MUST in the new text. The human rules on each at the gate:

| Block | Old wording | New wording |
| --- | --- | --- |
| contract-fulfilment, The provider count is of registry entries | "The count is of registry entries"; "A provider counts" | "MUST be of registry entries"; "MUST count" |
| contract-fulfilment, Zero providers are an unresolved demand | "Zero is an unresolved demand, which fails the render" | "MUST be an unresolved demand, which fails the render" |
| contract-fulfilment, The contract inventory computes the provider count once | "`core` declares the intent and computes the count once" | "MUST declare ... and compute ... once" |
| contract-fulfilment, The render build and the generation step refuse on the one count | "The kernel's render build and the generation step ... refuse" | "MUST refuse" |
| contract-fulfilment, A render's caller may ask to skip unprovided demands | "The request is per render"; "every render behaves" | "MUST be per render"; "MUST behave" |
| contract-fulfilment, The kernel enforces the skip rule and the inventory is unchanged | "Enforcement is the kernel's"; "the inventory is unchanged by it" | "MUST be the kernel's"; "MUST be unchanged by it" |
| primitive-keying, An unset FQN in an attachment map takes its key | "the map key binds `metadata.fqn`" | "MUST bind" |
| primitive-keying, The six attachment maps bind a key to its member's fqn | "`core` binds the key" | "MUST bind" |
| primitive-keying, Demand maps and implementation maps enforce the key form only | "`core` enforces the form only" | "MUST enforce" |
| primitive-keying, A transformer map key is checked for form only | "is checked for form only"; "neither compares" | "MUST be checked for form only" (the second clause is the reason) |
| primitive-keying, `#Trait.appliesTo` is not checked against the component's resources | "`#Trait.appliesTo` stays unchecked ...; core#99 tracks whether to enforce or drop it" | "MUST stay unchecked ..." (a status note became a prohibition; the human may prefer to drop the block, since core#99 may enforce it) |
| platform-contract-inventory, A platform... and the other ADDED blocks | old text already held MUST | unchanged |

Source lines kept on every split block that carries a rule they support: the owner decision of the beta.1 kernel plan walkthrough is on "A contract map binds each member's fqn to its key" and on "The transformer map is not bound to the transformer fqn"; the enhancement 0026 source is on all six collision blocks (in short form on five). Review nits fixed: the scenario "The inventory is not authorable" has an observable outcome; "exactly as before collisions were reported" replaces "before this requirement".
