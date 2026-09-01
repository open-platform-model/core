package core

// WHY an import instead of a version string: a version string is inert data
// nothing in a CUE build resolves, so the kernel pulled the build out of band
// and handed the result back on a materialized twin. The entry carries the
// catalog itself, resolved through the platform module's cue.mod like every
// other dependency, which is what lets one render build evaluate the
// instance, the platform and the catalog together (enhancement 0019 D5, D9).
// Catalog selection stays a pure function of committed source (0010 D14):
// cue.mod is committed source, and a prerelease is still selected by naming
// it there. SPEC.md § 3.4 Rationale, "Why an import instead of a version
// string", "Why the version is derived and not authored" and "Why the whole
// transformer map".

// #CatalogEntry declares that a #Platform admits a catalog, by carrying the
// imported catalog value whole on #catalog. `version` and `#transformers`
// are derived readouts, never authored; an expected `version` stamped at
// platform-generation time unifies with the readout, so wrong bytes are a
// build conflict naming the entry (0019 D13). One entry per catalog path;
// two builds of one catalog is two platforms. See SPEC.md § 3.4.
#CatalogEntry: {
	enable: bool | *true

	// The imported catalog, embedded whole.
	#catalog: #Catalog

	// Derived readouts of the catalog's release-stamped identity. Neither
	// is authored; #Catalog.metadata.version! has no development default,
	// so an unstamped catalog refuses as incomplete rather than rendering
	// wrong. A generation-time expected `version` stamp unifies with the
	// readout (0019 D13 tripwire).
	version:       #catalog.metadata.version
	#transformers: #TransformerMap & #catalog.#transformers
}

// WHY the fold copies per entry rather than unifying entry maps: the
// catalog's provenance stamp (0010 D25) refuses a foreign transformer
// unified into another catalog's member map, so map-level unification fails
// on healthy multi-catalog input (measured,
// enhancements/0019/experiments/05-match-in-one-build). Two entries writing
// one composed FQN still unify at that key: agreement collapses, divergent
// bodies conflict loudly. #matchers is removed (0019 D17): its only reader
// was the Go matcher the render-path collapse deletes, and the in-build
// matching glue folds its own buckets from #composedTransformers in a shape
// core's list-valued buckets never matched. SPEC.md § 3.4 Rationale, "Why
// the key binding is structural rather than a check", "Why the fold copies
// rather than unifies" and "Why #matchers is removed rather than derived".

// A #Platform is a path-keyed registry of catalog entries, each carrying its
// imported catalog, plus the derived #composedTransformers fold over the
// enabled entries. A platform value is complete on its own: no Materialize
// step, no materialized twin, no reverse index. See SPEC.md § 3.4.
#Platform: {
	kind: "Platform"

	metadata: {
		name!:        #NameType
		description?: string
		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// Informational. Future enhancement may enforce type-vs-transformer
	// compatibility; today it is an authored discriminator the matcher
	// does not consult (014 OQ2).
	type!: string

	// Path-keyed: the map key is the catalog's CUE module path, bound into
	// the embedded catalog's metadata.modulePath, so key-versus-import
	// drift is a build conflict naming the entry (0019 D5). Exactly one
	// entry per path; CUE map semantics enforce uniqueness (0010 D13).
	#registry: [Path=#ModulePathType]: #CatalogEntry & {#catalog: metadata: modulePath: Path}

	// Derived, never runtime-filled: the fold of every enabled entry's
	// #transformers, copied per entry by comprehension (see the WHY block
	// above). Empty when the registry is empty or fully disabled.
	#composedTransformers: {
		for _, entry in #registry if entry.enable {
			for fqn, tf in entry.#transformers {(fqn): tf}
		}
	}
}
