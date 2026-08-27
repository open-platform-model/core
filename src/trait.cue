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

		modulePath!: #PackagePathType // Example: "opmodel.dev/catalogs/opm/traits/v1beta1" (kind prefix + this trait's own apiVersion, 0010 D49)

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
	// upward. NOT rendered (D36). See SPEC.md § 2.2.
	matchLabels?: #LabelsAnnotationsType // Example: {"opm.opmodel.dev/workload-type": "stateless"}

	// WHY two fields: see #Resource.matchLabels for why the two cannot be one
	// field. NOT rendered: matchLabels does not reach #TransformerContext.

	// nameConstraint: the name rule a kind this primitive renders enforces on
	// the owning component's metadata.resourceName (enhancement 0019 D21);
	// top when the primitive is indifferent, which is the default. A hidden
	// definition field: never optional, never guarded on presence. MAY be
	// computed from this primitive's own fields (0019 D23). See SPEC.md § 2.2.
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
	// concrete one. SPEC.md § 2.2 Rationale, which points at #Resource
	// (§ 2.1) for the argument.

	// fulfilment: where this contract's implementation is expected to come
	// from. "catalog" (the default) means the declaring catalog implements
	// it; "provider" means it deliberately ships no transformer and a
	// platform must carry exactly one transformer requiring this contract.
	// See #Resource.fulfilment and SPEC.md § 2.2 (enhancement 0010 D32).
	fulfilment: *"catalog" | "provider"

	// WHY it exists on a trait: see #Resource.fulfilment for why it is
	// declared rather than derived, and why the guard is the kernel's.
	// `backup` is the case this exists for: catalog_opm declares the trait
	// and ships nothing that renders it, which is today indistinguishable
	// from having forgotten to.

	// optional: whether an unhandled demand for this trait fails the render or
	// degrades to a warning naming the trait (enhancement 0010 D46, amending
	// D28's trait half). NO DEFAULT HERE: the declaring catalog states the
	// posture as a default (`bool | *true` or `bool | *false`), a module may
	// narrow it at the attachment site, and #TraitOptionalGate refuses a
	// catalog that pins a concrete value. See SPEC.md § 2.2.
	optional: bool

	// WHY no default here, and the absence is the whole design. `core` has no
	// opinion about whether backups are optional; the DECLARING CATALOG states
	// the posture, and it must state it as a DEFAULT:
	//
	//   optional: bool | *true    // advisory — a workload without an
	//                             // autoscaler still runs
	//   optional: bool | *false   // load-bearing — an unhandled backup means
	//                             // there are no backups
	//
	// A default is what makes the posture a RECOMMENDATION rather than a
	// ruling: a module narrowing a default at the attachment site is never a
	// conflict, so the demand side always has the last word —
	//
	//   #traits: (BackupFQN): Backup & {optional: true}   // not my data
	//
	// while a module narrowing a CONCRETE value is a conflict, which is why a
	// catalog writing `optional: false` would win and is refused at publish.
	// `core` cannot express "you may suggest but not decide" in a field, so
	// #TraitOptionalGate below carries it instead.
	//
	// Why the posture is per-trait rather than one rule for all traits:
	// optionality is a property of the (trait, component) PAIR. `backup` on a
	// throwaway cache is advisory; on a database it is the entire point. The
	// catalog knows the common case, the module knows its own, and this shape
	// lets each say its part. SPEC.md § 2.2 Rationale, "Why optionality is a
	// property of the Trait, and why `core` states no default for it" and
	// "Why the earlier demand-side marker was dropped".

	// MUST be an OpenAPIv3 compatible schema
	// The field and schema exposed by this definition
	spec!: (strings.ToCamel(metadata.#definitionName)): _

	// Resources that this trait can be applied to (full references)
	appliesTo!: [...#Resource]
}

// #TraitOptionalGate: what `opm catalog publish` unifies against, once per
// published #Trait, to hold catalogs to the two rules #Trait.optional cannot
// express itself: a posture is stated, and it is not pinned. Takes the FIELD,
// not the trait, and MUST be unified into a non-hidden value. See SPEC.md
// § 5.1.
#TraitOptionalGate: {
	// The value under test: some published trait's `optional`.
	optional: bool

	// RULE 1 — the catalog stated a posture. Interpolation forces the
	// disjunction to its default, so a trait that never mentions `optional`
	// fails here. Reported as `incomplete value bool`, and visible only under
	// `cue vet -c` — which publish runs, and a catalog author's plain
	// `task vet` does not.
	_stated: "\(optional)"

	// RULE 2 — and did not PIN it. Both arms must remain admissible, so a
	// concrete value, which no module could ever override, is refused. Unlike
	// rule 1 this is visible under plain `cue vet`.
	_overridable: ((optional & true) != _|_) && ((optional & false) != _|_)
	_overridable: true
}

// WHY it ships in `core` beside the identity gates and is checked the same
// way — the schema is the contract, CUE is the engine that checks contracts,
// and what the author reads is CUE's own error (0011 D21/D22).
//
// WHY it TAKES THE FIELD, NOT THE TRAIT. `#TraitOptionalGate & {trait:
// SomeTrait}` would drag the trait's `spec` into concreteness checking under
// `cue vet -c`, and a spec is a SCHEMA that must never be concrete.
//
// WHY it MUST BE UNIFIED INTO A NON-HIDDEN VALUE. `cue vet -c` does not check
// hidden fields, so a gate parked in a `_`-prefixed slot passes silently while
// checking nothing. SPEC.md § 5.1 Rationale.

#TraitMap: [string]: #Trait
