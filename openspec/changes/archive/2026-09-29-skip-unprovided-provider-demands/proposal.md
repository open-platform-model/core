## Why

A provider-fulfilled contract (the catalog's `backup` and `backup-command` traits today) has no transformer in the catalog that declares it, so a render against any platform without the provider refuses the whole instance. That is right for a deployment on a platform that should have the provider. It is wrong for everything else: an author running `opm module build` against the module's own deps, and a deployer on a cluster without the operator, where no provider can ever be registered. Both want to render what the platform can and be told, by name, what was left out. Today `SPEC.md` says zero providers MUST fail the render, with no way for a caller to ask otherwise, so the kernel cannot offer that without breaking the specification.

## What Changes

- `SPEC.md` gains a caller-requested exception to "zero providers is an unresolved demand and MUST fail the render": a render's caller MAY ask the render to skip demands on provider-fulfilled contracts that no enabled catalog provides.
- The exception is narrow. It covers only a contract declaring `fulfilment: "provider"` for which zero enabled transformers require the demanded key. A catalog-fulfilled demand, a provider-fulfilled demand whose provider exists but did not match, and an over-subscribed contract still refuse.
- The consequence is stated per kind. A skipped trait demand: the component renders every pair it matched and the trait renders nothing. A skipped resource demand: the component renders nothing at all and is not reported as unmatched, so a partly satisfied component still never renders.
- Every skipped demand MUST be reported, naming the component and the contract key. Nothing is skipped silently, and nothing is skipped unless the caller asked.
- Off is the default and is exactly today's behaviour. Enforcement stays the kernel's; `core` states the rule.
- The platform contract inventory (`#Platform.#contracts`, `unfulfilled`) does not change: it describes the platform, not a render.
- Not **BREAKING**: no published definition changes, and every render that refused before still refuses unless its caller opts in.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `contract-fulfilment`: adds the caller-requested skip of unprovided provider-fulfilled demands, and qualifies the three requirements that today say an unmet demand always fails the render (the single-provider rule's "zero" case, the required-resource rule, and the load-bearing-trait scenario).

## Impact

- **`SPEC.md` only.** §2.1 `#Resource` (the `fulfilment` constraints and the enforcement bullet), §2.2 `#Trait` (the `fulfilment` bullet, by reference to §2.1), §3.1 `#Component` (the demand constraints and a rationale bullet). §3.4 `#ContractInventory` is read and left unchanged. No `src/*.cue` file changes, no construct in `.tasks/spec-tracked.txt` moves, and `src/INDEX.md` is unaffected.
- **Release: none.** The published CUE is byte-identical, so the change lands as a `docs(spec):` commit that release-please skips. It does not rely on `@v2` being in prerelease, since nothing published changes. No consumer pin moves.
- **library** implements the rule: a per-render switch on the kernel's render input, the reported skipped rows, and the omission of a component whose resource demand was skipped (change `render-skips-unprovided-provider-demands`). Until it lands, the kernel keeps refusing, which is still conformant because the exception is permissive.
- **cli** exposes the switch as a flag on the render-bearing commands (change `add-skip-unprovided-flag`).
- **opm-operator** does not set the switch and needs nothing: an operator render keeps refusing an unprovided demand, which is the point of running a provider.
- **catalogs and modules**: nothing. The `backup` and `backup-command` traits keep `fulfilment: "provider"` and their load-bearing `optional` posture.
