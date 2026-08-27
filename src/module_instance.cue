package core

import (
	cue_uuid "uuid"
)

// #ModuleInstance: The concrete deployment instance
// Contains: Reference to Module, values, target namespace
// Users/deployment systems create this to deploy a specific version
//
// Was: #ModuleRelease (renamed in enhancement 0002)
#ModuleInstance: {
	kind: "ModuleInstance"

	metadata: {
		name!:      #NameType
		namespace!: #NameType // Required for instances (target environment)

		// Cluster DNS domain. Defaults to "cluster.local"; override per instance
		// when the target cluster runs a non-standard domain. Surfaced into
		// every component's #names.dns.fqdn via #module.#ctx.instance.
		clusterDomain: string | *"cluster.local"

		// fqn: this instance's own identity — the deployed module's MAJOR-FREE
		// registry path, this instance's name, and its namespace. Neither the
		// module's version nor its major reaches instance identity (0010 D41).
		// See SPEC.md § 3.5.
		fqn: "\(#moduleMetadata.registryPath):\(name):\(namespace)"

		// WHY registryPath: it derives from the module's registryPath rather than from its fqn or
		// uuid, so NEITHER the module's version NOR its major reaches instance
		// identity (enhancement 0010 D41). The two values answer different
		// questions and were forced to agree by deriving one from the other:
		// module.uuid answers "which module is this" and MUST move across a
		// major; instance.uuid answers "which resources does this manage" and
		// MUST survive every upgrade of the same deployment.
		//
		// A full module path substituted here is refused by the type rather
		// than silently producing a third identity — registryPath is a
		// #PackagePathType, which admits no "@vN" at all.
		//
		// Deriving from the module's `name` instead was rejected on collision:
		// opmodel.dev/modules/jellyfin and example.com/jellyfin both carry
		// name "jellyfin", while a full registry path is unique by construction.
		// SPEC.md § 3.5 Rationale, "Why instance identity derives from the
		// module's `registryPath` and not from its `fqn` or `uuid`" and "Why not
		// derive instance identity from the module's `name`".

		// Stable UUID for this instance, computed as a UUID v5 (SHA1) of the
		// instance's own fqn — mirroring #Module's own fqn → uuid shape. This
		// is the value carried in the module-instance.opmodel.dev/uuid label
		// below, which the operator reads to decide whether it owns a live
		// object.
		uuid: #UUIDType & cue_uuid.SHA1(OPMNamespace, fqn)

		labels?: #LabelsAnnotationsType
		labels?: {if #moduleMetadata.labels != _|_ {#moduleMetadata.labels}}
		labels: {
			// Standard labels for module instance identification
			"module-instance.opmodel.dev/name": "\(name)"
			"module-instance.opmodel.dev/uuid": "\(uuid)"
		}

		annotations?: #LabelsAnnotationsType
		annotations?: {if #moduleMetadata.annotations != _|_ {#moduleMetadata.annotations}}

	}

	// Reference to the Module to deploy. The #ctx.instance wiring sets the
	// module's runtime context from this instance's metadata — every #Component
	// in #module receives this instance identity via the module's #components
	// pattern constraint, so #names + DNS variants flow through automatically.
	// Introduced by enhancement 0001 (D1, D4).
	#module!: #Module & {
		#ctx: instance: {
			name:          metadata.name
			namespace:     metadata.namespace
			uuid:          metadata.uuid
			clusterDomain: metadata.clusterDomain
		}
	}
	#moduleMetadata: #module.metadata

	let unifiedModule = #module & {#config: values}

	// components are the module's own components, verbatim. Core injects
	// nothing; a module with secrets declares its own secrets component.
	components: {
		for name, comp in unifiedModule.#components {
			(name): comp
		}
	}

	// WHY core no longer injects an `opm-secrets` component for configs
	// carrying #Secret fields: transformer matching is by exact resource FQN,
	// and a catalog's FQN embeds that catalog's version — a value core cannot
	// know and must not hardcode, so the injected component matched no
	// transformer on the v1 line and failed the render outright. A module with
	// secrets declares a secrets component against its own catalog's #Secrets
	// resource (catalogs re-export #AutoSecrets for the discovery half).
	// SPEC.md § 3.5 Rationale, "Why core no longer injects an `opm-secrets`
	// component".

	// Concrete values (everything closed/concrete)
	// Must satisfy the #config from #module
	values: _
}

// Was: #ModuleReleaseMap (renamed in enhancement 0002)
#ModuleInstanceMap: [string]: #ModuleInstance
