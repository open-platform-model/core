## Why

`opm instance init` (cli change `add-instance-init`, enhancement 0016) fills a new instance's `values.cue` from the module. Today its only source is `debugValues`, whose contract is "values for testing and debugging". Authors put throwaway hostnames, debug log levels and dummy credentials there, and none of that belongs in a user's deployment file. `#Module` has no field through which an author can say "this is what a new deployment should start from". Enhancement 0016 D3 and D4 add one.

Implements `enhancements/0016` D3 and D4 on the schema side (`0016:D3:R1/R3`, `0016:D4:R1/R2`). The reader side (`0016:D3:R2`, `0016:D4:R3`) lands in cli.

## What Changes

- **`#Module` gains `initValues?: _`**, an optional, open sibling of `debugValues`. It means "the values a freshly initialized instance package starts from".
- **No `#config` assertion.** The schema does not check `initValues` against `#config`. Conformance is observed where the value is consumed, by `opm instance vet` on the generated package (0016 D4). `initValues` may be non-concrete: an undefaulted disjunction is the "pick one" prompt a first-time deployer should see.
- **`debugValues` is unchanged.** Same field, same meaning, same SHOULD-satisfy-`#config` constraint. A module may carry both with different content.
- **Identity is untouched.** `initValues` reaches neither `fqn` nor `uuid`, for the module or for any instance that deploys it.
- `SPEC.md` § 3.2 co-updates in the same commit, `docs/constructs.md` gains the field beside `debugValues`, and `src/INDEX.md` regenerates.

## Capabilities

### New Capabilities

- `module-init-values`: what `#Module` accepts in `initValues`, what it keeps rejecting, and that the field is inert for identity and for existing modules.

### Modified Capabilities

(none)

## Impact

**Release class: MINOR (`feat:`).** Purely additive: an optional field on a closed definition. No published constraint tightens, nothing is removed, and every module that validates today still validates, which 0016 experiment 06 measured. The change does not rely on `@v2` still being in prerelease (Principle IV).

Principle V: the field has a named consumer before it ships. `add-instance-init` section 4 in cli reads it, and that section is gated on this release.

A **version floor** comes with it, which is the ordinary cost of any new field on a closed definition. A module that sets `initValues` must pin a core release that ships the field; against an older core it fails with `initValues: field not allowed` (experiment 06).

| Consumer | What it has to do |
| --- | --- |
| `cli` | Nothing to merge here. `add-instance-init` section 4 waits for this release, then reads `initValues` ahead of `debugValues`. |
| `library` | Nothing. The kernel evaluates a module against the core its own `cue.mod` pins, and uses its schema cache only to derive the synthesized instance's core import major (`opm/kernel/synth.go`). It never unifies a module against its own core copy. |
| `modules` | Optional. An author who adopts `initValues` moves the module's core pin to this release first (`task deps:update`). |
| `opm-operator`, catalogs | Nothing. |
| `opmodel.dev` | The generated schema reference picks up the field on its next regeneration. |
