package core

// Schema-level pins for the name types and the per-primitive name
// constraint (enhancement 0019 D20, D21, D23).
//
// Companion to platform_and_match_pins.cue and written to the same rules:
// every value here is a HIDDEN top-level field, so `cue vet` evaluates it
// and fails on a conflict while an importing package never does, and none of
// them adds a row to src/INDEX.md. MUST-FAIL cases are commented out with the
// exact error uncommenting yields, each run once in place at the commit that
// introduced it. The filename must NOT begin with an underscore: CUE skips
// such files, and every pin below would then vet clean by never running.
//
// Every pin here INTERPOLATES the value it asserts. metadata.resourceName is
// a defaulted disjunction, so the intuitive `_pin: <expr>` then
// `_pin: <literal>` asserts only that the literal is a legal value of the
// disjunction, which is always true; the interpolation forces the default to
// resolve (see platform_and_match_pins.cue, "ONE RULE ABOUT THE PIN SHAPE").
//
// WHY THESE PINS EXIST. The mechanism under test has two spellings that read
// as equivalent to the shipped one and fail SILENTLY (component.cue,
// _nameFits). A review cannot see that; a pinned default-under-constraint
// case can, because the guarded-error() spelling fires on the bare
// definition and fails every pin below, and the un-interpolated spelling
// admits the must-fail cases recorded at the end. Re-run those by hand
// whenever _nameFits is touched.

// ─── Fixtures: naming surfaces only ─────────────────────────────────────────

_pinNameInstance: #InstanceIdentity & {
	name:      "prod"
	namespace: "media"
}

// An indifferent resource: declares no constraint, so its slot is top.
_pinNameIndifferent: #Resource & {
	metadata: {
		name:           "volumes"
		modulePath:     "opmodel.dev/catalogs/opm/resources/v1beta1"
		apiVersion:     "v1beta1"
		catalogVersion: "2.0.0-alpha.5"
		fqn:            "opmodel.dev/catalogs/opm/resources/volumes@v1beta1"
	}
	spec: volumes: {}
}

// The container, shaped like the catalog's: the workload-type key is
// REQUIRED, and the constraint is computed from it (0019 D23) — #NameType
// when stateful (pod DNS <sts>-<n>.<svc>… puts the name in a label
// position, and the server enforces the label rule on both axes there),
// top otherwise. List-index form: a default arm would win over the concrete
// one.
_pinNameContainer: #Resource & {
	metadata: {
		name:           "container"
		modulePath:     "opmodel.dev/catalogs/opm/resources/v1beta1"
		apiVersion:     "v1beta1"
		catalogVersion: "2.0.0-alpha.5"
		fqn:            "opmodel.dev/catalogs/opm/resources/container@v1beta1"
	}
	matchLabels: "opm.opmodel.dev/workload-type"!: "stateless" | "stateful" | "daemon"
	#nameConstraint: [
		if matchLabels["opm.opmodel.dev/workload-type"] == "stateful" {#NameType},
		_,
	][0]
	spec: container: {}
}
_pinNameStateless: matchLabels: "opm.opmodel.dev/workload-type": "stateless"
_pinNameStateful: matchLabels: "opm.opmodel.dev/workload-type":  "stateful"

// Expose: the Service name is the first FQDN label, DNS-1035.
_pinNameExpose: #Trait & {
	metadata: {
		name:           "expose"
		modulePath:     "opmodel.dev/catalogs/opm/traits/v1beta1"
		apiVersion:     "v1beta1"
		catalogVersion: "2.0.0-alpha.5"
		fqn:            "opmodel.dev/catalogs/opm/traits/expose@v1beta1"
	}
	appliesTo: [_pinNameContainer]
	#nameConstraint: #ServiceNameType
	spec: expose: {}
}

// The stateful-workload blueprint: the label rule, dots and length.
_pinNameStatefulBlueprint: #Blueprint & {
	metadata: {
		name:           "stateful-workload"
		modulePath:     "opmodel.dev/catalogs/opm/blueprints/v1beta1"
		apiVersion:     "v1beta1"
		catalogVersion: "2.0.0-alpha.5"
		fqn:            "opmodel.dev/catalogs/opm/blueprints/stateful-workload@v1beta1"
	}
	composedResources: [_pinNameContainer]
	#nameConstraint: #NameType
	spec: statefulWorkload: {}
}

// ─── Pins: the name types ───────────────────────────────────────────────────

_pinObjectNameDots: "\(#ObjectNameType & "zfs.csi.openebs.io")"
_pinObjectNameDots: "zfs.csi.openebs.io"

// A leading digit: a #NameType, not a #ServiceNameType.
_pinNameTypeLeadingDigit: "\(#NameType & "1prod-web")"
_pinNameTypeLeadingDigit: "1prod-web"

// ─── Pins: the assertion admits what it must ────────────────────────────────

// Default under Expose: the qualified default is already DNS-1035.
_pinNameExposedDefault: #Component & {
	metadata: name:                                            "web"
	#resources: container:                                     _pinNameContainer & _pinNameStateless
	#traits: "opmodel.dev/catalogs/opm/traits/expose@v1beta1": _pinNameExpose
	#instance: _pinNameInstance
}
_pinNameExposedDefaultValue: "\(_pinNameExposedDefault.#names.resourceName)"
_pinNameExposedDefaultValue: "prod-web"

// Dotted override with no dot-hostile primitive: admitted, dots reach DNS.
_pinNameDottedOverride: #Component & {
	metadata: {
		name:         "exporter"
		resourceName: "metrics.internal.example"
	}
	#resources: container: _pinNameContainer & _pinNameStateless
	#instance: _pinNameInstance
}
_pinNameDottedOverrideFqdn: "\(_pinNameDottedOverride.#names.dns.fqdn)"
_pinNameDottedOverrideFqdn: "metrics.internal.example.media.svc.cluster.local"

// A 65-rune default with no constraint: admitted (the 63-rune guard that
// refused this before D20 is retired; both operands are labels, so the
// default cannot exceed 127 runes and the 253 ceiling is unreachable).
_pinNameLongDefault: #Component & {
	metadata: name:        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	#resources: container: _pinNameContainer & _pinNameStateless
	#instance: _pinNameInstance
}
_pinNameLongDefaultLen: len(_pinNameLongDefault.#names.resourceName)
_pinNameLongDefaultLen: 65

// The 127-rune maximum: admitted.
_pinNameMaxDefault: #Component & {
	metadata: name:        "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	#resources: container: _pinNameContainer & _pinNameStateless
	#instance: {name: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", namespace: "media"}
}
_pinNameMaxDefaultLen: len(_pinNameMaxDefault.#names.resourceName)
_pinNameMaxDefaultLen: 127

// Exact override that satisfies Expose: the D22 spelling for a workload,
// Service and projection that share one name.
_pinNameExposedExact: #Component & {
	metadata: {
		name:         "istiod"
		resourceName: "istiod"
	}
	#resources: container:                                     _pinNameContainer & _pinNameStateless
	#traits: "opmodel.dev/catalogs/opm/traits/expose@v1beta1": _pinNameExpose
	#instance: _pinNameInstance
}
_pinNameExposedExactFqdn: "\(_pinNameExposedExact.#names.dns.fqdn)"
_pinNameExposedExactFqdn: "istiod.media.svc.cluster.local"

// Raw stateful container, default: the conditional constraint reads
// #NameType, which the default satisfies.
_pinNameStatefulDefault: #Component & {
	metadata: name:        "cache"
	#resources: container: _pinNameContainer & _pinNameStateful
	#instance: _pinNameInstance
}
_pinNameStatefulDefaultValue: "\(_pinNameStatefulDefault.#names.resourceName)"
_pinNameStatefulDefaultValue: "prod-cache"

// Two constraints compose by unification (Expose ∧ stateful = DNS-1035),
// with no precedence rule written anywhere.
_pinNameComposed: #Component & {
	metadata: name:                                                               "db"
	#resources: container:                                                        _pinNameContainer & _pinNameStateful
	#traits: "opmodel.dev/catalogs/opm/traits/expose@v1beta1":                    _pinNameExpose
	#blueprints: "opmodel.dev/catalogs/opm/blueprints/stateful-workload@v1beta1": _pinNameStatefulBlueprint
	#instance: _pinNameInstance
}
_pinNameComposedValue: "\(_pinNameComposed.#names.resourceName)"
_pinNameComposedValue: "prod-db"

// ─── MUST FAIL (commented; observed cue v0.17.1, this commit) ───────────────
//
// Each refuses at `cue vet` on _nameFits, naming the string, the violated
// bound and the constraint type's definition site in types.cue. None is a
// bare `incomplete value` or `non-concrete value` diagnostic.
//
// Dotted override + Expose:
//
//   _failNameExposedDots: #Component & {
//   	metadata: {name: "web", resourceName: "web.internal"}
//   	#resources: container: _pinNameContainer & _pinNameStateless
//   	#traits: "opmodel.dev/catalogs/opm/traits/expose@v1beta1": _pinNameExpose
//   	#instance: _pinNameInstance
//   }
//
//   _failNameExposedDots._nameFits: invalid value "web.internal"
//     (out of bound =~"^[a-z]([a-z0-9-]*[a-z0-9])?$")
//
// Leading-digit instance + Expose — the hole #NameType alone left open:
//
//   _failNameLeadingDigit: #Component & {
//   	metadata: name: "web"
//   	#resources: container: _pinNameContainer & _pinNameStateless
//   	#traits: "opmodel.dev/catalogs/opm/traits/expose@v1beta1": _pinNameExpose
//   	#instance: {name: "1prod", namespace: "media"}
//   }
//
//   _failNameLeadingDigit._nameFits: invalid value "1prod-web"
//     (out of bound =~"^[a-z]([a-z0-9-]*[a-z0-9])?$")
//
// Raw stateful container, dotted override (D23):
//
//   _failNameStatefulDots: #Component & {
//   	metadata: {name: "cache", resourceName: "cache.internal"}
//   	#resources: container: _pinNameContainer & _pinNameStateful
//   	#instance: _pinNameInstance
//   }
//
//   _failNameStatefulDots._nameFits: invalid value "cache.internal"
//     (out of bound =~"^[a-z0-9]([a-z0-9-]*[a-z0-9])?$")
//
// 65-rune default on a raw stateful container (the label rule's length axis):
//
//   _failNameStatefulLong: #Component & {
//   	metadata: name: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
//   	#resources: container: _pinNameContainer & _pinNameStateful
//   	#instance: _pinNameInstance
//   }
//
//   _failNameStatefulLong._nameFits: invalid value "prod-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
//     (does not satisfy strings.MaxRunes(63))
//
// 254-rune override, no constraint — the #ObjectNameType ceiling, via the
// error() arm:
//
//   _failNameOverlongOverride: #Component & {
//   	metadata: {name: "x", resourceName: "<254 × a>"}
//   	#resources: container: _pinNameContainer & _pinNameStateless
//   	#instance: _pinNameInstance
//   }
//
//   _failNameOverlongOverride.metadata.resourceName: resourceName "aaa…" is
//     not a DNS subdomain (lowercase alphanumerics, hyphens and dots, 1-253
//     runes)
//
// An invalid explicit name, one message, no default-arm leak:
//
//   _failNameBad: #Component & {
//   	metadata: {name: "x", resourceName: "Bad_Name"}
//   	#resources: container: _pinNameContainer & _pinNameStateless
//   	#instance: _pinNameInstance
//   }
//
//   _failNameBad.metadata.resourceName: resourceName "Bad_Name" is not a DNS
//     subdomain (lowercase alphanumerics, hyphens and dots, 1-253 runes)

// ─── #ComponentNames admits what #Component admits ──────────────────────────
//
// The projection shape in module_context.cue must not be narrower than the
// field it projects: a dotted override unified through it must survive.
// Measured before the fix: `resourceName!: #NameType` there refused this.
_pinNameProjection:     #ComponentNames & _pinNameDottedOverride.#names
_pinNameProjectionFqdn: "\(_pinNameProjection.dns.fqdn)"
_pinNameProjectionFqdn: "metrics.internal.example.media.svc.cluster.local"
