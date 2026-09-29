## 1. State the caller-requested skip in SPEC.md

- [x] 1.1 `SPEC.md` §2.1 `#Resource` Constraints: in the `fulfilment: "provider"` bullet, qualify "zero is an unresolved demand and MUST fail the render" with the exception, "unless the render's caller asked to skip unprovided provider-fulfilled demands (§3.1)", and state that two providers remain refused under that request. In the enforcement bullet ("That count is enforced at **materialize**"), add that the kernel also honours the skip request. Verify: §2.1 no longer states an unconditional failure for zero providers, and it names §3.1.
- [x] 1.2 `SPEC.md` §2.2 `#Trait` Constraints: in the `fulfilment` bullet that names `backup`, add a pointer to the §3.1 skip. Verify: the bullet still defers to §2.1 and names §3.1.
- [x] 1.3 `SPEC.md` §3.1 `#Component` Constraints: add one bullet after the load-bearing-trait bullet stating the exception whole, per `design.md` § SPEC.md edits:
  - only unprovided demands (provider-fulfilled, zero requiring transformers);
  - a catalog-fulfilled demand, a present provider that did not match, and an over-subscribed contract still refuse;
  - a skipped trait leaves the component rendering its matched pairs; a skipped resource omits the whole component, which is not reported as unmatched;
  - every skip is reported, naming the component, the contract key and the kind;
  - `optional: true` traits are unaffected.

  Qualify the resource-demand bullet and the load-bearing-trait bullet with "except as the skip below allows", and widen "Enforcement of the three rules above" to cover the new bullet. Verify: each scenario in `specs/contract-fulfilment/spec.md` maps to a sentence in §3.1.
- [x] 1.4 `SPEC.md` §3.1 `#Component` Rationale: add one bullet after "Why an unmet demand is an error at all". It explains why a caller-requested, reported skip does not reopen the silent-backup failure, and why the exception is keyed on zero providers. Verify: the bullet names the report as the reason and the §2.1 provider count as the key.
- [x] 1.5 `SPEC.md` §3.4 `#ContractInventory`: confirm by reading that no constraint or rationale bullet needs to change. `unfulfilled` stays a report that gates nothing in `core`. Verify: `git diff SPEC.md` shows no hunk inside §3.4.
- [x] 1.6 Run `grep -n "fail the render" SPEC.md` and confirm that every hit about an unmet demand now carries the exception or points at §3.1. Verify: no unqualified statement is left that contradicts the new §3.1 bullet.
- [x] 1.7 `task check` green (no `src/*.cue` changed, so `spec:check` and `generate:index:check` stay clean), then commit `docs(spec): let a render skip unprovided provider-fulfilled demands on request`
