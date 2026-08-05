package core

import (
	"strings"
)

#LabelsAnnotationsType: [string]: string | int | bool | [string | int | bool]

// NameType: RFC 1123 DNS label — lowercase alphanumeric with hyphens, max 63 chars
#NameType: string & =~"^[a-z0-9]([a-z0-9-]*[a-z0-9])?$" & strings.MinRunes(1) & strings.MaxRunes(63)

// SnakeNameType: snake_case projection of #NameType — lowercase alphanumeric
// with underscores. Same character budget as #NameType; differs only in the
// separator (`_` instead of `-`), making it a valid CUE identifier (and thus a
// usable CUE package name / registry-path leaf).
#SnakeNameType: string & =~"^[a-z0-9]([a-z0-9_]*[a-z0-9])?$" & strings.MinRunes(1) & strings.MaxRunes(63)

// ModulePathType: an artifact's complete CUE module path, major suffix
// mandatory. What #Module and #Catalog declare.
// Example: "opmodel.dev/modules/postgres@v2", "opmodel.dev/catalogs/opm@v1"
//
// It is the same string cue.mod/module.cue's `module:` field, the registry
// coordinate and an `import` statement already agree on, so the registry
// address is recoverable by reading one field rather than recomposed from a
// prefix and a name (enhancement 0010 D1).
//
// Underscores are permitted in path segments because a CUE module's package
// name is inferred from its path leaf, and only #SnakeNameType leaves are
// valid CUE identifiers (see above) — and under D8 a module path *ends in*
// the module's own snake_case name, so every multi-word name carries one.
// Hyphens stay legal in non-leaf segments so an organisation such as
// github.com/open-platform-model remains expressible; only the leaf is
// constrained, and #Module.metadata constrains it rather than this regex.
//
// The suffix-free form this type carried before D1 is #PackagePathType.
#ModulePathType: string & =~"^[a-z0-9._-]+(/[a-z0-9._-]+)*@v[0-9]+$" & strings.MinRunes(1) & strings.MaxRunes(254)

// PackagePathType: the path a *primitive* declares — a package path inside a
// module, carrying no major suffix. #Resource, #Trait, #Blueprint and
// #ComponentTransformer carry this; #Module and #Catalog carry
// #ModulePathType. Also the type of a major-free registry path — see
// #ArtifactRef.registryPath.
// Example: "opmodel.dev/catalogs/opm/resources", "opmodel.dev/catalogs/opm/traits"
//
// This is #ModulePathType's regex from before enhancement 0010 D1, verbatim,
// so no primitive value shipped by any catalog changes. The major is inert on
// a primitive: a @vN module publishes vN.* tags, so a primitive carrying its
// catalog's build version already states its catalog's major. It is also not a
// path anyone writes — a consumer imports opmodel.dev/catalogs/opm/resources
// with no suffix and CUE resolves the major from cue.mod's deps.
#PackagePathType: string & =~"^[a-z0-9._-]+(/[a-z0-9._-]+)*$" & strings.MinRunes(1) & strings.MaxRunes(254)

// MajorVersionType: major version prefix used in primitive FQNs
// Example: "v1", "v0"
#MajorVersionType: string & =~"^v[0-9]+$"

// ArtifactRef splits a complete module path into the OCI repository its tags
// live under and the major it declares. This is the one place in the schema a
// module path is decomposed: every "compose an address from a prefix and a
// name" site collapses into reading registryPath (enhancement 0010 D1).
//
// A module path carries at most one "@", always terminal, so SplitN(2) is
// exact. CUE has no string slicing, so a LastIndex-plus-slice form is
// unavailable.
#ArtifactRef: {
	modulePath!: #ModulePathType

	_p: strings.SplitN(modulePath, "@", 2)

	// registryPath: the OCI repository. Tags hang off this, and it is the
	// major-free identity of the artifact's lineage. Typed #PackagePathType so
	// a value still carrying a major is refused by the type rather than
	// silently yielding a second address.
	registryPath: #PackagePathType & _p[0]

	// major: the identity-bearing version component, read rather than parsed.
	major: #MajorVersionType & _p[1]

	// importPath: what an `import` statement and a cue.mod dependency key
	// carry. modulePath verbatim — nothing is recombined.
	importPath: modulePath
}

// ModuleFQNType: container-style FQN for #Module — path/name:semver
// Example: "opmodel.dev/modules/jellyfin:2.0.0"
#ModuleFQNType: string & =~"^[a-z0-9._-]+(/[a-z0-9._-]+)*/[a-z0-9]([a-z0-9-]*[a-z0-9])?:\\d+\\.\\d+\\.\\d+.*$"

// BundleFQNType: FQN for #Bundle — path/name:vN (major version)
// Example: "opmodel.dev/bundles/game-stack:v1"
#BundleFQNType: string & =~"^[a-z0-9._-]+(/[a-z0-9._-]+)*/[a-z0-9]([a-z0-9-]*[a-z0-9])?:v[0-9]+$"

// Semver 2.0
#VersionType: string & =~"^\\d+\\.\\d+\\.\\d+(-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"

// FQNType: primitive definition FQN — path/name@semver
// Example: "opmodel.dev/catalogs/opm/traits/scaling@1.0.0"
// Example: "opmodel.dev/catalogs/opm/blueprints/workload/stateless-workload@1.0.0"
// Example: "github.com/myorg/traits/network/expose@2.1.0-rc.1"
//
// Lifted from MAJOR-only (@vN) to SemVer 2.0 per enhancement 0001 D5:
// two builds of the same primitive at adjacent versions must occupy
// distinct keys so divergent definitions surface as structured errors
// at match time rather than silently colliding on a MAJOR bucket.
#FQNType: string & =~"^[a-z0-9._-]+(/[a-z0-9._-]+)*/[a-z0-9]([a-z0-9-]*[a-z0-9])?@\\d+\\.\\d+\\.\\d+(-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"

// UUIDType: RFC 4122 UUID in standard format (lowercase hex)
#UUIDType: string & =~"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"

// OPM namespace UUID for uuid computations via uuid.SHA1 (UUID v5).
// This UUID MUST remain immutable across all versions — it is the root namespace
// for all OPM uuid generation. The CLI uses the same constant.
OPMNamespace: "11bc6112-a6e8-4021-bec9-b3ad246f9466"

// KebabToPascal converts a kebab-case string to PascalCase.
// Usage: (#KebabToPascal & {"in": "stateless-workload"}).out => "StatelessWorkload"
#KebabToPascal: {
	X="in": string
	let _parts = strings.Split(X, "-")
	out: strings.Join([for p in _parts {
		let _runes = strings.Runes(p)
		strings.ToUpper(strings.SliceRunes(p, 0, 1)) + strings.SliceRunes(p, 1, len(_runes))
	}], "")
}

// KebabToSnake converts a kebab-case string to snake_case (hyphens → underscores).
// Usage: (#KebabToSnake & {"in": "zot-registry-ttl"}).out => "zot_registry_ttl"
#KebabToSnake: {
	X="in": string
	out:    strings.Replace(X, "-", "_", -1)
}

// KebabToCamel converts a kebab-case string to camelCase.
// Usage: (#KebabToCamel & {"in": "k8up-backup"}).out => "k8upBackup"
// The first segment stays lowercase; every subsequent segment is capitalized.
#KebabToCamel: {
	X="in": string
	let _parts = strings.Split(X, "-")
	out: strings.Join([for i, p in _parts {
		if i == 0 {p}
		if i > 0 {
			let _runes = strings.Runes(p)
			strings.ToUpper(strings.SliceRunes(p, 0, 1)) + strings.SliceRunes(p, 1, len(_runes))
		}
	}], "")
}
