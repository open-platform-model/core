## MODIFIED Requirements

### Requirement: The resource name defaults to the instance-qualified name

`#Component.metadata.resourceName` MUST default to `"\(#instance.name)-\(metadata.name)"`. An explicitly authored `resourceName` MUST win over the default and MUST satisfy `#ObjectNameType` (a DNS subdomain: dot-separated labels, 1 to 253 runes). A name any attached primitive's `#nameConstraint` rejects is refused separately (name-constraints); the field's own ceiling does not narrow for it.

#### Scenario: Default-named component

- **WHEN** a component named `web` belongs to an instance named `shop` and sets no `resourceName`
- **THEN** `metadata.resourceName` and `#names.resourceName` are `"shop-web"`

#### Scenario: Explicit resource name wins

- **WHEN** a component named `web` in instance `shop` sets `metadata.resourceName: "storefront"`
- **THEN** `#names.resourceName` is `"storefront"` and the instance name does not appear in it

#### Scenario: Explicit resource name equal to the default

- **WHEN** a component named `web` in instance `shop` sets `metadata.resourceName: "shop-web"`
- **THEN** the component validates and `#names.resourceName` is `"shop-web"`

#### Scenario: Dotted explicit resource name is admitted

- **WHEN** a component sets `metadata.resourceName: "zfs.csi.openebs.io"` and attaches no primitive declaring a `#nameConstraint`
- **THEN** the component validates, `#names.resourceName` is `"zfs.csi.openebs.io"` and the dots reach `#names.dns.*` unchanged

#### Scenario: Invalid explicit resource name is refused

- **WHEN** a component sets `metadata.resourceName: "Bad_Name"`
- **THEN** validation fails at `metadata.resourceName` with a single custom message naming `"Bad_Name"` and the DNS-subdomain rule (lowercase alphanumerics, hyphens and dots, 1-253 runes)
- **AND** the diagnostic does not expose the default arm (no "conflicting values" line mentioning the instance-qualified default)

## REMOVED Requirements

### Requirement: An overlong default refuses the render legibly

**Reason**: The override ceiling is now `#ObjectNameType` (253 runes). Both operands of the default are `#NameType` labels of at most 63 runes, so the concatenation is at most 127 runes and can never exceed the ceiling; the guard has no reachable failure. A default between 64 and 127 runes is a valid object name for every kind that is not dot-restricted, and the dot-restricted kinds now refuse it through their primitive's `#nameConstraint` (name-constraints), which names the string and the 63-rune bound.

**Migration**: None for authors: every input the guard refused is either admitted (a 64-to-127-rune default on a subdomain kind) or refused by the constraint the rendering primitive declares once the catalog sweep ships. Consumers that pinned the guard's diagnostic text drop the pin.

## ADDED Requirements

### Requirement: The default cannot overflow the ceiling

Because `#instance.name` and `metadata.name` are both `#NameType`, the default `resourceName` MUST be at most 127 runes and MUST always satisfy `#ObjectNameType`; core SHALL carry no length guard on the default. A default of 64 or more runes MUST validate unless an attached primitive's `#nameConstraint` narrows it.

#### Scenario: A 65-rune default is admitted

- **WHEN** an instance named with 4 runes holds a component named with 60 runes, no `resourceName` is set, and no attached primitive declares a `#nameConstraint`
- **THEN** the component validates with the 65-rune concatenation as `#names.resourceName`

#### Scenario: A 127-rune default is admitted

- **WHEN** an instance and a component are each named with 63 runes and no `resourceName` is set
- **THEN** the component validates with the 127-rune concatenation as `#names.resourceName`
