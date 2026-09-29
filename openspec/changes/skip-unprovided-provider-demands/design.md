## Context

`SPEC.md` says three times that an unmet demand fails the render:

- §2.1: a provider-fulfilled contract with zero providers "is an unresolved demand and MUST fail the render".
- §3.1: every declared resource is a required demand.
- §3.1: an unhandled trait resolved `optional: false` fails the render.

§2.2 carries `fulfilment` "by the same rules as `#Resource` (§2.1)". The schema enforces none of these rules. §2.1 and §3.1 both hand enforcement to the kernel, whose render build refuses through one fail-closed gate. See `proposal.md` for why a caller needs to ask for less.

This change touches no `src/*.cue` file. The constructs whose `SPEC.md` sections move (`#Resource`, `#Trait`, `#Component`) are already listed in `.tasks/spec-tracked.txt`, and their CUE is unchanged. Nothing is newly tracked, and no helper is involved. No definition's closedness, defaults or required fields change.

## Goals / Non-Goals

**Goals:**

- State a caller-requested exception to the unmet-demand rule, so the kernel can implement it without violating `SPEC.md`.
- Keep the exception exactly as wide as "nothing on the platform can ever provide this": zero requiring transformers for a provider-fulfilled key.
- Keep the two invariants the demand rules exist for: no component renders a partly satisfied resource set, and no unmet demand passes without being named.

**Non-Goals:**

- Any schema field. The request is an input to one render, not a property of a module, component, trait or platform, so no `core` definition carries it.
- Any change to `#ContractInventory` or `#Platform.#contracts`. `unfulfilled` describes the platform with no module in hand and stays a report. `overSubscribed` stays the value that generation refuses on.
- The kernel's API, the diagnostic's field names and wording, and the CLI flag. The library and cli changes that implement and expose the rule own those.
- The pages under `docs/site/concepts/` that describe the refusal (`how-matching-works.md`, `platforms-and-catalogs.md`). They describe what a user sees, and no user can ask for the skip until the cli flag ships, so they are updated then.

## Research & Decisions

### Which unresolved demands the exception covers

**Context**: A provider-fulfilled demand is unresolved in one of two ways. Either no enabled transformer requires the key at all, or one does and it did not match this component (a predicate or unify refusal). Only the first means "this platform cannot provide it".

**Explored**: §2.1's single-provider rule, which already counts the transformers *requiring* a provider-fulfilled key. The library render build's over-subscription guard, which folds the same count per key from the enabled registry entries (`library/opm/internal/renderstage/render.cue.tmpl`, `guard._providerSuppliers`). The unresolved-demand rows, which already distinguish an empty bucket from an all-disqualified one.

**Decision**: The exception covers a demand only when its contract declares `fulfilment: "provider"` and zero enabled transformers require the demanded key. A present provider that did not match, a catalog-fulfilled demand, and an over-subscribed contract all still refuse.

**Rationale**: A present provider that did not match is a real defect on a platform that has the provider, which is exactly what the refusal exists to catch. A catalog-fulfilled demand with no transformer is a catalog or pin defect, never "not provided here". Keying on zero requiring transformers reads the same number §2.1 defines for the single-provider rule, so the exception and the over-subscription rule cannot drift apart.

Rejected: skip every unresolved provider-fulfilled demand, because it hides a broken provider behind the same switch that hides a missing one. Skip every unresolved demand of any fulfilment, because it hides catalog defects.

### What a skipped resource does to its component

**Context**: §3.1 forbids rendering the satisfied part of a partly satisfied resource set. A component whose resource has no renderer has nothing coherent to deploy (§3.1 Rationale, the resource-versus-trait asymmetry).

**Explored**: the §3.1 constraints and Rationale bullets on resource demands, and the render build's `unmatched` rule, under which a component with no matched pair is reported as unmatched.

**Decision**: A skipped resource demand omits the whole component. It renders nothing, the report says so, and it is not reported as unmatched. A skipped trait demand leaves its component rendering every pair it matched, with the trait producing nothing.

**Rationale**: This keeps the partial-set rule intact and follows the asymmetry §3.1 already argues. A trait modifies something that renders regardless; a resource is the thing that renders. "Unmatched" would be the wrong verdict, because the component was skipped on request, not refused by the transformers. Rejected: render the component's satisfied resources, which contradicts §3.1 and would deploy a component missing a resource its author declared.

### Who may ask for the skip

**Context**: `optional` already lets the catalog and the attachment site say that a trait is advisory.

**Explored**: §2.2's `optional` rules and §3.1 Rationale on why resources carry no optionality marker.

**Decision**: The request belongs to the render's caller, per render. No module, component, trait or platform can carry it, and `optional` is unaffected.

**Rationale**: The skip is a different statement from `optional`. It says "render what this platform can, and tell me what it could not", and only whoever runs the render can make it. Putting it on an artifact would let a module declare a load-bearing demand it does not mean, the class of statement §3.1 Rationale rejects for resource optionality.

### Reporting

**Context**: §3.1 Rationale ("Why an unmet demand is an error at all") records a backup that silently did not exist.

**Explored**: the same Rationale bullet, and the render build's existing diagnostics rows.

**Decision**: Every skipped demand is reported with the component, the contract key and the kind. For a resource, the report also says the component rendered nothing. The report's shape is the kernel's.

**Rationale**: A mandatory report is what stops the exception reopening the silent-backup failure.

## SPEC.md edits

- **§2.1 `#Resource`, Constraints.** The `fulfilment: "provider"` bullet keeps "zero is an unresolved demand" and adds "which MUST fail the render unless the render's caller asked to skip unprovided provider-fulfilled demands (§3.1)". Two providers remain refused under the request. The enforcement bullet ("That count is enforced at materialize") gains one sentence: the kernel also honours the skip request.
- **§2.2 `#Trait`, Constraints.** The `fulfilment` bullet already defers to §2.1. It gains a pointer to the §3.1 skip for the `backup` case it names.
- **§3.1 `#Component`, Constraints.** A new bullet, after the load-bearing-trait bullet, states the exception whole:
  - only unprovided provider-fulfilled demands;
  - the three cases that still refuse;
  - the consequence for each kind;
  - the mandatory report;
  - `optional: true` traits unaffected.

  The resource bullet and the load-bearing-trait bullet each gain "except as the skip below allows". The enforcement bullet ("Enforcement of the three rules above is the kernel's") becomes "of the rules above", so it covers the new bullet too.
- **§3.1 `#Component`, Rationale.** One new bullet after "Why an unmet demand is an error at all". It says why a caller-requested, reported skip does not reopen the silent-backup failure, and why it is keyed on zero providers.
- **§3.4 `#ContractInventory`.** Read and left unchanged. `unfulfilled` is a platform report that gates nothing in `core`, and it lists the same contracts whether or not any render skips them.

## Risks / Trade-offs

- [A caller turns the skip on for a deployment that needed the provider, and ships a workload without backups] → The skip is off by default and never set by the operator. Every skipped demand is reported by name, and the cli change also records the skip on the instance it applies.
- [The kernel implements a narrower or wider rule than stated] → The spec delta's scenarios fix the boundary in both directions: a present-but-unmatched provider, a catalog-fulfilled demand and an over-subscribed contract still refuse. The library change's tests are written against those scenarios.
- [A reader of §2.1 alone misses the exception] → §2.1 and §3.1 cross-reference it, and §2.2 points at it for the `backup` case.
