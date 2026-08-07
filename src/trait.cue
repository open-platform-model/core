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

		// Optional metadata labels for categorization and filtering
		// Labels are used by OPM for definition selection and matching
		// Example: {"core.opmodel.dev/workload-type": "stateless"}
		labels?: #LabelsAnnotationsType

		// Optional metadata annotations for definition behavior hints (not used for categorization)
		// Annotations provide additional metadata but are not used for selection
		annotations?: #LabelsAnnotationsType
	}

	// MUST be an OpenAPIv3 compatible schema
	// The field and schema exposed by this definition
	spec!: (strings.ToCamel(metadata.#definitionName)): _

	// Resources that this trait can be applied to (full references)
	appliesTo!: [...#Resource]
}

#TraitMap: [string]: #Trait
