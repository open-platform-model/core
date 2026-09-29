package core

// Schema-level pins for #Module.initValues (enhancement 0016 D3/D4).
//
// Hidden top-level fields, as in identity_pins.cue: `cue vet` evaluates them
// and fails on a conflict, an importing package never does, and they add no
// row to src/INDEX.md. The one MUST-FAIL case is commented out at the bottom
// with the error `task vet` printed when it was uncommented at the commit
// that introduced it.
//
// NOTE ON THE FILENAME: no leading underscore, or CUE skips the file and every
// pin below vets clean by never running.

// ─── The base every module pin shares ──────────────────────────────────────

// Plain struct, not a #Module, so each pin below differs from the others only
// in the fields it adds.
_pinInitBase: {
	metadata: {
		name:       "web"
		modulePath: "example.com/modules/web@v1"
		version:    "1.0.0"
	}
	#config: {
		replicas: int
		logLevel: "info" | "debug"
		port?:    int
	}
}

// A module that validated before initValues existed. The field stays absent.
_pinInitPlain:  #Module & _pinInitBase
_pinInitAbsent: (_pinInitPlain.initValues == _|_) & true

// ─── What #Module accepts in initValues ────────────────────────────────────

// Concrete initValues validate and read back as written.
_pinInitConcrete: #Module & _pinInitBase & {
	initValues: {replicas: 2, logLevel: "info"}
}
_pinInitConcreteReadBack: _pinInitConcrete.initValues & {replicas: 2, logLevel: "info"}
_pinInitConcreteReplicas: _pinInitConcrete.initValues.replicas & 2

// Non-concrete initValues validate: a default, an undefaulted disjunction (the
// "pick one" prompt) and an optional field.
_pinInitOpen: #Module & _pinInitBase & {
	initValues: {replicas: *2 | int, logLevel: "info" | "debug", port?: int}
}

// Both branches unify only while the disjunction survives; a value collapsed
// to one branch fails the other pin.
_pinInitDisjunctionInfo:  _pinInitOpen.initValues.logLevel & "info"
_pinInitDisjunctionDebug: _pinInitOpen.initValues.logLevel & "debug"

// ─── initValues is not checked against #config ─────────────────────────────

// "two" does not satisfy `replicas: int`, and the module still validates.
_pinInitNonConforming: #Module & _pinInitBase & {
	initValues: {replicas: "two"}
}

// ─── initValues is inert for debugValues and identity ──────────────────────

// Both fields, different content: each reads back its own.
_pinInitBoth: #Module & _pinInitBase & {
	debugValues: {logLevel: "debug"}
	initValues: {logLevel: "info"}
}
_pinInitBothDebug: _pinInitBoth.debugValues.logLevel & "debug"
_pinInitBothInit:  _pinInitBoth.initValues.logLevel & "info"

// Setting initValues does not move the module's identity.
_pinInitSameModuleUUID: _pinInitPlain.metadata.uuid & _pinInitConcrete.metadata.uuid
_pinInitSameModuleFQN:  _pinInitPlain.metadata.fqn & _pinInitConcrete.metadata.fqn

// The same instance deploying the plain module and the one with non-concrete
// initValues: both validate, and the instance uuid does not move.
_pinInitInstancePlain: #ModuleInstance & {
	metadata: {
		name:      "web-prod"
		namespace: "prod"
	}
	#module: _pinInitPlain
	values: {replicas: 3, logLevel: "info"}
}

_pinInitInstance: #ModuleInstance & {
	metadata: {
		name:      "web-prod"
		namespace: "prod"
	}
	#module: _pinInitOpen
	values: {replicas: 3, logLevel: "info"}
}

_pinInitSameInstanceUUID: _pinInitInstancePlain.metadata.uuid & _pinInitInstance.metadata.uuid

// Beyond the uuid, the instance's derived metadata does not move either: the
// same fqn and the same labels, owner label included. Unifying the two label
// maps catches a changed value; the length check catches an added key.
_pinInitSameInstanceFQN:         _pinInitInstancePlain.metadata.fqn & _pinInitInstance.metadata.fqn
_pinInitSameInstanceLabels:      _pinInitInstancePlain.metadata.labels & _pinInitInstance.metadata.labels
_pinInitSameInstanceLabelsCount: len(_pinInitInstancePlain.metadata.labels) & len(_pinInitInstance.metadata.labels)

// ─── MUST-FAIL: #Module stays closed ───────────────────────────────────────

// A misspelled sibling is still refused. Measured 2026-09-29 with `task vet`:
//   _pinInitTypo.initValuez: field not allowed
//
// _pinInitTypo: #Module & _pinInitBase & {initValuez: {}}
