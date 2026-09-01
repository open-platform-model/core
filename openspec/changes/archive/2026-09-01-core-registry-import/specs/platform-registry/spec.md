## Purpose

Defines what a `#Platform` declares about the catalogs it admits. A registry entry carries its catalog **by import**: the platform module names the build in its own `cue.mod` the way any CUE module names a dependency, and the entry embeds the imported value whole, deriving its `version` and `#transformers` from it. Covers the shape of an entry, the key-to-import binding, the derived transformer fold, why selection cannot move when the registry does, why two builds of one catalog is two platforms, and why a platform carries no reverse index.

Supersedes the `platform-subscription` capability, which described the same surface when an entry named its build with an inert `version!` scalar (enhancement 0019 D5, D17).

## ADDED Requirements

### Requirement: A registry entry carries its catalog by import

`#CatalogEntry` MUST carry the admitted catalog's value whole on `#catalog: #Catalog`, alongside `enable: bool | *true`. The value MUST be obtained by importing the catalog module in the platform module (the platform module's `cue.mod` names the build); it MUST NOT be assembled inline in the platform file. `#Subscription` MUST NOT exist.

#### Scenario: An entry embedding an imported catalog is accepted

- **WHEN** a platform module imports `opmodel.dev/catalogs/opm@v4` and declares a registry entry with `#catalog: opm` (the imported package value)
- **THEN** the value validates, and the entry's derived fields are readable

#### Scenario: An entry without a catalog is incomplete

- **WHEN** a registry entry declares only `enable: true` and no `#catalog`
- **THEN** evaluation reports the entry incomplete (the derived `version` readout has no source), rather than admitting a catalog-less entry

#### Scenario: The subscription shape is inexpressible

- **WHEN** a platform declares a registry entry with `version!: "1.2.0"` in the removed `#Subscription` form and no `#catalog`
- **THEN** validation fails: `#Subscription` does not exist, and an authored `version` with no embedded catalog cannot satisfy the derived readout

### Requirement: Entry identity is derived, never authored

`#CatalogEntry.version` MUST equal `#catalog.metadata.version` and `#CatalogEntry.#transformers` MUST equal the embedded catalog's `#transformers` map, whole. A caller MAY additionally write an expected `version` on the entry; the written value unifies with the derived readout, so a value that disagrees with the imported bytes MUST fail the build at a path naming the entry. Per-transformer selection MUST NOT be expressible on an entry.

#### Scenario: The version readout reflects the imported bytes

- **WHEN** an entry embeds a catalog whose `metadata.version` is `"4.0.1"`
- **THEN** the entry's `version` evaluates to `"4.0.1"` with nothing authored

#### Scenario: A stamped expected version that disagrees refuses

- **WHEN** an entry embeds a catalog stamped `metadata.version: "4.0.1"` and additionally writes `version: "4.0.2"`
- **THEN** the build fails with a conflict at a path naming that registry entry

#### Scenario: An unstamped catalog refuses as incomplete

- **WHEN** an entry embeds a catalog value whose `metadata.version` is not concrete
- **THEN** evaluation reports an incomplete value naming `metadata.version`, rather than rendering while wrong (`#Catalog.metadata.version!` carries no development default)

### Requirement: The registry key binds to the embedded catalog's module path

`#Platform.#registry`'s pattern constraint MUST unify each entry with `{#catalog: metadata: modulePath: Path}` where `Path` is the entry's map key. An entry keyed at a path whose embedded catalog declares a different `metadata.modulePath` MUST fail the build at a path naming that entry.

#### Scenario: A matching key and import validate

- **WHEN** an entry keyed `"opmodel.dev/catalogs/opm@v4"` embeds a catalog declaring `metadata.modulePath: "opmodel.dev/catalogs/opm@v4"`
- **THEN** the value validates

#### Scenario: Key-versus-import drift is a conflict

- **WHEN** an entry keyed `"opmodel.dev/catalogs/opm@v4"` embeds a catalog declaring `metadata.modulePath: "opmodel.dev/catalogs/other@v1"`
- **THEN** the build fails with a conflict on `metadata.modulePath` at a path naming that entry

### Requirement: Composed transformers are a derived fold over enabled entries

`#Platform.#composedTransformers` MUST be derived: the fold of every enabled entry's `#transformers`, copied member by member per entry (a comprehension). It MUST NOT be optional and no runtime MUST fill it. The fold MUST NOT unify one entry's transformer map into another entry's map. An entry with `enable: false` MUST contribute nothing to the fold while remaining present in the file.

#### Scenario: Enabled entries contribute their transformers

- **WHEN** a platform declares two enabled entries whose catalogs carry disjoint transformer FQNs
- **THEN** `#composedTransformers` contains every FQN from both, each mapped to its catalog's transformer value

#### Scenario: A disabled entry is excluded

- **WHEN** a platform declares an entry with `enable: false`
- **THEN** none of that catalog's transformer FQNs appear in `#composedTransformers`

#### Scenario: A runtime-filled slot is no longer expressible as absent

- **WHEN** a platform declares a `#registry` and nothing else
- **THEN** `#composedTransformers` evaluates from the registry alone, with no runtime step required for it to exist

### Requirement: One registry entry per catalog path

A `#Platform` MUST NOT be able to express two builds of one catalog. CUE map semantics enforce exactly one entry per catalog path, and the platform module's `cue.mod` admits exactly one build per catalog major. Two builds of one catalog is two platforms.

#### Scenario: The map key enforces uniqueness

- **WHEN** a `#Platform` declares two registry entries under the same catalog module path
- **THEN** CUE map semantics collapse them to one key, so two distinct builds of one catalog are not expressible

### Requirement: A platform carries no reverse index

`#Platform` MUST NOT declare `#matchers`. A platform value declaring one MUST be rejected as a field not allowed. Consumers that want a contract-to-transformers index MUST derive it from `#composedTransformers`.

#### Scenario: A declared reverse index is refused

- **WHEN** a platform value declares `#matchers: {...}` in any shape
- **THEN** validation fails with a field-not-allowed error on `#matchers`

### Requirement: Catalog selection is a pure function of committed source

Nothing in the registry shape MUST require a resolution step against a registry at evaluation time to determine which build is selected. The platform module's own `cue.mod` MUST be the sole selector of each entry's catalog build: the declared dependency IS the selected build, prereleases selected by naming them there like any other version, with no lockfile, no maturity inference and no opt-in flag.

#### Scenario: Selection does not move when the registry does

- **WHEN** a platform module's `cue.mod` depends on catalog build `1.2.0` and a newer build `1.3.0` is published
- **THEN** the platform's selection is still `1.2.0`, with no lockfile consulted and no re-resolution performed

#### Scenario: A prerelease build is selected by writing it down

- **WHEN** a platform module's `cue.mod` names catalog build `1.0.0-alpha.2`
- **THEN** the entry's derived `version` reads `"1.0.0-alpha.2"`, with no additional flag required
