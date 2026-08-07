package core

import (
	"strings"
)

// #Resource: Defines a resource of deployment within the system.
// Resources represent deployable components, services or resources that can be instantiated and managed independently.
#Resource: {
	kind: "Resource"

	metadata: {
		name!: #NameType // Example: "container"
		#definitionName: (#KebabToPascal & {"in": name}).out

		modulePath!: #PackagePathType // Example: "opmodel.dev/catalogs/opm/resources"

		// apiVersion: this contract's own level, and the only component of its
		// key (enhancement 0010 D4). Moved when this resource's shape breaks —
		// a catalog release does not move it, which is what lets a module's
		// demand survive one.
		//
		// It is the one identity value on a primitive that is NOT derivable
		// from its catalog's identity package: it is a judgement the author
		// makes, which is why it is a field rather than an interpolation.
		apiVersion!: #APIVersionType // Example: "v1beta1"

		// catalogVersion: the catalog build this definition shipped in.
		// Provenance only (D25) — no contract key interpolates it. It is what
		// lets a diagnostic say "this platform's provider was built against
		// 1.0.0; this module needs 1.3.0" when the shapes are compatible but
		// the provider lags.
		catalogVersion!: #VersionType // Example: "1.0.0"

		// fqn: AUTHORED by the catalog at the definition site, not derived here
		// (enhancement 0010 D21). The catalog interpolates it from its own
		// identity package, so fqn, modulePath and catalogVersion all trace to
		// one source and a release moves them together.
		//
		// `core` therefore no longer refuses a value disagreeing with this
		// definition's own name or path. Enforcement MOVES rather than
		// disappearing: #CatalogMemberFQNGate asserts the agreement at publish.
		fqn!: #ContractFQNType // Example: "opmodel.dev/catalogs/opm/resources/container@v1beta1"

		// Human-readable description of the definition
		description?: string

		// Optional metadata labels for CATEGORIZATION. Descriptive only —
		// nothing selects on these, and they are never unified upward into a
		// #Component. Matching lives in matchLabels below (enhancement 0010
		// D36).
		// Example: {"resource.opmodel.dev/category": "workload"}
		labels?: #LabelsAnnotationsType

		// Optional metadata annotations for definition behavior hints (not used for categorization)
		// Annotations provide additional metadata but are not used for selection
		annotations?: #LabelsAnnotationsType
	}

	// matchLabels: this resource's MATCHING identity — the keys a
	// #ComponentTransformer.requiredLabels predicate selects on. A #Component
	// unifies its attached primitives' matchLabels WHOLESALE, so every key
	// written here participates in matching and nothing else does.
	//
	// Deliberately not metadata.labels. The two were one field, and the
	// upward union that implied cannot be built: categorisation labels
	// legitimately disagree between primitives — "workload" on a container,
	// "storage" on volumes, "config" on config maps — so a full union fails
	// on the first real component. Every FILTERED union measured had to
	// iterate, and CUE refuses to iterate a struct holding an unset required
	// field, which forced dropping `!` from the one label a module author
	// must pick. Separating the fields removes the filter and both costs.
	//
	// Because the union embeds structs rather than iterating them, a REQUIRED
	// key survives it: a primitive MAY declare `matchLabels: "<key>"!: <disj>`
	// and the component reports that field unset rather than silently
	// carrying an incomplete value.
	//
	// `core` names no key here — the matching vocabulary belongs to the
	// catalog that defines it, by construction rather than by `core` agreeing
	// not to look at some keys.
	//
	// NOT rendered: matchLabels does not reach #TransformerContext, so it
	// appears on no rendered object (D36).
	matchLabels?: #LabelsAnnotationsType // Example: {"opm.opmodel.dev/workload-type": "stateless"}

	// MUST be an OpenAPIv3 compatible schema
	// The field and schema exposed by this definition
	spec!: (strings.ToCamel(metadata.#definitionName)): _
}

#ResourceMap: [string]: #Resource
