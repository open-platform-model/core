## MODIFIED Requirements

### Requirement: core publishes one docs bundle

The repository SHALL declare one docs-kit project, `core`, in `docs-kit.cue`: placed in a site version's `/docs/` tree, owning `reference/definitions/`, versioned from tags with the prefix `v`, built from a `cue-definitions` source over `./src` (files matching `*_pins.cue` skipped) and a `markdown` source over `docs/site`. The bundle SHALL carry the authored pages under `docs/site/` and the generated definitions reference together (docs-kit DESIGN decision 20).

#### Scenario: The bundle holds both kinds of page

- **WHEN** `task docs:bundle` runs on a clean checkout
- **THEN** `out/core/content/` holds `concepts/modules-and-instances.md` (authored) and `reference/definitions/components.md` (generated), and `out/core/manifest.json` names the placement `docs` owning `reference/definitions/`

#### Scenario: A committed generated page that is not excluded collides

- **WHEN** `docs/site/reference/definitions/components.md` is committed and the `markdown` source does not exclude `reference/definitions/`
- **THEN** `task docs:bundle:check` fails, naming the page both sources write

## ADDED Requirements

### Requirement: The bundle tasks build and check without publishing

`task docs:bundle` SHALL build the bundle into `out/core/`. `task docs:bundle:check` SHALL build and lint it without publishing.

#### Scenario: The build task writes the bundle to out/core

- **WHEN** `task docs:bundle` runs
- **THEN** it SHALL build the bundle into `out/core/`

#### Scenario: The check task publishes nothing

- **WHEN** `task docs:bundle:check` runs
- **THEN** it SHALL build and lint the bundle and SHALL NOT publish it

