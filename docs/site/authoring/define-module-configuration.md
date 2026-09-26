---
title: "Define a module's configuration"
description: "Declare the values users of your module can set, with types, defaults and limits."
type: how-to
sidebar:
  order: 22
---

<!-- One sentence: `#config` declares every value an instance of the module may set, each with a type, limits and usually a default, and components read those values instead of literals. Use it for any field that should differ between instances.
Keep secrets out of this page. Leave at most a note that secrets documentation is pending; do not describe `#Secret` fields.
Check against: core/src/module.cue (#config, debugValues), core/src/module_instance.cue (values), core/SPEC.md section 3.2 (#Module) -->

## Before you begin

<!-- By title: a module with at least one component, as built in "Your first module", and a list of the component fields that should vary between instances.
Check against: opm/docs/site/authoring/your-first-module.md, core/src/module.cue -->

## Steps

1. Declare `#config` in `module.cue`.

   <!-- `#config: {...}` beside `metadata`. Core types it as `_`, so any CUE schema is accepted. Because it is a definition, it is closed: a value for a field `#config` does not declare is refused. Verify the exact message a misspelled field produces under `opm module vet -f`.
   Check against: core/src/module.cue, core/src/module_instance.cue (`#module & {#config: values}`) -->

2. Give each field a type and limits.

   <!-- Types with bounds: `replicas: int & >=1`, `port: int & >0 & <=65535`, an enumeration `serviceType: "ClusterIP" | "NodePort" | "LoadBalancer"`. Reuse catalog schemas for structured values: `res.#Image` (repository, tag and digest; digest may be "" but must be present) and `res.#ResourceRequirementsSchema`. For a constraint repeated across fields, a private helper such as `_#portSchema` outside `#config`.
   Keep `#config` expressible as an OpenAPI v3 schema: no `for`, `if` or comprehensions inside it, because the schema is the module's public contract and non-CUE consumers read it. State this as a rule the author follows. Verify: core/SPEC.md says the library's render pipeline enforces it, but no check exists in library/opm today.
   Check against: cli/templates/standard/module.cue, catalog_opm/opm/resources/v1beta1/container.cue (#Image, #ResourceRequirementsSchema), modules/DESIGN_PATTERNS.md sections 1 and 7, core/SPEC.md section 3.2 (Constraints and Rationale on #config) -->

3. Add a default where a working value exists.

   <!-- `*` marks the default: `replicas: int & >=1 | *1`, `tag: string | *"1.29"`. Defaults belong in `#config`, never written onto component fields: where a blueprint also defaults that field, two differing defaults cancel out, and the field fails at render with an error that names neither author. This is a convention; no tool checks it.
   - If no value works for every user, give the field a type and no default, and an instance that omits it fails at render. Verify the message the reader then sees.
   Check against: core/SPEC.md section 6 (layers L4 and L5), cli/templates/minimal/module.cue -->

4. Mark fields a user may leave out.

   <!-- `publishedServerUrl?: string`, `httpRoute?: {...}`. Guard every use in a component with `if #config.<field> != _|_ {...}`; chain guards for nested optionals (`if #config.resources != _|_ if #config.resources.gpu != _|_`).
   - If an optional block switches a feature on, attach the trait under the same guard: `if #config.httpRoute != _|_ { tr.#HttpRoute }`.
   Check against: modules/DESIGN_PATTERNS.md section 6, opm-modules/jellyfin/module.cue, opm-modules/jellyfin/components.cue -->

5. Read the values from components.

   <!-- `image: #config.image`, `scaling: count: #config.replicas`, `targetPort: #config.port`. Components hold data and references, never their own defaults.
   - If the destination field carries a blueprint default and your `#config` field carries its own default, pass resolved data; for a string, interpolate it: `"\(#config.name)"`. Verify whether any v1beta1 blueprint marks a field default today; none was found in stateless_workload.cue.
   Check against: core/SPEC.md section 6.3 (L5), cli/templates/standard/components.cue -->

6. Write `debugValues`.

   <!-- A concrete value for every `#config` field, optional ones included, so `opm module vet` and `opm module build` exercise every branch. `debugValues` is used only when no `-f` file is given; a `-f` file replaces it rather than layering on it.
   Check against: core/src/module.cue (debugValues), modules/DESIGN_PATTERNS.md section 11, cli/internal/workflow/render/values.go (ResolveModuleValues, DebugValuesSource) -->

## Check that it worked

<!-- Command: `opm module vet` in the module directory.
Success: the line "Values satisfy #config" with detail `debugValues`, then "Module config valid". To check a values file an instance will use: `opm module vet -f prod.cue`; the detail then names the file. A values file may wrap its fields in a top-level `values:`, which is unwrapped on load.
Failure: "values do not satisfy #config" with the position of the offending field in the file.
Check against: cli/internal/cmd/module/vet.go (runVetModuleOnly, validateVetValues, vetValuesDetail), library/opm/kernel/source_loader.go (LoadSourceFromFile) -->

## Related

<!-- By title: the reference entry "Definitions" (the #Module definition) and the concept page "Modules and instances".
Check against: opmodel.dev/site/content/docs/reference/definitions/index.md, core/docs/site/concepts/modules-and-instances.md, core/src/module.cue -->
