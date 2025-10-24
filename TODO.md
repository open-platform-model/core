# TODO

## Nearterm

- [ ] Add deteremistic UUID to all components and module definitions.
- [ ] Go through all "Specs" and add sane default to relevant values.
  - **Status**: PARTIALLY COMPLETE - Some defaults exist (e.g., `Replicas.count: int | *1`, `Container.protocol: *"TCP"`), needs comprehensive review
- [ ] Refactor how Modifier elements points out what primitive elements they are compatible with.
  - **Status**: PARTIALLY COMPLETE - `modifies: []` field exists, `matchLabels` added for label-based matching, but needs improvement
- [x] ~~Investigate in replacing workloadType with "hints" or "annotations" in element. Would function similarly to labels in #Element but would NOT be used for categorization or filtering. Would have workloadType, and could be expanded in the future with more fields.~~
  - **Completed 2025-10-02**: Implemented annotations system
  - Replaced `workloadType?: #WorkloadTypes` field with `annotations?: [string]: string` map
  - Workload type now specified via `"core.opm.dev/workload-type"` annotation
  - Components derive and validate workloadType from element annotations
  - Clear separation: `labels` for categorization (OPM-level), `annotations` for behavior hints (provider-level)
  - Kubernetes-aligned pattern for extensibility
- [ ] Add a new element kind called patch. Would work similar to how patches are handled in for example kustomize today.
- [ ] Figure out a better solution to "..." in Element base, etc. It needs to be typed but also allow for extending with fields. Maybe components are allowed to be loosy goosy but Elements are stricter
- [ ] Implement standard status definition for component.
- [x] ~~Implement standard status definition for module, should inherit from components in some way.~~
  - **Completed**: Module status implemented in `module.cue`
  - `#ModuleDefinition.#status`: Has `componentCount` and `scopeCount` fields
  - `#Module.#status`: Extended with `#allComponents` aggregation and counts
  - Note: Component-level status still pending (see above)
- [ ] Find a better way to handle secrets. Maybe a way to generate. Maybe a way to inform the platform team of what the secrets should be and how they should look (an informed handoff).

## Future

- [ ] Support the [OSCAL](https://pages.nist.gov/OSCAL/) model
- [ ] Ability to bundle several Modules into a Bundle, that can be deployed as a whole into a platform. Support scopes in bundles.
- [ ] Ability to write workflows/pipelines. Tasks that execute in series, either in combination with Modules and Components or completely separately.
- [ ] Implmement a runtime query system. The ability to query the platform for extra "not required" data. This data can help in generation but is not required for CUE-OAM to function.

## Research

- Figure out how to handle the addition of new traits for when the project is in wide use. Should not be required on a regular basic once the API is stable.
- Figure out how to handle deprecation of traits.
- Also investiage adding a trait/component/module dependencies. Meaning a trait in a component can have a dependency that is external to the module, it would also be installed alongside the module.
- How do a platform team curate a catalog of modules, and is able to enforce certain policies on the end-user consuming the modules?
- Investigate how an integration with OPA could be used for policies. The ability to define polices in rego and have that be a part of a ModuleDefinition and Module.
- Investigate how to add queries to a module, meaning when the module is deployed it can pull data from the target environment. For example metadata about the environment.
- Every component requires a unique identity (SPIFFE/SPIRE) so that it can be utilized to grab secrets accesible to the component
