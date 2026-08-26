## Purpose

Defines the three name types that transcribe the Kubernetes API server's name validators, and how a primitive declares the name rule a kind it renders enforces so that `#Component` refuses a violating `resourceName` at authoring time instead of the server refusing it at apply (enhancement 0019 D20, D21, D23).

## ADDED Requirements

### Requirement: Three name types mirror the server's validators

Core SHALL provide `#NameType` (RFC 1123 DNS label: lowercase alphanumerics and hyphens, 1 to 63 runes, unchanged), `#ObjectNameType` (RFC 1123 DNS subdomain: dot-separated labels, 1 to 253 runes) and `#ServiceNameType` (RFC 1035 label: as `#NameType` but the first rune MUST be alphabetic). Core SHALL NOT provide a length-only name type.

#### Scenario: Subdomain admits dots and 253 runes

- **WHEN** a value `zfs.csi.openebs.io` or a 253-rune dotted string is unified with `#ObjectNameType`
- **THEN** it validates

#### Scenario: Subdomain refuses 254 runes

- **WHEN** a 254-rune value is unified with `#ObjectNameType`
- **THEN** validation fails naming the value and `strings.MaxRunes(253)`

#### Scenario: Service name refuses a leading digit

- **WHEN** `1prod-web` is unified with `#ServiceNameType`
- **THEN** validation fails naming the value and the DNS-1035 pattern
- **AND** the same value unified with `#NameType` validates

### Requirement: A primitive declares its name constraint on a hidden slot

`#Resource`, `#Trait` and `#Blueprint` SHALL each carry a hidden definition field `#nameConstraint` whose default is top. The slot SHALL NOT be optional and a consumer SHALL NOT guard on its presence. A primitive MAY set the slot to a type, or compute it from its own fields so that the constraint follows the primitive's own configuration. A primitive that declares nothing SHALL impose no constraint.

#### Scenario: Constant constraint

- **WHEN** a trait declares `#nameConstraint: #ServiceNameType`
- **THEN** every component that attaches it is subject to `#ServiceNameType` on its resolved `resourceName`

#### Scenario: Conditional constraint computed from the primitive's own key

- **WHEN** a resource declares `#nameConstraint` as `#NameType` when its own `workload-type` matching key reads `stateful` and top otherwise
- **THEN** a component whose entry answers `stateful` is subject to `#NameType`, and one whose entry answers `stateless` is subject to nothing

#### Scenario: Indifferent primitive costs nothing

- **WHEN** a component attaches only primitives that declare no constraint
- **THEN** any `resourceName` `#ObjectNameType` admits validates

### Requirement: The component asserts the resolved name against every attached constraint

`#Component` SHALL collect the `#nameConstraint` of every attached resource, trait and blueprint into one conjunction, unconditionally, and SHALL assert the resolved `metadata.resourceName` (the default or the explicit override, as a string) against that conjunction on a hidden field. The conjunction SHALL NOT be unified into `metadata.resourceName` itself, so the field's own default, override and refusal behaviour (component-names) is unchanged. Two constraints SHALL compose by unification with no precedence rule.

#### Scenario: Default name admitted by a constraint

- **WHEN** component `web` of instance `shop` attaches a trait declaring `#ServiceNameType` and sets no `resourceName`
- **THEN** the component validates and `#names.resourceName` is `shop-web`

#### Scenario: Override refused by a constraint

- **WHEN** the same component sets `metadata.resourceName: "web.internal"`
- **THEN** validation fails on the assertion naming `"web.internal"` and the DNS-1035 pattern, at the type's definition site

#### Scenario: Default refused by a constraint

- **WHEN** component `web` of instance `1prod` attaches a trait declaring `#ServiceNameType` and sets no `resourceName`
- **THEN** validation fails on the assertion naming `"1prod-web"` and the DNS-1035 pattern
- **AND** the failure is not a bare `incomplete value` or `non-concrete value` diagnostic

#### Scenario: Overlong default refused by a length-bearing constraint

- **WHEN** a component attaches a resource whose conditional constraint reads `#NameType` and its default `resourceName` is 65 runes
- **THEN** validation fails on the assertion naming the 65-rune string and `strings.MaxRunes(63)`

#### Scenario: Two constraints compose

- **WHEN** a component attaches a trait declaring `#ServiceNameType` and a blueprint declaring `#NameType`
- **THEN** its `resourceName` MUST satisfy both, and a default of the form `<label>-<label>` with an alphabetic lead validates

#### Scenario: Override that satisfies the constraint is admitted

- **WHEN** a component with an attached `#ServiceNameType` constraint sets `metadata.resourceName: "istiod"`
- **THEN** the component validates and `#names.dns.fqdn` is `istiod.<namespace>.svc.<clusterDomain>`
