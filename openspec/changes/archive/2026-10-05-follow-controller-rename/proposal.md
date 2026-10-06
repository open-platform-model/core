## Why

The Kubernetes controller `opm-operator` is renamed `opm-controller`: the repo, the Go module, the image, the namespace `opm-controller-system`, the CLI noun `opm controller`, the docs section `/docs/reference/controller/`, and `spec.owner: controller` in place of `operator`, with no alias and no migration. "Operator" in the Kubernetes sense names a controller carrying app-specific day-2 knowledge; OPM's is a generic delivery engine. In the new vocabulary "the controller" is the product and its per-kind loops are "reconcilers". The rename is recorded in the controller repo's ADR-019 and in enhancement 0032 (The operator becomes the controller), which amends 0006.

core names the product in prose only: the concept pages it ships to opmodel.dev, `SPEC.md`, four main specs, doc comments in `src/*.cue`, its own `AGENTS.md` and `openspec/config.yaml`, and one script comment. Left alone, those pages would tell a reader to run `opm operator install`, to set `spec.owner: operator` (which the CRD now refuses), and would cite source paths under `opm-operator/` that no longer exist.

## What Changes

- The concept pages under `docs/site/concepts/` name "the controller", `opm controller install`, `spec.owner: controller`, "controller-managed", and cite `opm-controller/...`, `cli/internal/controller/...` and `cli/internal/cmd/controller/...` in their Check-against lines. Headings move with them (`A controller-managed instance`); nothing links to the old anchors.
- `docs/adapters.md`, `SPEC.md`, `AGENTS.md`, `openspec/config.yaml` and `.tasks/branch-tag.sh` say "controller" or `opm-controller` where they meant the product.
- `src/*.cue` doc comments and WHY blocks that name the product say "controller". Comment text only: no field, constraint, default or closedness moves, so the evaluated schema is identical. The CI co-update gate is already satisfied because `SPEC.md` changes in the same PR; a `Spec-Impact: none` line in the PR body is optional.
- Four main-spec requirement bodies (`contract-fulfilment`, `instance-identity`, `platform-contract-inventory`, `release-cascade`) are MODIFIED with the new name; no requirement or scenario title carries the word, so nothing is retitled. The `instance-identity` Purpose line is edited in place.
- Kept as written: `CHANGELOG.md` and `openspec/changes/archive/**` (history), the human "platform operator" and "an operator upgrading a catalog", Kubernetes-generic "operators installed in a cluster", and "Helm operators".
- Not here: `.tasks/cascade/wiring-check.sh` names `opm-operator` twice, but it is a byte-identical copy of the `.github` wiring script whose hash the pin round checks, so it moves only with the `.github` pin round that retires the old repo name.

## Release class

No release of its own: `docs:` commits only. The schema is semantically byte-identical; the doc-comment text rides the next core release (and with it the regenerated definitions reference). No break, no use of the beta break licence, no `catalogs/opm` impact.

## Downstream consumers

`library`, `cli`, `opm-controller`, the catalogs and `modules` need nothing: no definition changes. opmodel.dev picks up the concept pages from the next core docs bundle; its own links to the controller pages move in its own change. The cited source paths are correct once the controller repo rename and the cli `opm controller` command have merged, so this change merges after both.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `contract-fulfilment`: body text of "A provider-fulfilled contract admits exactly one provider".
- `instance-identity`: body text of "Instance identity survives every upgrade of the module it deploys".
- `platform-contract-inventory`: body text of "Discriminated is true exactly when no pair is comparable".
- `release-cascade`: scenario text of "A published core release notifies its cascade downstreams".

## Impact

Prose in `docs/site/concepts/*.md`, `docs/adapters.md`, `SPEC.md`, `AGENTS.md`, `openspec/config.yaml`, `.tasks/branch-tag.sh`, `openspec/specs/{contract-fulfilment,instance-identity,platform-contract-inventory,release-cascade}/spec.md`; comments in `src/platform.cue`, `src/module_instance.cue`, `src/transformer.cue`, `src/pins/identity_pins.cue`; regenerated `src/INDEX.md` if a doc comment it extracts moves.
