## Why

`#Component.metadata.resourceName` is typed `#NameType` (a DNS-1123 label), which is both too strict and too loose for what the API server enforces. Too strict: the kinds most components render (Deployment, DaemonSet, ConfigMap, Secret, StorageClass, CSIDriver, CRD, APIService) admit a DNS subdomain, dots included, at 253 runes, so an author cannot name a CSIDriver `zfs.csi.openebs.io` through the override that exists for exactly that case. Too loose: `#NameType` admits a leading digit, so an instance named `1prod` vets clean and its Service `1prod-web` is refused at apply as not DNS-1035; and a dotted or 64-rune name is refused at apply on StatefulSet and Namespace. Every one of these is a fact the server knows and `cue vet` does not. Enhancement 0019 resolves this with D20, D21 and D23: three name types transcribing the server's three validators, and a per-primitive `#nameConstraint` slot the component asserts, so the primitive that introduces a dot-hostile kind is the one that declares the rule and core carries no per-kind knowledge.

This is `core-name-types-and-constraint`, implementing `enhancements/0019` D20, D21 (as revised 2026-08-26) and D23's core allowance. It is Phase A work and gates the catalog names sweep (0019 06-operational step 6), which cannot declare `#ExposeTrait: #nameConstraint: #ServiceNameType` until the slot exists. Now, because that sweep is the next slice in the entry's order and everything else it needs has landed.

## What Changes

- `src/types.cue`: two new constrained-string types, `#ObjectNameType` (RFC 1123 subdomain, ≤253) and `#ServiceNameType` (RFC 1035 label, ≤63). `#NameType` is unchanged.
- `src/resource.cue`, `src/trait.cue`, `src/blueprint.cue`: each primitive gains a hidden definition field `#nameConstraint: _`, top by default, never optional and never guarded. A primitive MAY compute it from its own fields (D23).
- `src/component.cue`:
  - the `resourceName` override ceiling widens from `#NameType` to `#ObjectNameType` (explicit names may carry dots and run to 253 runes); the `error()` arm's text and the `_resourceNameDefaultFits` bound (63 to 253) follow. The default arm, the guard and the `error()` arm otherwise stay as `core-resourcename-default` landed them.
  - a hidden `_nameConstraints` conjunction collected unconditionally from every attached resource, trait and blueprint, and a hidden assertion `_nameFits: "\(metadata.resourceName)" & _nameConstraints` that refuses a resolved name any attached primitive rejects, naming the string and the violated bound.
- `src/component_names_pins.cue` (new, hidden pins only): the must-pass matrix pinned against the real package, because the refuted spellings of this mechanism fail silently and a review cannot see that.
- `SPEC.md` co-update under `core-schema-edit`: §2.1, §2.2, §3.3 (the slot), §3.1 (ceiling, collection, assertion), and §1's note on name types.

Nothing else moves: closedness of the three primitives is preserved (a hidden definition field is added to closed structs, which is a schema edit consumers cannot make themselves and is why this is a core change), `#names` and its projection into `#Module.#ctx.components` are unchanged, no required field is added.

## Classification

**Additive on the override path, BREAKING on two edges, absorbed on the `@v2` alpha line** as `feat(component)!:` (Principle IV; this relies on `@v2` still being pre-release, as 0019 06-operational states). Loosened: an explicit `resourceName` that `#NameType` refused (dots, 64 to 253 runes) is admitted. Tightened, and therefore breaking under Principle I even though nothing is removed: (1) a name that an attached primitive's `#nameConstraint` rejects is refused, which is inert today because no published primitive declares one, and starts firing when the catalog sweep ships Expose, the stateful-workload blueprint, the Namespace resource and the container resource's D23 conditional; (2) `_resourceNameDefaultFits` now admits a 64-to-253-rune default, which previously refused, so the 63-rune protection for a dot-restricted kind moves from core's guard to that kind's primitive. Between this release and the sweep's, a stateful component with a 64-rune default vets clean and is refused at apply; that window is the sweep's to close, and it is the same window the entry accepts for every D15 rename.

## Downstream consumers

- **`catalog_opm`**: the direct consumer. The names sweep re-pins to this release and declares `#nameConstraint` on Expose (`#ServiceNameType`), the stateful-workload blueprint (`#NameType`), the Namespace resource (`#NameType`) and the container resource (D23 conditional on its own `workload-type` key); `#ExposeSchema.name` moves to `#ServiceNameType` (D20, D22). No transformer reads the slot.
- **`library`**: no shape it reads changes; `#nameConstraint` is a hidden definition field the kernel never fills. Fixtures that pin `#NameType` refusals on `resourceName` (if any) move to the new messages on the ordinary dep-bump commit.
- **`modules`**: no v2 staging component sets a dotted `resourceName` today (the type refused it), so nothing renames. Authors gain the override.
- **`cli`, `opm-operator`**: no code reads `resourceName`, `#names` or the new types; they re-pin on their normal cadence.
- **`opmodel.dev`**: the generated schema reference picks up the two new types and doc comments on its next `task generate`.

## Principle V

Two new types and one hidden slot, each with a consumer in the next slice: `#ServiceNameType` is declared by Expose and types `#ExposeSchema.name`; `#ObjectNameType` is the override ceiling and is read by nothing else; `#nameConstraint` is declared by four catalog primitives. No length-only type is added: the dot-restricted kinds carry the 63-rune budget with the dot ban (measured, 0019 experiment 09), so `#NameType` already is that constraint. The pins file is hidden fields only and adds no published surface.

## Capabilities

### New Capabilities
- `name-constraints`: how a primitive declares a `#nameConstraint`, how `#Component` collects and asserts it against the resolved `resourceName`, and the three name types.

### Modified Capabilities
- `component-names`: the override ceiling becomes `#ObjectNameType` (dots, 253 runes) and the overlong-default refusal moves to the 253-rune bound; the DNS-label wording of the invalid-override message changes.

## Impact

- `src/types.cue`, `src/resource.cue`, `src/trait.cue`, `src/blueprint.cue`, `src/component.cue`, new `src/component_names_pins.cue`; `SPEC.md` §1, §2.1, §2.2, §3.1, §3.3.
- `src/INDEX.md` regenerated (two new top-level definitions). `.tasks/spec-tracked.txt` unchanged: the types are `*Type` helpers by the skill's own rule, and the slot lives on already-tracked constructs.
- Source of truth for the shapes: `enhancements/0019/schemas/target.cue` and `examples.cue` (vetted), validated by `enhancements/0019/experiments/09-name-constraint-propagation/` and `11-name-constraint-on-landed-d16/`.
