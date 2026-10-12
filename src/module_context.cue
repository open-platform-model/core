package core

// WHY clusterDomain lives here (not buried inside a runtime context): so a
// single overridable value covers every #Component's FQDN derivation.
// Introduced by enhancement 0001. Was: #ReleaseIdentity (renamed
// in enhancement 0002). SPEC.md § 3.5 Rationale, "Why `clusterDomain` lives
// on `#InstanceIdentity` and not buried inside a runtime context type".

// #InstanceIdentity carries the deployment-scoped facts that compute per-component
// names and DNS variants. Set by #ModuleInstance and propagated into every
// #Component via the parent #Module's pattern constraint on #components.
// See SPEC.md § 3.5.
#InstanceIdentity: {
	name!:         #NameType
	namespace!:    #NameType
	uuid!:         #UUIDType
	clusterDomain: string | *"cluster.local"
}

// WHY #ComponentNames: introduced when the context collapsed to an inline channel with a projected components map (enhancement 0001).

// #ComponentNames is the shape of the per-component computed-names projection.
// The single source of truth lives on each #Component.#names; #Module.#ctx.components
// projects every component's #names into a map keyed by component id.
#ComponentNames: {
	// WHY resourceName: an explicit resourceName may carry dots, so it uses the subdomain type (enhancement 0019).

	// #ObjectNameType, not #NameType: an explicit resourceName may carry dots and
	// run to 253 runes, and this projection must admit whatever
	// #Component.metadata.resourceName admits.
	resourceName!: #ObjectNameType
	dns: {
		short!: string // "<resourceName>"
		local!: string // "<resourceName>.<namespace>"
		fqdn!:  string // "<resourceName>.<namespace>.svc.<clusterDomain>"
	}
}
