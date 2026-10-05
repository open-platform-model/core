## 1. Concept pages and design notes

- [x] 1.1 `docs/site/concepts/who-owns-an-instance.md`: front matter description, enum text (`cli` or `controller`), headings ("A controller-managed instance", "Why the controller adds no finalizer ...", "Why the CLI edits a controller-managed instance ...", "A ModuleInstance with no owner is controller-managed", "`spec.prune` is read by the controller only"), `opm controller install --crds-only`, and every Check-against path.
- [x] 1.2 The other concept pages (`application-and-platform-models.md`, `how-matching-works.md`, `identity-and-names.md`, `modules-and-instances.md`, `platforms-and-catalogs.md`, `versions.md`, `what-enforces-a-rule.md`): product noun, the "controller's API version" heading, `opm controller install`, `GateControllerVersionCeiling`, Check-against paths. Keep the Kubernetes-generic operator comparison in `platforms-and-catalogs.md` and "a platform operator" in `versions.md`.
- [x] 1.3 `docs/adapters.md`: the runtime list and the `#runtimeName` example.
- [x] 1.4 `task docs:bundle:check` green, then commit `docs(concepts): name the controller in the concept pages`.

## 2. Specification, schema comments and repo rules

- [ ] 2.1 `SPEC.md`: the product mentions (render-gate list, `initValues` consumers, the `#CatalogEntry.version` writer, the `#matchers` reader check, the D18 rationale, `#ModuleInstance` definition and ownership-label constraints, the `#Catalog.provides` rationale). Keep "a cluster with no operator" (provider operator) and "Helm operators".
- [ ] 2.2 Comments in `src/platform.cue`, `src/module_instance.cue`, `src/transformer.cue` (`#runtimeName`), `src/pins/identity_pins.cue`. Keep the human "operator upgrading" in `src/transformer.cue` and `src/types.cue`. Run `task generate:index` and review the diff.
- [ ] 2.3 Main specs: edit the `instance-identity` Purpose line in place; the four MODIFIED requirement bodies land at archive.
- [ ] 2.4 `AGENTS.md`, `openspec/config.yaml` (constitution consumer list and the proposal rule) and `.tasks/branch-tag.sh` comment name `opm-controller`.
- [ ] 2.5 `task fmt`, stage, then `task check` green and `openspec validate --all --strict` green, then commit `docs(spec): name the controller in SPEC.md, schema comments and repo rules`.
