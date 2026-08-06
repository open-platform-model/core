package core

// Schema-level pins for the identity model (enhancement 0010).
//
// These mirror the cases in enhancements/0010/schemas/target.cue so the
// properties are pinned where the schema lives rather than only in the design
// document. Every value here is a HIDDEN top-level field: `cue vet` evaluates
// them and fails on a conflict, while an importing package never does — so
// they gate this repo without costing a consumer anything. They also add no
// row to src/INDEX.md, which lists `#Definition:` names only.
//
// MUST-FAIL cases are commented out with the exact error uncommenting yields.
// A commented case is not self-verifying, so each was run once, in place, at
// the commit that introduced it; the recorded error is what `task vet` printed.
//
// NOTE ON THE FILENAME: this file must NOT be named with a leading underscore.
// CUE skips files whose name begins with "_", so an "_identity_pins.cue" would
// be silently unloaded and every pin below would vet clean by never running.

// ─── Artifact identity: a module at @v2 ─────────────────────────────────────

// The positive case. `fqn` is the path — note it carries "@v2" and not
// "2.4.1" — and `registryPath` drops the major.
_pinModuleV2: #Module & {
	metadata: {
		name:         "postgres"
		modulePath:   "opmodel.dev/modules/postgres@v2"
		version:      "2.4.1"
		fqn:          "opmodel.dev/modules/postgres@v2"
		registryPath: "opmodel.dev/modules/postgres"
	}
}

// Underscores are legal in a module path leaf, because a module path ends in
// the module's own snake_case name (D8).
_pinModuleSnakeLeaf: #Module & {
	metadata: {
		name:         "cert_manager"
		modulePath:   "opmodel.dev/modules/cert_manager@v1"
		version:      "1.0.0"
		registryPath: "opmodel.dev/modules/cert_manager"
	}
}

// The same module one major up. Same lineage, different artifact.
_pinModuleV3: #Module & {
	metadata: {
		name:         "postgres"
		modulePath:   "opmodel.dev/modules/postgres@v3"
		version:      "3.0.0"
		registryPath: "opmodel.dev/modules/postgres"
	}
}

// A release inside one major. Differs from _pinModuleV2 in `version` only.
_pinModuleV2Later: #Module & {
	metadata: {
		name:       "postgres"
		modulePath: "opmodel.dev/modules/postgres@v2"
		version:    "2.9.9"
	}
}

// THE INVARIANT, HALF ONE — asserted in both directions, because a test that
// only pins what must not move will not catch an identity that has stopped
// distinguishing what it should.
//
// Direction one: a release does not move the module's identity. `uuid` is
// asserted explicitly — a case checking `fqn` alone would not catch a `uuid`
// regression, since `uuid`'s formula could change while its input did not.
_pinModuleUUIDStableAcrossRelease: _pinModuleV2.metadata.uuid & _pinModuleV2Later.metadata.uuid
_pinModuleFQNStableAcrossRelease:  _pinModuleV2.metadata.fqn & _pinModuleV2Later.metadata.fqn
_pinModuleFQNStableAcrossRelease:  "opmodel.dev/modules/postgres@v2"

// Direction two: a major bump DOES move it. @v2 and @v3 are distinct modules
// under both CUE and Go semantics. Expressed as a disunification check —
// `!=` on two concrete strings evaluates to a bool, which `true` then pins.
_pinModuleUUIDMovesAcrossMajor: _pinModuleV2.metadata.uuid != _pinModuleV3.metadata.uuid
_pinModuleUUIDMovesAcrossMajor: true

// ...while the registry path does not, which is what half two rests on.
_pinRegistryPathStableAcrossMajor: _pinModuleV2.metadata.registryPath & _pinModuleV3.metadata.registryPath
_pinRegistryPathStableAcrossMajor: "opmodel.dev/modules/postgres"

// ─── Artifact identity: a catalog ───────────────────────────────────────────

// A catalog's fqn is its module path too. Hyphens stay legal in non-leaf
// segments, so an organisation such as github.com/open-platform-model remains
// expressible; only a module's LEAF is constrained, and only for #Module.
_pinCatalog: #Catalog & {
	metadata: {
		modulePath: "github.com/open-platform-model/catalogs/opm@v1"
		version:    "1.2.0"
		fqn:        "github.com/open-platform-model/catalogs/opm@v1"
	}
}

// The transformer stamp carries the MAJOR-FREE path. Re-appending the major
// would produce a value #ComponentTransformer's own #PackagePathType rejects.
_pinCatalogStamp: #Catalog & {
	metadata: {
		modulePath: "opmodel.dev/catalogs/opm@v1"
		version:    "1.2.0"
	}
	#transformers: "opmodel.dev/catalogs/opm/transformers/deployment@1.2.0": {
		metadata: {
			name:        "deployment"
			description: "renders a Deployment"
			modulePath:  "opmodel.dev/catalogs/opm/transformers"
		}
		#transform: {}
	}
}

// ─── Instance identity (D41) ────────────────────────────────────────────────
//
// THE INVARIANT, HALF TWO, and the half the owner label depends on. The SAME
// instance under four perturbations of the module it deploys: only the last
// two move it, and both of them should.

_pinInstanceOnV2: #ModuleInstance & {
	metadata: {
		name:      "postgres-prod"
		namespace: "prod"
		fqn:       "opmodel.dev/modules/postgres:postgres-prod:prod"
	}
	#module: _pinModuleV2
	values:  _
}

// A patch release of the same module. Nothing about the instance moves.
_pinInstanceOnV2Later: #ModuleInstance & {
	metadata: {
		name:      "postgres-prod"
		namespace: "prod"
		fqn:       "opmodel.dev/modules/postgres:postgres-prod:prod"
	}
	#module: _pinModuleV2Later
	values:  _
}

// A MAJOR bump. The module's own uuid moved (pinned above); the instance's
// does not, because registryPath carries no major. This is the case that was
// silently orphaning resources: the operator's prune step skips any delete
// whose live owner label disagrees with the instance UUID it recorded, and it
// skips WITHOUT erroring.
_pinInstanceOnV3: #ModuleInstance & {
	metadata: {
		name:      "postgres-prod"
		namespace: "prod"
		fqn:       "opmodel.dev/modules/postgres:postgres-prod:prod"
	}
	#module: _pinModuleV3
	values:  _
}

_pinInstanceSurvivesRelease: _pinInstanceOnV2.metadata.uuid & _pinInstanceOnV2Later.metadata.uuid
_pinInstanceSurvivesMajor:   _pinInstanceOnV2.metadata.uuid & _pinInstanceOnV3.metadata.uuid

// The ownership label carries that uuid — it is the value the prune step reads.
_pinInstanceOwnerLabel: _pinInstanceOnV2.metadata.labels["module-instance.opmodel.dev/uuid"] & "\(_pinInstanceOnV2.metadata.uuid)"

// ─── Instance identity still distinguishes what it must ─────────────────────
//
// Without these, the survival pins above are satisfiable by an identity that
// has stopped distinguishing anything.

// A different module sharing a leaf name. Deriving instance identity from
// `metadata.name` rather than from the path would collide exactly here.
_pinOtherOwnerModule: #Module & {
	metadata: {
		name:       "postgres"
		modulePath: "community.opmodel.dev/m/otherorg/postgres@v2"
		version:    "2.4.1"
	}
}

_pinInstanceOtherOwner: #ModuleInstance & {
	metadata: {
		name:      "postgres-prod"
		namespace: "prod"
		fqn:       "community.opmodel.dev/m/otherorg/postgres:postgres-prod:prod"
	}
	#module: _pinOtherOwnerModule
	values:  _
}

// One module, two namespaces.
_pinInstanceOtherNamespace: #ModuleInstance & {
	metadata: {
		name:      "postgres-prod"
		namespace: "staging"
		fqn:       "opmodel.dev/modules/postgres:postgres-prod:staging"
	}
	#module: _pinModuleV2
	values:  _
}

// One module, one namespace, two instance names.
_pinInstanceOtherName: #ModuleInstance & {
	metadata: {
		name:      "postgres-replica"
		namespace: "prod"
		fqn:       "opmodel.dev/modules/postgres:postgres-replica:prod"
	}
	#module: _pinModuleV2
	values:  _
}

_pinInstancesDistinct: [
	_pinInstanceOnV2.metadata.uuid != _pinInstanceOtherOwner.metadata.uuid,
	_pinInstanceOnV2.metadata.uuid != _pinInstanceOtherNamespace.metadata.uuid,
	_pinInstanceOnV2.metadata.uuid != _pinInstanceOtherName.metadata.uuid,
]
_pinInstancesDistinct: [true, true, true]

// ─── #ArtifactRef decomposition ─────────────────────────────────────────────

_pinRef: #ArtifactRef & {
	modulePath:   "opmodel.dev/modules/postgres@v2"
	registryPath: "opmodel.dev/modules/postgres"
	major:        "v2"
	importPath:   "opmodel.dev/modules/postgres@v2"
}

// ─── Primitive paths carry no major ─────────────────────────────────────────

_pinResourcePath: #Resource & {
	metadata: {
		name:       "config-maps"
		modulePath: "opmodel.dev/catalogs/opm/resources"
		version:    "1.2.0"
	}
	spec: configMaps: _
}

// ─── MUST VET CLEAN, deliberately (D43 / D45) ───────────────────────────────
//
// A declared version whose major disagrees with the path's is NOT refused by
// `core`, on either artifact type. This is the SPECIFIED behaviour, not a gap:
// D40 added a `core`-side versionMajor assertion, D43 removed it for #Catalog
// and D45 for #Module. The relation is asserted in the artifact's own
// identity/identity.cue, at the point both values are written, where a failure
// names the file the author has open.
//
// These two cases exist so that reintroducing the `core`-side assertion reads
// as a CHANGE rather than as a fix — an uncommented passing case with no
// comment looks like an oversight, and this one is the trade D43/D45 made.
_pinModuleMajorSkewAccepted: #Module & {
	metadata: {
		name:       "postgres"
		modulePath: "opmodel.dev/modules/postgres@v2"
		version:    "3.0.0"
	}
}

_pinCatalogMajorSkewAccepted: #Catalog & {
	metadata: {
		modulePath: "opmodel.dev/catalogs/opm@v1"
		version:    "2.0.0"
	}
}

// ─── MUST FAIL ──────────────────────────────────────────────────────────────
//
// Each was uncommented once and run; the recorded error is `task vet`'s output.

// A version interpolated into fqn. The refusal is STRUCTURAL rather than merely
// regex-level — `fqn: #ModulePathType & modulePath` admits no other value — so
// the first error is a conflict, not an out-of-bound:
//   _failFqnCarriesVersion.metadata.fqn: conflicting values
//     "opmodel.dev/modules/postgres@v2" and "opmodel.dev/modules/postgres@2.4.1"
//
//  _failFqnCarriesVersion: #Module & {
//   metadata: {
//    name:       "postgres"
//    modulePath: "opmodel.dev/modules/postgres@v2"
//    version:    "2.4.1"
//    fqn:        "opmodel.dev/modules/postgres@2.4.1"
//   }
//  }

// A kebab-case module name. Reported twice — once through the
// module.opmodel.dev/name label's interpolation, once on the field itself:
//   _failKebabName.metadata.name: invalid interpolation: invalid value
//     "cert-manager" (out of bound =~"^[a-z0-9]([a-z0-9_]*[a-z0-9])?$")
//   _failKebabName.metadata.name: invalid value "cert-manager"
//     (out of bound =~"^[a-z0-9]([a-z0-9_]*[a-z0-9])?$")
//
//  _failKebabName: #Module & {
//   metadata: {
//    name:       "cert-manager"
//    modulePath: "opmodel.dev/modules/cert-manager@v1"
//    version:    "1.0.0"
//   }
//  }

// A name disagreeing with the path's leaf:
//   _failLeafMismatch.metadata._leaf: conflicting values false and true
//
//  _failLeafMismatch: #Module & {
//   metadata: {
//    name:       "postgres"
//    modulePath: "opmodel.dev/modules/mysql@v1"
//    version:    "1.0.0"
//   }
//  }

// A module path with no major. The out-of-bound is reported against `fqn` and
// `_ref.modulePath` before `modulePath` itself, since both read it:
//   _failNoMajor.metadata.fqn: invalid interpolation: invalid value
//     "opmodel.dev/modules/postgres"
//     (out of bound =~"^[a-z0-9._-]+(/[a-z0-9._-]+)*@v[0-9]+$")
//   _failNoMajor.metadata._ref.modulePath: invalid value
//     "opmodel.dev/modules/postgres" (out of bound =~"…@v[0-9]+$")
//
//  _failNoMajor: #Module & {
//   metadata: {
//    name:       "postgres"
//    modulePath: "opmodel.dev/modules/postgres"
//    version:    "1.0.0"
//   }
//  }

// A primitive path carrying a major:
//   _failPrimitiveMajor.metadata.modulePath: invalid interpolation: invalid
//     value "opmodel.dev/catalogs/opm/resources@v1"
//     (out of bound =~"^[a-z0-9._-]+(/[a-z0-9._-]+)*$")
//
//  _failPrimitiveMajor: #Resource & {
//   metadata: {
//    name:       "config-maps"
//    modulePath: "opmodel.dev/catalogs/opm/resources@v1"
//    version:    "1.2.0"
//   }
//   spec: configMaps: _
//  }

// A module path substituted where a registry path belongs — the shape D41
// replaces, and the one an instance fqn must never be built from.
//
// Two mechanisms refuse it, and in `core` the FIRST one fires. `registryPath`
// here is DERIVED from `_ref`, not authored, so supplying a full module path
// conflicts with the already-computed value:
//   _failRegistryPathCarriesMajor.metadata.registryPath: conflicting values
//     "opmodel.dev/modules/postgres" and "opmodel.dev/modules/postgres@v2"
//
// The type check is the backstop rather than the trigger, which is worth
// stating because enhancements/0010's _instanceFromFqn case reports the type
// error instead: there, `#InstanceIdentity.moduleRegistryPath!` is an AUTHORED
// field with nothing to conflict against, so #PackagePathType is all that
// stands in the way. Both refusals are structural; only the wording differs.
//
//  _failRegistryPathCarriesMajor: #Module & {
//   metadata: {
//    name:         "postgres"
//    modulePath:   "opmodel.dev/modules/postgres@v2"
//    version:      "2.4.1"
//    registryPath: "opmodel.dev/modules/postgres@v2"
//   }
//  }
