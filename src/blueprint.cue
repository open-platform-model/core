package core

import (
	"strings"
)

// #Blueprint: Defines a reusable blueprint
// that composes resources and traits into a higher-level abstraction.
// Blueprints enable standardized configurations for common use cases.
#Blueprint: {
	kind: "Blueprint"

	metadata: {
		name!: #NameType // Example: "stateless-workload"
		#definitionName: (#KebabToPascal & {"in": name}).out

		modulePath!: #PackagePathType // Example: "opmodel.dev/catalogs/opm/blueprints/workload"

		// apiVersion: this contract's own level, and the only component of its
		// key (enhancement 0010 D4). A blueprint carries one because it is a
		// PRIMITIVE (D44): it composes resources and traits rather than
		// introducing vocabulary, but a module attaches it and writes against
		// its `spec`, so it earns the contract key and the additive-only
		// promise that key gates.
		apiVersion!: #APIVersionType // Example: "v1beta1"

		// catalogVersion: the catalog build this definition shipped in.
		// Provenance only (D25) — no contract key interpolates it.
		catalogVersion!: #VersionType // Example: "1.0.0"

		// fqn: AUTHORED by the catalog at the definition site, not derived here
		// (enhancement 0010 D21), so fqn, modulePath and catalogVersion trace
		// to one identity package and a release moves them together. `core` no
		// longer refuses a value disagreeing with this definition's own fields;
		// #CatalogMemberFQNGate asserts that agreement at publish.
		fqn!: #ContractFQNType // Example: "opmodel.dev/catalogs/opm/blueprints/workload/stateless-workload@v1beta1"

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

	// Resources that compose this blueprint (full references)
	composedResources!: [...#Resource]

	// Traits that compose this blueprint (full references)
	composedTraits?: [...#Trait]

	// MUST be an OpenAPIv3 compatible schema
	// The field and schema exposed by this definition
	spec!: (strings.ToCamel(metadata.#definitionName)): _
}

#BlueprintMap: [string]: #Blueprint
