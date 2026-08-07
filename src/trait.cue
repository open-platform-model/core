package core

import (
	"strings"
)

// #Trait: Defines additional behavior or characteristics that can be attached to components.
#Trait: {
	kind: "Trait"

	metadata: {
		name!: #NameType // Example: "scaling"
		#definitionName: (#KebabToPascal & {"in": name}).out

		modulePath!: #PackagePathType // Example: "opmodel.dev/catalogs/opm/traits"

		// apiVersion: this contract's own level, and the only component of its
		// key (enhancement 0010 D4). Moved when this trait's shape breaks — a
		// catalog release does not move it, which is what lets a module's
		// demand survive one. The one identity value on a primitive that is
		// not derivable from its catalog's identity package.
		apiVersion!: #APIVersionType // Example: "v1beta1"

		// catalogVersion: the catalog build this definition shipped in.
		// Provenance only (D25) — no contract key interpolates it.
		catalogVersion!: #VersionType // Example: "1.0.0"

		// fqn: AUTHORED by the catalog at the definition site, not derived here
		// (enhancement 0010 D21), so fqn, modulePath and catalogVersion trace
		// to one identity package and a release moves them together. `core` no
		// longer refuses a value disagreeing with this definition's own fields;
		// #CatalogMemberFQNGate asserts that agreement at publish.
		fqn!: #ContractFQNType // Example: "opmodel.dev/catalogs/opm/traits/scaling@v1beta1"

		// Human-readable description of the definition
		description?: string

		// Optional metadata labels for CATEGORIZATION. Descriptive only —
		// nothing selects on these, and they are never unified upward into a
		// #Component (enhancement 0010 D36).
		// Example: {"trait.opmodel.dev/category": "network"}
		labels?: #LabelsAnnotationsType

		// Optional metadata annotations for definition behavior hints (not used for categorization)
		// Annotations provide additional metadata but are not used for selection
		annotations?: #LabelsAnnotationsType
	}

	// matchLabels: this trait's MATCHING identity — the keys a
	// #ComponentTransformer.requiredLabels predicate selects on, unified
	// wholesale into every #Component that attaches this trait. Separate from
	// metadata.labels, which carries categorisation and is never unified
	// upward; see #Resource.matchLabels for why the two cannot be one field.
	//
	// NOT rendered: matchLabels does not reach #TransformerContext (D36).
	matchLabels?: #LabelsAnnotationsType // Example: {"opm.opmodel.dev/workload-type": "stateless"}

	// fulfilment: where this contract's implementation is expected to come
	// from. "catalog" (the default) means the declaring catalog implements
	// it; "provider" means it deliberately ships no transformer and a
	// platform must carry exactly one transformer requiring this contract.
	// See #Resource.fulfilment for why it is declared rather than derived,
	// and why the guard is the kernel's (enhancement 0010 D32).
	//
	// `backup` is the case this exists for: catalog_opm declares the trait
	// and ships nothing that renders it, which is today indistinguishable
	// from having forgotten to.
	fulfilment: *"catalog" | "provider"

	// MUST be an OpenAPIv3 compatible schema
	// The field and schema exposed by this definition
	spec!: (strings.ToCamel(metadata.#definitionName)): _

	// Resources that this trait can be applied to (full references)
	appliesTo!: [...#Resource]
}

#TraitMap: [string]: #Trait
