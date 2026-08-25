## Purpose

Defines how a `#Component` computes its rendered resource name and DNS variants: the `metadata.resourceName` cascade, its instance-qualified default, the explicit override, and the refusal of a default that would not fit a DNS label. `#names` is the single source of truth every consumer reads; `#Module.#ctx.components` is a projection of it (enhancement 0019 D16).

## Requirements

### Requirement: The resource name defaults to the instance-qualified name

`#Component.metadata.resourceName` MUST default to `"\(#instance.name)-\(metadata.name)"`. An explicitly authored `resourceName` MUST win over the default and MUST satisfy `#NameType`.

#### Scenario: Default-named component

- **WHEN** a component named `web` belongs to an instance named `shop` and sets no `resourceName`
- **THEN** `metadata.resourceName` and `#names.resourceName` are `"shop-web"`

#### Scenario: Explicit resource name wins

- **WHEN** a component named `web` in instance `shop` sets `metadata.resourceName: "storefront"`
- **THEN** `#names.resourceName` is `"storefront"` and the instance name does not appear in it

#### Scenario: Explicit resource name equal to the default

- **WHEN** a component named `web` in instance `shop` sets `metadata.resourceName: "shop-web"`
- **THEN** the component validates and `#names.resourceName` is `"shop-web"`

#### Scenario: Invalid explicit resource name is refused

- **WHEN** a component sets `metadata.resourceName: "Bad_Name"`
- **THEN** validation fails at `metadata.resourceName` with a single custom message naming `"Bad_Name"` and the DNS-label rule (lowercase alphanumerics and hyphens, 1-63 runes)
- **AND** the diagnostic does not expose the default arm (no "conflicting values" line mentioning the instance-qualified default)

### Requirement: DNS variants follow the resource name

`#names.dns.short` MUST equal `#names.resourceName`; `#names.dns.local` MUST be `"\(resourceName).\(#instance.namespace)"`; `#names.dns.fqdn` MUST be `"\(resourceName).\(#instance.namespace).svc.\(#instance.clusterDomain)"`. The variants MUST NOT carry a second copy of the instance name.

#### Scenario: Default-named service DNS

- **WHEN** component `web` of instance `shop` in namespace `prod` sets no `resourceName` and the cluster domain is the default
- **THEN** `#names.dns.fqdn` is `"shop-web.prod.svc.cluster.local"` and `#names.dns.local` is `"shop-web.prod"`

#### Scenario: Overridden service DNS

- **WHEN** the same component sets `metadata.resourceName: "storefront"`
- **THEN** `#names.dns.fqdn` is `"storefront.prod.svc.cluster.local"`

### Requirement: An overlong default refuses the render legibly

When no `resourceName` is authored and `"\(#instance.name)-\(metadata.name)"` exceeds 63 runes, the component MUST fail validation, and the diagnostic MUST name the offending concatenated string, its length in runes, the 63-rune limit, and the remedy (shorten the instance or component name, or set `metadata.resourceName`). An explicit `resourceName` MUST NOT be subject to that check.

#### Scenario: Overlong default is refused with the string in the diagnostic

- **WHEN** an instance named with 40 runes holds a component named with 30 runes and no `resourceName`
- **THEN** validation fails with a diagnostic containing the 71-rune concatenation, `71 runes`, `63-rune` and `set metadata.resourceName explicitly`
- **AND** the diagnostic is not a bare `incomplete value` naming only `#NameType`'s constraints

#### Scenario: Overlong default escaped by an explicit name

- **WHEN** the same instance and component set `metadata.resourceName: "short"`
- **THEN** the component validates and `#names.resourceName` is `"short"`

#### Scenario: Names at the bound are accepted

- **WHEN** the instance name and component name total 62 runes (63 with the hyphen)
- **THEN** the component validates with the concatenation as `#names.resourceName`
