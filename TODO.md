# TODO

## Nearterm

- [ ] Figure out a better solution to "..." in Element base, etc. It needs to be typed but also allow for extending with fields. Maybe components are allowed to be loosy goosy but Elements are stricter
- [ ] Investigate and fix the reason why "containers" is not balooned to #ContainerSpec when evaluating #WorkloadSchema "clear && cue eval catalog/traits/core/v2alpha2/workload/workload.cue -e "#WorkloadSchema" --all".
- [ ] Implement standard status definition for component.
- [ ] Implement standard status definition for module, should inherit from components in some way.
- [ ] Create a CLI helper tool. Responsible for bootstrapping a CUE module with an example, or for listing and viewing traits, components, modules, scopes, policies and bundles. Would also be able to handle deployment of the generated resources.
- [ ] Find a better way to handle secrets. Maybe a way to generate. Maybe a way to inform the platform team of what the secrets should be and how they should look (an informed handoff).
- [ ] Decide if ports should be a set or continue as a list. Pros of set is it would be easier to reference.

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
