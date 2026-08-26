## 1. `src/types.cue` (with its `SPEC.md` §1 type note, same commit)

- [x] 1.1 Add `#ObjectNameType` and `#ServiceNameType` beside `#NameType` with the doc comments from design; `#NameType` unchanged.
- [x] 1.2 `SPEC.md` §1: one paragraph naming the three name types and which rule each transcribes (label for DNS composition and the default, subdomain for the override ceiling, DNS-1035 for Service).

## 2. `src/resource.cue`, `src/trait.cue`, `src/blueprint.cue` (with `SPEC.md` §2.1, §2.2, §3.3, same commit)

- [x] 2.1 Add the hidden `#nameConstraint: _` slot after `matchLabels` in all three, with the design's doc comment (top default, never optional, never guarded, may be computed from the primitive's own fields).
- [x] 2.2 `SPEC.md` §2.1, §2.2, §3.3: Shape line, one Constraints bullet (MUST be top by default; a consumer MUST NOT guard on presence), one Rationale bullet ("Why the primitive declares the name rule") in §2.1 with §2.2/§3.3 pointing at it.

## 3. `src/component.cue` (with `SPEC.md` §3.1, same commit)

- [x] 3.1 Widen `resourceName`'s override arm to `#ObjectNameType` and its `error()` message to the subdomain rule; rewrite the doc comment for D20 (default structurally dotless, override may carry dots).
- [x] 3.2 Delete `_resourceNameDefault` and `_resourceNameDefaultFits` and their comment (unreachable under the 253 ceiling, design "Why the length guard goes").
- [x] 3.3 Add `_nameConstraints` (three unconditional comprehensions) and `_nameFits: "\(metadata.resourceName)" & _nameConstraints` with the doc comment recording both refuted spellings, per design.
- [x] 3.4 `SPEC.md` §3.1: Shape (arm, hidden fields), Constraints (ceiling; collection and assertion; the two MUST NOTs on spelling), Rationale (rewrite "Why the default branch is not unified", drop the overlong-default bullets, add "Why a hidden assertion rather than the field's type" and "Why no length guard").

- [x] 3.5 `src/module_context.cue`: `#ComponentNames.resourceName` widens to `#ObjectNameType` (found at verify: the projection shape was narrower than the field it projects); pinned by unifying a dotted-override `#names` through it.
- [x] 3.6 `docs/primitives.md` structure blocks gain the `#nameConstraint` slot plus a prose paragraph; `docs/constructs.md` `#Component` block gains the `resourceName` cascade and `#names`.

## 4. `src/component_names_pins.cue` (new; pins only, no SPEC impact of its own)

- [x] 4.1 Stand-in primitives: a `#Trait` declaring `#ServiceNameType`, a `#Blueprint` declaring `#NameType`, a `#Resource` with the D23 list-index conditional on its own `workload-type` key, an indifferent `#Resource`.
- [x] 4.2 Pin the must-pass matrix from design (qualified default under the trait; dotted override with no constraint; 65- and 127-rune defaults with no constraint; exact `istiod` override under the trait; conditional resolving `prod-cache`; two constraints composing), each `_pin: <expr>` then `_pin: <literal>`.
- [x] 4.3 Record the must-fail cases as comments with the observed cue v0.17.1 output (dotted override + trait; leading-digit instance + trait; stateful + dotted override; 65-rune stateful default; 254-rune override; `Bad_Name`).

## 5. Verification against the spec scenarios

- [x] 5.1 Scratch `cue vet -c` (not committed) running every `name-constraints` and `component-names` scenario, including each must-fail from 4.3, against the real package; confirm each refusal names the string and the bound and that no must-fail vets clean.
- [x] 5.2 Confirm the bare `#Component` definition and `#Module` vet clean with no component attached (the guarded-`error()` failure mode), and that `#Module.#ctx.components.<id>` projects a dotted override unchanged.

## 6. Generated artifacts and validation gates

- [x] 6.1 `task generate:index` (two new top-level definitions) and review the extracted doc comments. The hand-maintained tree in `src/INDEX.md` is a stub listing only `docs/`, so no entry to add.
- [x] 6.2 `task vet`, `task generate:index:check`, `task spec:check` pass; `task fmt:check` is `git diff --exit-code` on `src/*.cue` and passes only once the edits are committed (`cue fmt` itself is clean).
