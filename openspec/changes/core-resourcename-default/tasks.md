## 1. `src/component.cue` (with its SPEC.md §`#Component` co-update, same commit)

- [x] 1.1 Change `metadata.resourceName` to `*"\(#instance.name)-\(name)" | #NameType` and rewrite its doc comment per design.
- [x] 1.2 Add `_resourceNameDefault` and the guarded `_resourceNameDefaultFits` assertion below `#instance`, per design.
- [x] 1.3 `SPEC.md` §`#Component`: Shape line and hidden fields, Constraints bullet, Rationale bullets (default case rewritten; new "Why the default branch is not unified with `#NameType`").
- [x] 1.4 Diagnostics via `error()`: last arm on `resourceName`, and the value of `_resourceNameDefaultFits` under the `len > 63` guard (design "Diagnostics through the built-in `error()`"); SPEC.md Shape, Constraints and the new Rationale bullet on the V3 trap, same commit.

## 2. Verification against the spec scenarios

- [x] 2.1 Scratch `cue vet -c` cases (not committed) exercising every `component-names` scenario against the real package: default-named, explicit override, explicit equal to default, invalid explicit (single custom message, no default-arm leak), overlong default (diagnostic names the string, its length, the limit and the remedy), overlong escaped by explicit, 63-rune bound accepted; and `#names.dns.*` for the default and overridden cases.
- [x] 2.2 Confirm `#Module.#ctx.components.<id>` projects the new values with no change to `src/module_context.cue`.

## 3. Validation gates

- [x] 3.1 `task check` (fmt check, vet, INDEX freshness, SPEC inventory). `src/INDEX.md` is expected unchanged.
