## MODIFIED Requirements

### Requirement: The component asserts the resolved name against every attached constraint

`#Component` SHALL conjoin the `#nameConstraint` of every attached resource, trait and blueprint unconditionally, and SHALL assert the resolved `metadata.resourceName` (the default or the explicit override, as a string) against it on a hidden field. The conjunction SHALL NOT be unified into `metadata.resourceName` itself, so that field's own default, override and refusal behaviour (component-names) is unchanged. Two constraints SHALL compose by unification with no precedence rule.

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

