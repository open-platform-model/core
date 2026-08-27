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

		// Exactly "<catalog registryPath>/blueprints/<apiVersion>" — one base
		// segment per kind and one version segment beneath it, DERIVED from
		// this blueprint's own apiVersion (enhancement 0010 D42 as amended by
		// D49). The version segment never enters the fqn. See SPEC.md § 3.3.
		modulePath!: #PackagePathType // Example: "opmodel.dev/catalogs/opm/blueprints/v1beta1"

		// WHY never an arbitrary grouping: #CatalogMemberFQNGate compares this
		// against kindPrefix.blueprints + "/" + apiVersion by EQUALITY, so a
		// blueprint filed flat or under any other segment is refused at
		// publish.

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
		fqn!: #ContractFQNType // Example: "opmodel.dev/catalogs/opm/blueprints/stateless-workload@v1beta1"

		// Human-readable description of the definition
		description?: string

		// Optional metadata labels for CATEGORIZATION. Descriptive only —
		// nothing selects on these, and they are never unified upward into a
		// #Component (enhancement 0010 D36).
		// Example: {"blueprint.opmodel.dev/category": "workload"}
		labels?: #LabelsAnnotationsType

		// Optional metadata annotations for definition behavior hints (not used for categorization)
		// Annotations provide additional metadata but are not used for selection
		annotations?: #LabelsAnnotationsType
	}

	// matchLabels: this blueprint's MATCHING identity — the keys a
	// #ComponentTransformer.requiredLabels predicate selects on, unified
	// wholesale into every #Component that attaches this blueprint. Separate
	// from metadata.labels. NOT rendered (D36). See SPEC.md § 3.3.
	matchLabels?: #LabelsAnnotationsType // Example: {"opm.opmodel.dev/workload-type": "stateful"}

	// WHY a blueprint typically answers the key: a blueprint is where the
	// workload-type key is typically CONCRETE: it composes a container that
	// declares the key required and answers it, so attaching the blueprint
	// is what makes the component's matching identity complete. See
	// #Resource.matchLabels for why the two cannot be one field. NOT
	// rendered: matchLabels does not reach #TransformerContext.

	// nameConstraint: the name rule a kind this primitive renders enforces on
	// the owning component's metadata.resourceName (enhancement 0019 D21);
	// top when the primitive is indifferent, which is the default. A hidden
	// definition field: never optional, never guarded on presence. MAY be
	// computed from this primitive's own fields (0019 D23). See SPEC.md § 3.3.
	#nameConstraint: _

	// WHY the primitive declares it: #Component collects every attached
	// primitive's slot into one conjunction and asserts the resolved name
	// against it, so the primitive that introduces a dot-hostile kind is the
	// one that declares the rule and core carries no per-kind knowledge.
	// Unifying top costs nothing.
	//
	// WHY not optional and never guarded on presence: measured on cue
	// v0.17.1, `x.#nameConstraint != _|_` is false for a non-concrete value,
	// so an optional slot behind an existence guard silently never propagates
	// while the code reads correctly.
	//
	// WHY it may be computed (0019 D23): the catalog's container resource
	// declares #NameType when its own workload-type key reads "stateful" and
	// top otherwise, in list-index form so a default arm cannot win over the
	// concrete one. SPEC.md § 3.3 Rationale, which points at #Resource
	// (§ 2.1) for the argument.

	// NO fulfilment field, and the exclusion is STRUCTURAL rather than an
	// omission: #ComponentTransformer carries requiredResources and
	// requiredTraits and has no blueprint equivalent, so nothing can ever
	// DEMAND a blueprint and the field would name a question no matcher
	// asks. A blueprint's fulfilment is that of the contracts it composes,
	// each of which declares its own.
	//
	// Because this struct is a definition it is CLOSED, so supplying
	// `fulfilment` here is a `field not allowed` error rather than a field
	// nothing reads — see the pinned case in platform_and_match_pins.cue.
	// This is the same reasoning that keeps apiVersion off a transformer
	// (enhancement 0010 D44): a shape that admits a field nobody reads hands
	// every future field to the wrong kind for free.

	// Resources that compose this blueprint (full references)
	composedResources!: [...#Resource]

	// Traits that compose this blueprint (full references)
	composedTraits?: [...#Trait]

	// MUST be an OpenAPIv3 compatible schema
	// The field and schema exposed by this definition
	spec!: (strings.ToCamel(metadata.#definitionName)): _
}

#BlueprintMap: [string]: #Blueprint
