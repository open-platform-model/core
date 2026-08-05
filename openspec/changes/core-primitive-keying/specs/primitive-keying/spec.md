## ADDED Requirements

### Requirement: A contract key and an implementation key are distinct types

`core` MUST provide `#ContractFQNType` — `path/name@vN` where `vN` matches `#APIVersionType` — and `#ImplFQNType` — `path/name@<semver>`, the form carried before this change. `#FQNType` MUST be their disjunction, for the map shapes that hold both.

#### Scenario: A contract key is accepted in the contract form

- **WHEN** a value is `"opmodel.dev/catalogs/opm/traits/scaling@v1beta1"`
- **THEN** it validates against `#ContractFQNType`

#### Scenario: An implementation key is accepted in the build form

- **WHEN** a value is `"opmodel.dev/catalogs/opm/transformers/configmap-transformer@1.2.0"`
- **THEN** it validates against `#ImplFQNType`

#### Scenario: A build-shaped key is refused where a contract key is required

- **WHEN** `#Resource.metadata.fqn` is `"opmodel.dev/catalogs/opm/resources/backup@1.1.0"`
- **THEN** validation fails against `#ContractFQNType`

#### Scenario: A contract-shaped key is refused where an implementation key is required

- **WHEN** `#ComponentTransformer.metadata.fqn` is `"opmodel.dev/catalogs/opm/transformers/backup-transformer@v1"`
- **THEN** validation fails against `#ImplFQNType`

### Requirement: A contract key carries an API version following the Kubernetes ladder

`core` MUST provide `#APIVersionType` admitting exactly `vNalphaM`, `vNbetaM` and `vN`. `#MajorVersionType` MUST be left unchanged and MUST continue to type module majors.

#### Scenario: The three ladder forms are accepted

- **WHEN** a value is `"v1alpha1"`, `"v1beta2"` or `"v2"`
- **THEN** each validates against `#APIVersionType`

#### Scenario: A SemVer is refused as an API version

- **WHEN** a value is `"1.2.0"` or `"v1.2"`
- **THEN** validation fails against `#APIVersionType`

### Requirement: The additive-only promise is readable off the API version

`core` MUST provide `#APIVersionGated`, which takes an `apiVersion!` and reports `gated` — false at alpha, true at beta and GA. It MUST NOT introduce any ordering between levels.

#### Scenario: Alpha is ungated

- **WHEN** `#APIVersionGated` is unified with `apiVersion: "v1alpha1"`
- **THEN** `gated` is `false`

#### Scenario: Beta and GA are gated

- **WHEN** `#APIVersionGated` is unified with `apiVersion: "v1beta1"`, and separately with `apiVersion: "v1"`
- **THEN** `gated` is `true` in both cases

### Requirement: The three primitives declare an API version; the adapter does not

`#Resource`, `#Trait` and `#Blueprint` MUST each carry a required `metadata.apiVersion` typed `#APIVersionType`. `#ComponentTransformer` MUST NOT carry the field, and its identity shape MUST be closed so that supplying one is refused rather than silently ignored.

#### Scenario: A primitive without an API version is refused

- **WHEN** a `#Resource` is evaluated with `metadata.apiVersion` unset
- **THEN** evaluation reports the required field as missing

#### Scenario: An API version on a transformer is inexpressible

- **WHEN** a `#ComponentTransformer` declares `metadata.apiVersion: "v1"`
- **THEN** validation fails with a field-not-allowed error, not a silent accept

### Requirement: The build a definition shipped in is named `catalogVersion`

All four catalog member kinds MUST carry `metadata.catalogVersion` typed `#VersionType`, replacing `metadata.version`. It MUST be provenance only: it MUST NOT appear in a contract key, and it MUST appear in an implementation key.

#### Scenario: A primitive records its build without keying on it

- **WHEN** a `#Resource` declares `apiVersion: "v1beta1"` and `catalogVersion: "1.2.0"`
- **THEN** its `metadata.fqn` ends `@v1beta1`, and `catalogVersion` is readable as `"1.2.0"`

#### Scenario: A transformer keys on its build

- **WHEN** a `#ComponentTransformer` declares `catalogVersion: "1.2.0"`
- **THEN** its `metadata.fqn` ends `@1.2.0`

#### Scenario: The old field name is gone

- **WHEN** any of the four kinds is evaluated
- **THEN** `metadata.version` does not exist

### Requirement: A catalog member's FQN is authored, not derived

`core` MUST NOT derive `metadata.fqn` for any of the four kinds. The field MUST be declared with its type and left for the catalog to author from its identity package.

The correctness of an authored value is **not** checked by `core`. It is checked by `#CatalogMemberFQNGate` at publish, which ships separately.

#### Scenario: An authored FQN is accepted as written

- **WHEN** a `#Resource` declares `fqn: "opmodel.dev/catalogs/opm/resources/backup@v1beta1"` and `name: "backup"`
- **THEN** the value validates, with no derivation from `modulePath`, `name` or `apiVersion`

#### Scenario: An FQN disagreeing with the primitive's own fields is not refused by `core`

- **WHEN** a `#Resource` declares `name: "backup"` and `fqn: "opmodel.dev/catalogs/opm/resources/restore@v1beta1"`
- **THEN** the value validates against `core`, because the agreement is a publish-time gate rather than a schema constraint

### Requirement: A contract key retains its kind segment

An authored contract FQN MUST include the kind segment — `/resources`, `/traits`, `/blueprints`, `/transformers` — so that two members of different kinds sharing a name do not collide.

#### Scenario: A resource and a trait sharing a name occupy distinct keys

- **WHEN** a catalog ships a resource and a trait both named `backup` at `v1beta1`
- **THEN** their FQNs differ by the kind segment and are not equal

### Requirement: The primitive and adapter identity shapes have no shared parent

`core` MUST carry two independent identity shapes: one for the three primitives narrowing `fqn` to `#ContractFQNType`, and one for `#ComponentTransformer` narrowing `fqn` to `#ImplFQNType`. No shared parent definition MUST span the two.

#### Scenario: A field added to the primitive shape does not reach transformers

- **WHEN** a field is added to the primitive identity shape
- **THEN** `#ComponentTransformer` does not acquire it, and no manual exclusion is required to keep it off

### Requirement: `#definitionName` is removed from `#ComponentTransformer`

`#ComponentTransformer.metadata.#definitionName` MUST be deleted. It MUST be retained on `#Resource`, `#Trait` and `#Blueprint`, where each builds its `spec!` field key from it.

#### Scenario: The transformer's unread projection is gone

- **WHEN** a `#ComponentTransformer` value is evaluated
- **THEN** `metadata.#definitionName` does not exist

#### Scenario: The primitive projections survive

- **WHEN** a `#Resource` declares `name: "config-maps"`
- **THEN** `metadata.#definitionName` is `"ConfigMaps"` and the `spec!` key derived from it is unchanged

### Requirement: `#Blueprint` is classified as a primitive

`SPEC.md`'s category lines MUST list `#Blueprint` among the primitives rather than the constructs. It MUST carry `apiVersion` and a contract key on that basis.

`#Blueprint` MUST NOT gain a `fulfilment` field: a transformer declares `requiredResources` and `requiredTraits` and has no blueprint equivalent, so the field would be unreachable.

#### Scenario: A blueprint carries a contract key

- **WHEN** a `#Blueprint` declares `apiVersion: "v1beta1"`
- **THEN** its `metadata.fqn` validates against `#ContractFQNType`
