package core

import (
	"strings"

	cue_uuid "uuid"
)

// #Module: The portable application blueprint created by developers and/or platform teams
#Module: {
	kind: "Module"

	metadata: {
		// WHY name: a module name is snake_case and equals the leaf of its module path (enhancement 0010).

		// name: snake_case, and the leaf of modulePath. A module name has one
		// spelling: it is the CUE package name, the registry-path leaf and the value
		// in the module.opmodel.dev/name label, and package names cannot contain
		// hyphens. The kebab-case #NameType stays on #Resource / #Trait /
		// #Blueprint, which are not CUE packages.
		name!: #SnakeNameType // Example: "example_module"

		modulePath!: #ModulePathType // Example: "example.com/modules/example_module@v1" (from the module's identity package, identity/identity.cue)
		version!:    #VersionType    // Example: "0.1.0" (from the module's identity package, identity/identity.cue)

		// The one decomposition of modulePath. registryPath is the OCI
		// repository (major stripped); major is read from the path.
		_ref: #ArtifactRef & {"modulePath": modulePath}

		// WHY fqn: the fqn is the complete module path, with nothing recombined (enhancement 0010).

		// fqn is the module path — nothing is recombined, and neither `name` nor
		// `version` is interpolated into it. Artifact identity therefore
		// distinguishes majors and nothing finer: @v2 and @v3 are distinct modules
		// under both CUE and Go semantics, while every release inside a major shares
		// one fqn.
		fqn: #ModulePathType & modulePath // Example: "example.com/modules/example_module@v1"

		// WHY registryPath: instance identity derives from the module's registry path, not from its fqn (enhancement 0010).

		// registryPath: the major-free identity of the module lineage.
		// #ModuleInstance derives its own fqn from this rather than from fqn, so
		// instance identity survives a major bump; it is also the OCI repository
		// every address-composition site in `cli` and `library` collapses into.
		registryPath: _ref.registryPath // Example: "example.com/modules/example_module"

		// WHY _leaf: the path's leaf must equal the module name (enhancement 0010).

		// The path's leaf MUST be the module's name. Hidden, because it is a check
		// rather than a value a consumer reads. Only the LEAF is constrained: CUE
		// accepts hyphens in path segments, and narrowing the whole path would make
		// OPM unable to express its own organisation
		// (github.com/open-platform-model/...).
		_leaf: strings.HasSuffix(_ref.registryPath, "/"+name)
		_leaf: true

		// NO versionMajor field and NO assertion that `version`'s major equals
		// the path's — deliberately (enhancement 0010, as for #Catalog).
		// Its absence is specified, not forgotten. `identity/identity.cue`
		// asserts VersionMajor == Major at the point both values are WRITTEN,
		// so a failure names the file the author has open; `core` re-deriving
		// it one hop downstream tests the same relation over the same two
		// values. `core` cannot read id.VersionMajor directly — it cannot
		// import a consumer's identity package.
		//
		// ACCEPTED EXPOSURE: a module whose identity package is absent or
		// non-conformant carries no consumer-runnable major check. Bounded by
		// publish-side validation (enhancement 0011).

		// Unique identifier for the module, computed as a UUID v5 (SHA1) of the
		// FQN using the OPM namespace UUID. Its input is the module path, so a
		// uuid moves on a major bump and on nothing else.
		uuid: #UUIDType & cue_uuid.SHA1(OPMNamespace, fqn)

		description?: string
		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType

		labels: {
			// Standard labels for module identification
			"module.opmodel.dev/name":    "\(name)"
			"module.opmodel.dev/version": "\(version)"
			"module.opmodel.dev/uuid":    "\(uuid)"
		}
		annotations: {
			// Standard annotations for module metadata
			"module.opmodel.dev/default-namespace"?: string
		}
	}

	// WHY #components: the pattern constraint wires the per-component injection slot (enhancement 0001).

	// Components defined in this module (developer-defined, required. May be
	// added to by the platform-team). The pattern constraint wires the
	// module-level instance into every component so each component computes its
	// own #names from a shared instance identity.
	#components: [Id=#NameType]: #Component & {
		metadata: {
			name: string | *Id
			labels: "component.opmodel.dev/name": name
		}
		// WHY #instance: was #release: #ctx.release, renamed by enhancement 0002.

		#instance: #ctx.instance
	}

	// Value schema - constraints and defaults.
	// Developers define the configuration contract and reference it in their components.
	// Must be OpenAPIv3 compliant (no CUE templating - for/if statements)
	#config: _

	// debugValues: Example values for testing and debugging.
	// It is unified and validated in the runtime
	debugValues: _

	// WHY optional, open and not unified with #config: only instance init reads it, so a stale or non-concrete template must not fail every module load (enhancement 0016).
	// SPEC.md § 3.2 Rationale.

	// Values a freshly initialized instance package starts from.
	// Optional; may be non-concrete. Not checked against #config here.
	// See SPEC.md § 3.2.
	initValues?: _

	// WHY open and projected: open so future enhancements can add `platform`
	// / `environment` siblings without breaking module bodies. Components are
	// the single source of truth for their own identity; #ctx.components only
	// mirrors them (enhancement 0010). SPEC.md § 3.2 Rationale, "Why `#ctx` is inline on
	// `#Module` and not a wrapper type" and "Why `#ctx.components` is a
	// projection, not an authored map".

	// WHY #ctx: the context collapses to an inline channel with a projected components map (enhancement 0001).

	// Inline runtime context channel, open at the top level (`...`).
	// `instance` is set by #ModuleInstance from its own metadata; `components`
	// is a pure CUE projection over every component's #names.
	// See SPEC.md § 3.2.
	#ctx: {
		// WHY instance: was release: #ReleaseIdentity, renamed by enhancement 0002.

		instance: #InstanceIdentity

		components: {
			for id, c in #components {
				(id): c.#names
			}
		}

		...
	}
}

#ModuleMap: [string]: #Module
