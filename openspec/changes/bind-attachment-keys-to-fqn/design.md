## Context

At `origin/main` 8dbb7e7 (core v2.0.0-beta.3), each of the six attachment maps constrains its key's form at most:

```cue
// src/resource.cue:172, src/trait.cue:165, src/blueprint.cue:122
#ResourceMap:  [string]: #Resource
#TraitMap:     [string]: #Trait
#BlueprintMap: [string]: #Blueprint

// src/component.cue:50-56
#resources:   #ResourceMap
#traits?:     #TraitMap
#blueprints?: #BlueprintMap

// src/catalog.cue, inside #Catalog (likewise #traits, #blueprints)
#resources: [#ContractFQNType]: #Resource & {
	metadata: {
		A=apiVersion:   #APIVersionType
		modulePath:     "\(M._ref.registryPath)/resources/\(A)"
		catalogVersion: M.version
	}
}
```

Every reader treats the key as the member's identity. `#Platform.#contracts` (`src/platform.cue:244-260`) keys `_definers`, `defined` and `definedBy` by the catalog map key. The library's render template (`library/opm/internal/renderstage/render.cue.tmpl:170-218`) matches transformer demands against `comp.#resources[fqn]` and `comp.#traits[fqn]`. A key that differs from its member's fqn is therefore a silent identity error: the component demands, or the catalog publishes, a name that the member does not carry.

Core is the only place where short keys are authored at `origin/main`:

- `src/pins/component_names_pins.cue:118,131,142,151,164,175,185`: `#resources: container:`. The commented must-fail twins are at :203, 215, 227, 238, 250 and 262.
- `src/pins/platform_and_match_pins.cue:118-119`: `container:` and `volumes:`. Line :330 has `#resources: container:`. The read-backs at :151-152 index `.container` and `.volumes`. The commented twins are at :463, 489, 514 and 537.
- `src/pins/catalog_pins.cue:99-116`: `_pinContractKeyNotCompared` and its read-back assert that core does **not** compare key and fqn.

Files this change touches: `src/resource.cue`, `src/trait.cue`, `src/blueprint.cue`, `src/catalog.cue`, `src/pins/component_names_pins.cue`, `src/pins/platform_and_match_pins.cue`, `src/pins/catalog_pins.cue`, `src/pins/identity_package_pins.cue`, `src/pins/identity_pins.cue` (header), `Taskfile.yml` (the `vet` export list and its comment), `AGENTS.md` and `.claude/skills/core-schema-edit/SKILL.md` (the pins-are-hidden statements), `SPEC.md`, `src/INDEX.md` (regenerated), and the outline comments of `docs/site/concepts/platforms-and-catalogs.md` and `docs/site/concepts/components-and-blueprints.md`. `src/component.cue` is not edited: it already types its maps with the three map definitions. Tracked constructs whose SPEC.md sections move: `#Trait` (§2.2, the `appliesTo` text only), `#Component` (§3.1), `#Blueprint` (§3.3, the `appliesTo` text only), `#Catalog` (§3.6) and `#TraitOptionalGate` (§5.1). No construct is newly tracked. `#ResourceMap`, `#TraitMap` and `#BlueprintMap` stay untracked helpers. `docs-kit.cue` already excludes them as "map shorthand", and they gain only a doc comment.

## Goals / Non-Goals

**Goals:**

- In all six attachment maps, a key that differs from its member's `metadata.fqn` is a hard `cue vet` error that names both strings.
- Core's own pins key by fqn. The old "not compared" pin becomes a recorded must-fail case, and every map has a must-fail case and a positive case.
- The publish-gate pins are non-hidden, so plain `task vet` gates rule 1 of `#TraitOptionalGate`, and the rule-1 text everywhere says what plain vet actually prints.
- `appliesTo` stays unchecked and is documented that way, citing core#99.

**Non-Goals:**

- Binding `#Catalog.#transformers` (SD13). Every published transformer already matches its key, so binding it later costs one more tightening and nothing else.
- Binding the transformer demand maps (`requiredResources`, `optionalResources`, `requiredTraits`, `optionalTraits`).
- Checking `appliesTo` (core#99).
- Changing `task vet` to `cue vet -c`. Plain vet now fails on rule 1. `-c` would also name the field, and that stays a possible follow-up.

## Decisions

### The component maps

```cue
// src/resource.cue
// WHY bound: every reader treats the key as the member's identity (the
// platform's contract fold, the render build's demand match). SPEC.md § 3.1
// Rationale, "Why an attachment key must equal the member's fqn".

// ResourceMap: resources attached to a component, keyed by each member's
// own metadata.fqn; a key that differs is a conflict. See SPEC.md § 3.1.
#ResourceMap: [FQN=string]: #Resource & {metadata: fqn: FQN}

// src/trait.cue
#TraitMap: [FQN=string]: #Trait & {metadata: fqn: FQN}

// src/blueprint.cue
#BlueprintMap: [FQN=string]: #Blueprint & {metadata: fqn: FQN}
```

The key stays `string` rather than `#ContractFQNType`. The member's own `fqn!: #ContractFQNType` already refuses a non-contract key. Keeping `string` means a short key reports `conflicting values "container" and "<fqn>"`, which names the fix. A typed key would report `field not allowed` and name neither string. The exact doc-comment wording may move during implementation. It must stay within six lines (`task docs:check`), with the rationale in the WHY block. The other two maps carry a two-line pointer to the `#ResourceMap` WHY block (AGENTS.md "Doc comments", tier 2).

### The catalog maps

```cue
#resources: [K=#ContractFQNType]: #Resource & {
	metadata: {
		fqn:            K
		A=apiVersion:   #APIVersionType
		modulePath:     "\(M._ref.registryPath)/resources/\(A)"
		catalogVersion: M.version
	}
}
// #traits and #blueprints: the same line added under their own stamps.
```

`#transformers` keeps its current pattern. The `catalog.cue` header and the §3.6 Rationale "Why the pattern stamps `modulePath` + `catalogVersion` but not `fqn`" are reworded. The transformer stamp still does not touch `fqn`. The contract maps now bind it to the key. Binding does not compute `fqn` from `name` or `modulePath`, so 0010:D21 (an fqn is authored, not derived) still holds: both the key and the fqn are authored, and core now requires them to agree. `#CatalogMemberFQNGate` still checks fqn against the identity package at publish.

### A member that leaves fqn unset

Under the bind, a member placed in one of the six maps without an authored `fqn` takes the key as its fqn, because unification fills the required field. This is accepted, and specified: the primitive-keying requirement "A catalog member's FQN is authored, not derived" is modified to say that the definitions derive nothing, but inside the six maps the key binds fqn (a disagreeing value is refused, an unset one takes the key), and SPEC §2.1's Constraint bullet says the same. The member definition still requires `fqn!`, every catalog wrapper authors it, and at publish the gate refuses an fqn that disagrees with the identity package. The positive pins key by `(X.metadata.fqn)`, so they test the authored case; one bind-fill read-back per map tests the fill, and is exported by `task vet` so that losing any one bind fails the vet.

### Pin rewrites and new cases

- Short keys become `(_pinNameContainer.metadata.fqn):`, `(_pinMatchContainer.metadata.fqn):` and `(_pinMatchVolumes.metadata.fqn):`. Read-backs index `[_pinMatchContainer.metadata.fqn]`. Measured during planning, this rewrite makes `cue vet ./...` green against the bound maps.
- The commented twins get the same key rewrite. Each recorded error is re-run in place, and the text is updated wherever a path in it changes.
- `_pinContractKeyNotCompared` becomes a commented must-fail case. Measured during planning on cue v0.17.1:

  ```text
  _failContractKeyMismatch.#traits."opmodel.dev/catalogs/opm/traits/autoscale@v1beta1".metadata.fqn: conflicting values "opmodel.dev/catalogs/opm/traits/autoscale@v1beta1" and "opmodel.dev/catalogs/opm/traits/scaling@v1beta1"
  ```

  It is renamed `_failContractKeyMismatch`, and the error is re-recorded under that name. The section banner "Key and fqn are not compared by core" becomes "A contract key must equal its member's fqn". A positive pin for each of the three catalog maps reads the member back by its fqn key.
- New commented must-fail cases cover a component resource under `container:`, a trait under another trait's fqn, and a blueprint under another blueprint's fqn. Measured for the resource during planning:

  ```text
  _failShortResourceKey.#resources.container.metadata.fqn: conflicting values "container" and "opmodel.dev/catalogs/opm/resources/container@v1beta1"
  ```

  CUE also prints follow-on `field not allowed` errors on `spec`, because the conflict empties the member. The recorded text quotes the first line and says that the follow-on lines exist.

### Non-hidden publish-gate pins

The rule covers applied (uncommented) gate pins only. The commented must-fail gate cases (`_failGatePinned` and the seven `_failGate*` `#CatalogMemberFQNGate` cases) keep the hidden shape: each reports a conflict, which CUE reports in a hidden field too, and their recorded errors were measured in that shape. `failGateUnstated` is already non-hidden, because it tests incompleteness.

The seven pins that apply a publish gate are renamed without the `_` prefix: `pinGateTraitPostureRequired`, `pinGateTraitPostureAdvisory`, `pinGateResource`, `pinGateResourceGA`, `pinGateTrait`, `pinGateBlueprint` and `pinGateTransformer`, and every reference is updated. Package `pins` is imported by nothing, so a regular field there ships to no consumer, and `cue vet` now checks the gates for completeness.

### Rule-1 text

The text everywhere says what cue v0.17.1 prints for a non-hidden application of an unstated posture. Plain `cue vet ./...` exits 1 with `some instances are incomplete; use the -c flag to show errors or -c=false to allow incomplete instances` and names no field. `cue vet -c ./...` prints `failGateUnstated.optional: incomplete value bool`. A hidden application exits 0 under both. The places to correct are `src/trait.cue` (the RULE 1 comment on `_stated`), SPEC §5.1 (the Shape comment "Visible only under `cue vet -c`", the Constraints bullet "rule 1 does not", and the Rationale "Rule 1 is an incomplete value, which it does not"), and the "THESE PINS ARE HIDDEN" paragraph in `platform_and_match_pins.cue`, which loses its premise once the pins are non-hidden. The publish requirement for `-c` stays, because only `-c` names the field.

## Research & Decisions

### Does a pattern label alias bind on cue v0.17.1?

**Context**: The `catalog.cue` header records that a bare reference inside a pattern literal fails with "reference not found". That is why the stamps read `apiVersion` through `A=apiVersion`.
**Explored**: A scratch copy of `src/` at 8dbb7e7 with the three map definitions and the three catalog maps changed as shown above, run under `cue vet ./...` on cue v0.17.1.
**Decision**: Use the pattern-label alias `[FQN=string]` / `[K=#ContractFQNType]`. It resolves inside the literal, which a bare `apiVersion` does not.
**Rationale**: With the bind in place, `cue vet .` (package core) passed. The short-key pins failed with the conflicting-values error above. After the key rewrite they passed. `_pinContractKeyNotCompared` failed with the recorded error. No spike section is needed.

### Which pins are "the gate pins"?

**Context**: The wave-1 follow-up ("Gate pins in package pins not made non-hidden") was raised on `#TraitOptionalGate`, but `#CatalogMemberFQNGate` is also a publish gate, and its applications in `identity_package_pins.cue` are hidden too.
**Explored**: In a scratch copy, all seven applications were renamed without the `_` prefix and run under `cue vet ./...` and `cue vet -c ./...`. Both exited 0. Adding the rule-1 case as `failGateUnstated` made plain vet exit 1 with the generic message, and `-c` named `failGateUnstated.optional`.
**Decision**: Make all seven non-hidden.
**Rationale**: SPEC §5.1 says a gate MUST be unified into a non-hidden value. The pins now follow the rule they document, at no cost. The pin-shape rule in the file headers (a pin forces evaluation) is unchanged.

### `#transformers`

**Context**: The research counted seven key-to-member maps, but the owner's sentence names the component and catalog member maps. SPEC §3.6 says the transformer key-to-fqn agreement is asserted at publish by `#CatalogMemberFQNGate`. That is false: the cli fills the gate from the member definitions it finds by package (`cli/internal/publish/catalog_gates.go`) and never reads a `#Catalog` map key. The transformer key is checked for form only, and this change rewrites the §3.6 bullet to say so.
**Decision**: SD13. Bind the six attachment maps, and leave `#transformers` as is.
**Rationale**: The decision covers attachment maps. All 23 to 29 published transformers per release match their keys, so binding `#transformers` later costs one more tightening and nothing else.

## Risks / Trade-offs

- **A third-party hand-keyed map breaks on the core bump.** This is the purpose of the change. The error names the key and the fqn, and the migration note gives the fix.
- **Catalog wrappers that embed partial attachments.** A blueprint wrapper adds `#resources` entries through unification. If a wrapper keys by fqn, the bind is a no-op. If it does not, it fails. The planning audit found every wrapper in catalog_opm keyed by fqn. The pre-merge re-vet proves this against the real build.
- **An unset fqn is filled from the key.** See "A member that leaves fqn unset" above.

## Re-vet against this build

Run 2026-10-05 on cue v0.17.1, in scratch copies only; no consumer repo was changed.

**The build.** The branch's `src/` at commit a01ccd3 (sections 1-3) was published as the throwaway version `opmodel.dev/core@v2.0.0-beta.99` to a private in-memory `cue mod registry` on 127.0.0.1:5917, never to GHCR or the shared `localhost:5000`. All 145 published `opmodel.dev/core` tags were copied into it from GHCR with `crane copy`, so module-graph resolution of older core versions still worked. `CUE_REGISTRY` routed `opmodel.dev/core` (and, for the library registry fixtures, `testing.opmodel.dev`) to that registry and everything else to GHCR, with a private `CUE_CACHE_DIR`. Each consumer was copied twice, its core requirement set (or added) to `v2.0.0-beta.3` (origin/main's core, the baseline) and to `v2.0.0-beta.99` (this branch), and vetted on both. The cache held only `core@v2.0.0-beta.99` after the first run, which confirms resolution went through the override.

**Positive controls.** A component keyed `#resources: container: #ContainerResource`, added to a scratch copy of catalog_opm `src/resources/v1beta1` and of `modules/apprise` (under `#components`), failed plain `cue vet` with `... .#resources.container.metadata.fqn: conflicting values "opmodel.dev/catalogs/opm/resources/container@v1beta1" and "container"`. Plain vet therefore reaches attachments in both regular fields and definitions, and the override was live.

**Result: no mis-keyed member anywhere. No OWNER STOP (0021:D7:R5) fired.**

| Consumer (origin/main) | Command | beta.3 | beta.99 | Note |
| --- | --- | --- | --- | --- |
| catalog_opm `src/` (3d92d84) | `task vet` (plain and `-t fixtures`), `task vet:fixtures` | — | pass | 71 rendered-output fixtures evaluate |
| Published `opmodel.dev/catalogs/opm@v4` 4.1.0, 4.1.1, 4.2.0, 4.3.0, 4.3.1, 4.4.0-4.4.5, 4.5.0-4.5.2, 4.6.0 (source pulled from GHCR, vetted as main module) | `cue vet ./...`, and `-t fixtures` where the release has fixture files | pass (as pinned) | pass | |
| Published `catalogs/opm` v2.0.0-alpha.1 to alpha.8, v2.0.0, v3.0.0, v4.0.0, v4.0.1 | `cue vet ./...` | fail | fail | Pre-existing: identical error sets on beta.3 and beta.99 (label-count and transformer fixtures broken by earlier core releases); no `metadata.fqn` conflict in either. Key audit below finds every key fqn-shaped. |
| Published `catalogs/k8s` v1.0.0-alpha.1 to beta.2, `catalogs/kubernetes` v2.0.0-alpha.1 | `cue vet ./...` | pass (as pinned) | pass | `catalogs/kubernetes` v1.2.0 is on core@v1, so unaffected |
| modules fleet (eb4cb97): apprise, cert_manager, gotify, istio_ambient, k8up, metallb, ntfy, web_app | `cue vet ./...` | pass | pass | |
| opm-modules (f16a187, read only): fileflows, intel_gpu_device_plugin, intel_gpu_exporter, jellyfin, jellystat, jellyswarrm, nvidia_device_plugin, nvidia_gpu_exporter, radarr, sabnzbd, seerr, sonarr | `cue vet ./...` | pass | pass | |
| library (168c736): `modules/opm_platform`, `testdata`, `testdata/modules/web_app`, `testdata/parity`, `testdata/parity/opm_platform`, the 15 `testdata/render/{instance*,platform*,scenarios}` modules | `cue vet ./...` | pass | pass | render modules need the served registry fixtures below |
| library `testdata/render/registry/*` (14 modules) | served: each published to the scratch registry at its directory version (with `source: kind: "self"` added in scratch; `bprov` v1.0.0 published from a `cue mod tidy` copy, because it is not tidy), then `cue vet ./...`; `-c=false` for app_bk0, app_maj0, web_app v0.1.0 and v0.2.0, which carry unfilled values by design | pass | pass | |
| cli (bd4d1a7c): examples, hack/platform, internal/workflow/render/testdata/skip-unprovided, templates/{advanced,minimal,standard}, tests/e2e/testdata/{duplicate-identities,operator-owned,vet-errors/*}, tests/fixtures/{modules/podinfo,valid/*}, tests/integration/{inst-tree,module-apply}/testdata | `cue vet ./...` | pass | pass | |
| cli internal/instinit/testdata/initvalues, tests/e2e/testdata/vet-errors/open-debug-values | `cue vet -c=false ./...` | pass | pass | incomplete by design (plain vet says so on both builds) |
| opm-operator (9b83611): `modules/opm_operator`, hack/testdata/operator-module-release-check/module, internal/source/testdata/minimal-module, test/fixtures/catalogs/{backup,provider}, test/fixtures/modulepackages/{hello,hello_web,podinfo,redis}, test/fixtures/modules/{backup_consumer,backup_provider,hello,hello_web,podinfo,redis} | `cue vet ./...` | pass | pass | |

No consumer was left NOT VETTED.

**Key audit.** A scan of every `#resources`, `#traits` and `#blueprints` struct written in CUE or in a Go string (`.cue`, `.go`, `.tmpl`) flagged any key that is neither an `(… .metadata.fqn)` expression nor a quoted contract FQN. It flagged 10 keys in core at 8dbb7e7 (the short pin keys this change rewrites), and 0 in: this branch's `src/` (51 keys), catalog_opm main (92), every published catalog release above (up to 92 per release), library (94), cli (8) and opm-operator (1). The Go-embedded component maps are five `#resources: %q:` sites in library `opm/kernel/` tests (`integration_fixtures_test.go` twice, `parity_probe_test.go`, `flow_synth_catalog_import_test.go`, `flow_synth_imported_test.go`), each filled with `containerFQN`, the same value as the member's `fqn`. cli and opm-operator embed no attachment map in Go; opm-operator's `internal/render/demand.go` only reads `#resources` and `#traits`. `registrytest.BuildCatalog` writes `#transformers` only.

**Still to run at the PR stage.** Re-run the library fixture vet and the Go-embedded audit against library `origin/main` once `lib-i3d2` and `lib-b1g2` have merged.
