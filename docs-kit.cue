// core's docs bundle (docs-kit docs/contracts.md C6, C15, C17): the
// definitions reference generated from src/, plus the authored pages under
// docs/site/, in one bundle (docs-kit DESIGN decision 20). opm-docs builds
// it (task docs:bundle, task docs:bundle:check); docs.yml and release.yml
// publish it to ghcr.io/open-platform-model/docs/core.
//
// Every exported definition in src/ goes on exactly one page or in exclude
// with a reason, or the build fails.
bundles: core: {
	placement: {kind: "docs", root: "/docs/", owns: ["reference/definitions/"]}
	version: {from: "tag", prefix: "v"}
	sources: [{
		kind:    "cue-definitions"
		package: "./src"
		// The pins live in src/pins/ since core PR 103; releases before it,
		// v2.0.0-beta.1 among them, carry them in src/ beside the schema.
		skip: ["*_pins.cue"]
		section:     "reference/definitions/"
		title:       "Definitions"
		description: "Every OPM definition type, generated from the CUE schema in core."
		weight:      1
		intro:       "Every definition below belongs to `opmodel.dev/core@v2`, the CUE module every OPM artifact is typed against. An entry's summary, notes and field comments come from the definition's doc comment; its spec, the definitions it uses and the rules CUE enforces are read off the CUE source."
		pages: [
			{
				file:        "modules-and-instances"
				title:       "Modules and instances"
				description: "The module an author publishes, the instance that deploys it, and the identity the instance hands its components."
				definitions: ["#Module", "#ModuleInstance", "#InstanceIdentity"]
			},
			{
				file:        "components"
				title:       "Components"
				description: "The component a module is built from, and the names it computes for itself."
				definitions: ["#Component", "#ComponentNames"]
			},
			{
				file:        "resources-traits-and-blueprints"
				title:       "Resources, traits and blueprints"
				description: "The three primitives a catalog defines and a component attaches."
				definitions: ["#Resource", "#Trait", "#Blueprint"]
			},
			{
				file:        "transformers"
				title:       "Transformers"
				description: "The transformer that turns a matched component into platform objects, and the context it renders with."
				definitions: ["#ComponentTransformer", "#TransformerContext"]
			},
			{
				file:        "catalogs-and-platforms"
				title:       "Catalogs and platforms"
				description: "The catalog that publishes contracts and transformers, and the platform that admits catalogs."
				definitions: ["#Catalog", "#Platform", "#CatalogEntry", "#ContractInventory"]
			},
			{
				file:        "publish-gates"
				title:       "Publish gates"
				description: "The definitions a publishing tool unifies an artifact against before it publishes."
				definitions: ["#IdentityPackage", "#CatalogMemberFQNGate", "#TraitOptionalGate"]
			},
			{
				file:        "secrets-and-config"
				title:       "Secrets and configuration"
				description: "The secret type module authors put on sensitive values, and the Secret and ConfigMap schemas catalogs build on."
				definitions: ["#Secret", "#SecretType", "#SecretLiteral", "#SecretK8sRef", "#AutoSecrets", "#SecretSchema", "#ConfigMapSchema"]
			},
			{
				file:        "names-paths-and-versions"
				title:       "Names, paths and versions"
				description: "The constraint types for names, module and package paths, versions, keys and labels."
				definitions: ["#NameType", "#ObjectNameType", "#ServiceNameType", "#SnakeNameType", "#ModulePathType", "#PackagePathType", "#ArtifactRef", "#MajorVersionType", "#APIVersionType", "#APIVersionGated", "#VersionType", "#ContractFQNType", "#ImplFQNType", "#FQNType", "#UUIDType", "#LabelsAnnotationsType"]
			},
		]
		exclude: {
			"#BlueprintMap":        "map shorthand"
			"#ComponentMap":        "map shorthand"
			"#ModuleMap":           "map shorthand"
			"#ModuleInstanceMap":   "map shorthand"
			"#ResourceMap":         "map shorthand"
			"#TraitMap":            "map shorthand"
			"#TransformerMap":      "map shorthand"
			"#KebabToPascal":       "string helper"
			"#KebabToCamel":        "string helper"
			"#DiscoverSecrets":     "internal step of #AutoSecrets"
			"#GroupSecrets":        "internal step of #AutoSecrets"
			"#ContentHash":         "naming helper for transformers"
			"#SecretContentHash":   "naming helper for transformers"
			"#ImmutableName":       "naming helper for transformers"
			"#SecretImmutableName": "naming helper for transformers"
			"#BundleFQNType":       "types #Bundle, which core does not define"
		}
	}, {
		// The authored pages.
		kind: "markdown"
		dir:  "docs/site"
	}]
}
