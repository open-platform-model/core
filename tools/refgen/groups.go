package main

// page is one generated reference page: a group of definitions, in the
// order a reader meets them.
type page struct {
	file        string // kebab-case file name under the output directory
	title       string
	description string
	defs        []string
}

// pages is the inclusion list. Every exported top-level definition in a
// non-pins file of src/ must appear in exactly one page or in excluded; the
// generator refuses to run otherwise, so a new definition cannot be left out
// of the reference by accident.
var pages = []page{
	{
		file:        "modules-and-instances",
		title:       "Modules and instances",
		description: "The module an author publishes, the instance that deploys it, and the identity the instance hands its components.",
		defs:        []string{"#Module", "#ModuleInstance", "#InstanceIdentity"},
	},
	{
		file:        "components",
		title:       "Components",
		description: "The component a module is built from, and the names it computes for itself.",
		defs:        []string{"#Component", "#ComponentNames"},
	},
	{
		file:        "resources-traits-and-blueprints",
		title:       "Resources, traits and blueprints",
		description: "The three primitives a catalog defines and a component attaches.",
		defs:        []string{"#Resource", "#Trait", "#Blueprint"},
	},
	{
		file:        "transformers",
		title:       "Transformers",
		description: "The transformer that turns a matched component into platform objects, and the context it renders with.",
		defs:        []string{"#ComponentTransformer", "#TransformerContext"},
	},
	{
		file:        "catalogs-and-platforms",
		title:       "Catalogs and platforms",
		description: "The catalog that publishes contracts and transformers, and the platform that admits catalogs.",
		defs:        []string{"#Catalog", "#Platform", "#CatalogEntry", "#ContractInventory"},
	},
	{
		file:        "publish-gates",
		title:       "Publish gates",
		description: "The definitions a publishing tool unifies an artifact against before it publishes.",
		defs:        []string{"#IdentityPackage", "#CatalogMemberFQNGate", "#TraitOptionalGate"},
	},
	{
		file:        "secrets-and-config",
		title:       "Secrets and configuration",
		description: "The secret type module authors put on sensitive values, and the Secret and ConfigMap schemas catalogs build on.",
		defs:        []string{"#Secret", "#SecretType", "#SecretLiteral", "#SecretK8sRef", "#AutoSecrets", "#SecretSchema", "#ConfigMapSchema"},
	},
	{
		file:        "names-paths-and-versions",
		title:       "Names, paths and versions",
		description: "The constraint types for names, module and package paths, versions, keys and labels.",
		defs: []string{
			"#NameType", "#ObjectNameType", "#ServiceNameType", "#SnakeNameType",
			"#ModulePathType", "#PackagePathType", "#ArtifactRef",
			"#MajorVersionType", "#APIVersionType", "#APIVersionGated", "#VersionType",
			"#ContractFQNType", "#ImplFQNType", "#FQNType",
			"#UUIDType", "#LabelsAnnotationsType",
		},
	},
}

// excluded lists the exported definitions the reference leaves out, each with
// the reason. A reference to one of them is followed through to the included
// definitions it uses, so a map shorthand still links its element type.
var excluded = map[string]string{
	"#BlueprintMap":        "map shorthand",
	"#ComponentMap":        "map shorthand",
	"#ModuleMap":           "map shorthand",
	"#ModuleInstanceMap":   "map shorthand",
	"#ResourceMap":         "map shorthand",
	"#TraitMap":            "map shorthand",
	"#TransformerMap":      "map shorthand",
	"#KebabToPascal":       "string helper",
	"#KebabToCamel":        "string helper",
	"#DiscoverSecrets":     "internal step of #AutoSecrets",
	"#GroupSecrets":        "internal step of #AutoSecrets",
	"#ContentHash":         "naming helper for transformers",
	"#SecretContentHash":   "naming helper for transformers",
	"#ImmutableName":       "naming helper for transformers",
	"#SecretImmutableName": "naming helper for transformers",
	"#BundleFQNType":       "types #Bundle, which core does not define",
}
