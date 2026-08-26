## Context

See proposal.md for motivation. Current state in `src/`: `#NameType` is the only name type; `#Component.metadata.resourceName` is `*"\(#instance.name)-\(name)" | #NameType | error(...)` with a guarded hidden `_resourceNameDefaultFits` length assertion, landed by `core-resourcename-default` (enhancement 0019 D16). `#Resource`, `#Trait` and `#Blueprint` are closed definitions with no naming slot. The shapes below are copied from `enhancements/0019/schemas/target.cue` (vetted, with `examples.cue` pinning every case) and were validated by 0019 experiments 09 and 11; this document records only what is specific to landing them in `src/`.

## Goals / Non-Goals

**Goals:**
- Land the exact spellings the experiments validated. Two of them are load-bearing and look interchangeable with spellings that fail silently; the pins file exists so a later "tidy-up" cannot swap one in unnoticed.
- Keep the D16 field mechanism intact: unvalidated default arm, `error()` arm.

**Non-Goals:**
- Declaring any `#nameConstraint` in core. Every declaration is a catalog primitive's (0019 D21); core ships the slot and the assertion only.
- Naming the offending primitive or a remedy in the constraint refusal. Measured impossible on cue v0.17.1 without a false positive on the bare definition (Research & Decisions below).
- Rewriting dots to hyphens anywhere (0019 D20 rejected it).

## Decisions

### `src/types.cue`: two new types beside `#NameType`

```cue
// RFC 1123 DNS subdomain: dot-separated labels, ≤253 runes. The ceiling of an
// explicit #Component.metadata.resourceName. Never the type of anything that
// composes into DNS: a dot in a label position is a different FQDN.
#ObjectNameType: string & =~"^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$" & strings.MinRunes(1) & strings.MaxRunes(253)

// RFC 1035 label: #NameType with an alphabetic first rune. Service
// metadata.name refuses a leading digit at apply; this refuses it at vet.
#ServiceNameType: string & =~"^[a-z]([a-z0-9-]*[a-z0-9])?$" & strings.MinRunes(1) & strings.MaxRunes(63)
```

Helpers by the `core-schema-edit` rule (`*Type`), so untracked; they appear in `src/INDEX.md` through `task generate:index` and in `SPEC.md` §1's type note only.

### `src/resource.cue`, `src/trait.cue`, `src/blueprint.cue`: the slot

```cue
// The name rule a kind this primitive renders enforces on the owning
// component's resourceName; top when the primitive is indifferent. A hidden
// DEFINITION field, deliberately not optional and never guarded: measured on
// cue v0.17.1, `x.#nameConstraint != _|_` is false for a non-concrete value,
// so an optional slot behind a guard silently never propagates. May be
// computed from this primitive's own fields (0019 D23).
#nameConstraint: _
```

Same text in all three, placed after `matchLabels`. Closedness: the three definitions stay closed; a hidden definition field is added inside them, which does not admit any new authored field. Required-field set and defaults unchanged.

### `src/component.cue`: ceiling, collection, assertion

```cue
metadata: {
    resourceName: *"\(#instance.name)-\(name)" | #ObjectNameType | error("resourceName \"\(resourceName)\" is not a DNS subdomain (lowercase alphanumerics, hyphens and dots, 1-253 runes)")
}

// Every attached primitive's constraint, top when none. Collected
// unconditionally: comprehensions, no existence guard.
_nameConstraints: _
for _, r in #resources {_nameConstraints: r.#nameConstraint}
if #traits != _|_ {
    for _, t in #traits {_nameConstraints: t.#nameConstraint}
}
if #blueprints != _|_ {
    for _, b in #blueprints {_nameConstraints: b.#nameConstraint}
}

// The assertion, on the RESOLVED name. The interpolation is load-bearing.
_nameFits: "\(metadata.resourceName)" & _nameConstraints
```

`_resourceNameDefault` and `_resourceNameDefaultFits` are **deleted**: with the ceiling at 253 and both operands `#NameType`, the default is at most 127 runes and the guard has no reachable failure (component-names REMOVED requirement). The `error()` arm and the unvalidated default arm stay exactly as D16 landed them; only the arm's type and message change.

### `src/component_names_pins.cue`: hidden pins for the must-pass matrix

Written to the rules of `platform_and_match_pins.cue` (hidden fields, `_pin: <expr>` then `_pin: <literal>`). Pins: qualified default admitted under a `#ServiceNameType` trait; dotted override admitted with no constraint; 65-rune and 127-rune defaults admitted with no constraint; exact override `istiod` admitted under `#ServiceNameType`; D23-style conditional constraint on a stand-in resource resolving the default `prod-cache`; two constraints composing. Must-fail cases cannot be committed; they are recorded as comments with observed output, as the D16 change did, and re-run by hand in task 2.

## Research & Decisions

### Where the constraint is applied

**Context**: 0019 D21 as ratified on 2026-08-24 unified the conjunction into `metadata.resourceName`; that was validated against a validated-default field, and core landed an unvalidated-default field.
**Explored**: `enhancements/0019/experiments/11-name-constraint-on-landed-d16/` ran the full must-fail/must-pass matrix against six spellings on the landed field.
**Decision**: hidden assertion on the interpolated field (`_nameFits`), never unification into the field. D21 was revised in place on 2026-08-26 to say so.
**Rationale**: unified into the field, a constraint distributes into the default arm; a failing default drops out of the disjunction, the field becomes a bare constraint, and the refusal surfaces as `non-concrete value … in operand to ==` at the D16 guard with the string nowhere, while an override refusal is caught by the `error()` arm whose text mis-describes it. The hidden assertion refuses every case naming the string, the bound and the type site.

### Why the interpolation, and why no `error()` guard

**Context**: two shorter spellings read as equivalent to the chosen one.
**Explored**: same experiment, variants v3 (`metadata.resourceName & _nameConstraints`, no interpolation) and v2/v6 (`if (… & C) == _|_ { _x: error(...) }`).
**Decision**: `"\(metadata.resourceName)" & _nameConstraints` as a plain hidden field.
**Rationale**: without the interpolation the disjunction distributes again and every default-arm failure is **silently admitted** (a non-concrete hidden field raises nothing under `vet -c`). With an `error()` guard, `(incomplete & C) == _|_` is true on the bare `#Component` definition, where `#instance.name` is unresolved, so the guard fires on the definition itself and every consumer refuses; prefixing a concreteness term produces a circular-conditional error on the override path instead. The plain interpolated field is the only spelling that is correct on the definition, on defaults and on overrides. Cost: the diagnostic cannot carry a remedy sentence or the primitive's name; the constraint type's definition site in the trace is the pointer.

### Why the length guard goes rather than moving to 253

**Context**: the 0019 delta first moved `_resourceNameDefaultFits`' bound to 253.
**Explored**: arithmetic on the operands.
**Decision**: delete the guard and its hidden default field.
**Rationale**: `#NameType` caps each operand at 63, so the concatenation is at most 127 runes and can never trip a 253 bound; keeping it would be an assertion that documents a failure that cannot happen. The 64-to-127 range is legal for subdomain kinds and refused for dot-restricted kinds by their primitive's constraint through `_nameFits`.

### `src/module_context.cue`: the projection shape follows the field

`#ComponentNames.resourceName!` moves from `#NameType` to `#ObjectNameType`. Found at verification: the projection is the published shape of `#Module.#ctx.components.<id>`, and a consumer unifying a dotted or 64-plus-rune name through it would have been refused while `#Component` admitted it. Core did not catch this because `module.cue` projects `c.#names` directly; a pin now unifies a dotted override through `#ComponentNames`.

## Risks / Trade-offs

- [Between this release and the catalog sweep, a stateful or exposed component with a 64-to-127-rune default, or an exposed component under a leading-digit instance, vets clean and is refused at apply] → the same window every D15 rename accepts; the sweep is the next slice and declares all four constraints. Nothing that validated before this change is refused by it.
- [A future edit "simplifies" `_nameFits` to the un-interpolated form or wraps it in an `error()` guard] → the doc comment states both refutations, and the pins file's default-under-constraint cases exist so `task vet` catches the guarded form (it fires on the definition); the silent form is caught only by the recorded must-fail re-run in task 2, which is why that task is not optional.
- [Two consumers of `resourceName` pin the old invalid-name message text] → message changes from "DNS label" to "DNS subdomain"; grep `library` fixtures on the dep bump.

## Migration Plan

Lands as one `feat(component)!:` commit on `main` (alpha line), released by release-please. Rollback is a revert; no consumer has declared a `#nameConstraint` until the catalog sweep, so a revert before that sweep is inert downstream.
