## Purpose

Defines how a `#Component` computes its rendered resource name and DNS variants: the `metadata.resourceName` cascade, its instance-qualified default, the explicit override, and the subdomain ceiling on an explicit name. `#names` is the single source of truth every consumer reads; `#Module.#ctx.components` is a projection of it (enhancement 0019, "`metadata.resourceName` defaults to the instance-qualified name, and the flip lands before the sweep").

## Requirements

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

### Requirement: DNS variants follow the resource name

`#names.dns.short` MUST equal `#names.resourceName`; `#names.dns.local` MUST be `"\(resourceName).\(#instance.namespace)"`; `#names.dns.fqdn` MUST be `"\(resourceName).\(#instance.namespace).svc.\(#instance.clusterDomain)"`. The variants MUST NOT carry a second copy of the instance name.

#### Scenario: Default-named service DNS

- **WHEN** component `web` of instance `shop` in namespace `prod` sets no `resourceName` and the cluster domain is the default
- **THEN** `#names.dns.fqdn` is `"shop-web.prod.svc.cluster.local"` and `#names.dns.local` is `"shop-web.prod"`

#### Scenario: Overridden service DNS

- **WHEN** the same component sets `metadata.resourceName: "storefront"`
- **THEN** `#names.dns.fqdn` is `"storefront.prod.svc.cluster.local"`

### Requirement: The default cannot overflow the ceiling

Because `#instance.name` and `metadata.name` are both `#NameType`, the default `resourceName` MUST be at most 127 runes and MUST always satisfy `#ObjectNameType`; core SHALL carry no length guard on the default. A default of 64 or more runes MUST validate unless an attached primitive's `#nameConstraint` narrows it.

#### Scenario: A 65-rune default is admitted

- **WHEN** an instance named with 4 runes holds a component named with 60 runes, no `resourceName` is set, and no attached primitive declares a `#nameConstraint`
- **THEN** the component validates with the 65-rune concatenation as `#names.resourceName`

#### Scenario: A 127-rune default is admitted

- **WHEN** an instance and a component are each named with 63 runes and no `resourceName` is set
- **THEN** the component validates with the 127-rune concatenation as `#names.resourceName`
