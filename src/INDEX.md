# core — Definition Index

CUE module: `opmodel.dev/core@v2`

---

## Project Structure

```
+-- docs/
```

---

## Definitions

| Definition | File | Description |
|---|---|---|
| `#Blueprint` | `blueprint.cue` | #Blueprint: Defines a reusable blueprint that composes resources and traits into a higher-level abstraction |
| `#BlueprintMap` | `blueprint.cue` |  |
| `#Catalog` | `catalog.cue` | #Catalog: top-level catalog definition |
| `#Component` | `component.cue` |  |
| `#ComponentMap` | `component.cue` |  |
| `#LabelWorkloadType` | `component.cue` | Workload type label key |
| `#Module` | `module.cue` | #Module: The portable application blueprint created by developers and/or platform teams |
| `#ModuleMap` | `module.cue` |  |
| `#ComponentNames` | `module_context.cue` | #ComponentNames is the shape of the per-component computed-names projection |
| `#InstanceIdentity` | `module_context.cue` | #InstanceIdentity carries the deployment-scoped facts that compute per-component names and DNS variants |
| `#ModuleInstance` | `module_instance.cue` | #ModuleInstance: The concrete deployment instance Contains: Reference to Module, values, target namespace Users/deployment systems create this to deploy a specific version Was: #ModuleRelease (renamed in enhancement 0002) |
| `#ModuleInstanceMap` | `module_instance.cue` | Was: #ModuleReleaseMap (renamed in enhancement 0002) |
| `#Platform` | `platform.cue` | #Platform — path-keyed registry of catalog subscriptions plus kernel-filled materialization slots |
| `#Subscription` | `platform.cue` | #Subscription declares that a #Platform pulls primitives from a catalog published at a given CUE module path |
| `#SubscriptionFilter` | `platform.cue` | #SubscriptionFilter narrows the set of catalog builds a #Platform pulls from a subscribed registry path |
| `#Resource` | `resource.cue` | #Resource: Defines a resource of deployment within the system |
| `#ResourceMap` | `resource.cue` |  |
| `#AutoSecrets` | `schemas.cue` | #AutoSecrets discovers all #Secret instances from a resolved config and groups them by $secretName/$dataKey in one step |
| `#ConfigMapSchema` | `schemas.cue` | #ConfigMapSchema: ConfigMap specification |
| `#ContentHash` | `schemas.cue` | #ContentHash computes a deterministic 10-character hex hash of a string data map |
| `#DiscoverSecrets` | `schemas.cue` | #DiscoverSecrets walks a resolved config (up to 10 levels deep) and collects all fields whose value is a #Secret |
| `#GroupSecrets` | `schemas.cue` | #GroupSecrets takes a flat map of discovered secrets and groups them by $secretName, keyed by $dataKey |
| `#ImmutableName` | `schemas.cue` | #ImmutableName computes the K8s resource name for a ConfigMap |
| `#Secret` | `schemas.cue` | #Secret is the contract type that module authors place on sensitive fields |
| `#SecretContentHash` | `schemas.cue` | #SecretContentHash normalizes #Secret entries and plain strings to a string map, then delegates to #ContentHash |
| `#SecretImmutableName` | `schemas.cue` | #SecretImmutableName computes the K8s resource name for a Secret |
| `#SecretK8sRef` | `schemas.cue` | #SecretK8sRef: points to a pre-existing K8s Secret in the cluster |
| `#SecretLiteral` | `schemas.cue` | #SecretLiteral: user provides the actual value |
| `#SecretSchema` | `schemas.cue` | #SecretSchema: Secret specification for K8s Secret resources |
| `#SecretType` | `schemas.cue` |  |
| `#Trait` | `trait.cue` | #Trait: Defines additional behavior or characteristics that can be attached to components |
| `#TraitMap` | `trait.cue` |  |
| `#ComponentTransformer` | `transformer.cue` | #ComponentTransformer: Declares how to convert OPM components into platform-specific resources |
| `#TransformerContext` | `transformer.cue` | Provider context passed to transformers |
| `#TransformerMap` | `transformer.cue` | Map of transformers by fully qualified name |
| `#APIVersionGated` | `types.cue` | APIVersionGated reports whether the additive-only promise binds at a given apiVersion (enhancement 0010 D34): false at alpha, which promises nothing and whose publish gate is off, true at beta and GA, which are gated in full |
| `#APIVersionType` | `types.cue` | APIVersionType: a PRIMITIVE's contract level — the value its author moves when the primitive's shape breaks, independent of the catalog's module major and of the catalog's release SemVer (enhancement 0010 D4, D25) |
| `#ArtifactRef` | `types.cue` | ArtifactRef splits a complete module path into the OCI repository its tags live under and the major it declares |
| `#BundleFQNType` | `types.cue` | BundleFQNType: FQN for #Bundle — path/name:vN (major version) Example: "opmodel |
| `#ContractFQNType` | `types.cue` | ContractFQNType: what a module DEMANDS — path/name@vN, where vN is the primitive's own #APIVersionType (enhancement 0010 D4) |
| `#FQNType` | `types.cue` | FQNType: either form, for the map shapes that hold both |
| `#ImplFQNType` | `types.cue` | ImplFQNType: what a platform EXECUTES — path/name@semver, the full SemVer of the build the definition shipped in (enhancement 0010 D4) |
| `#KebabToCamel` | `types.cue` | KebabToCamel converts a kebab-case string to camelCase |
| `#KebabToPascal` | `types.cue` | KebabToPascal converts a kebab-case string to PascalCase |
| `#LabelsAnnotationsType` | `types.cue` |  |
| `#MajorVersionType` | `types.cue` | MajorVersionType: the identity-bearing version component of a CUE module path — what #ArtifactRef |
| `#ModulePathType` | `types.cue` | ModulePathType: an artifact's complete CUE module path, major suffix mandatory |
| `#NameType` | `types.cue` | NameType: RFC 1123 DNS label — lowercase alphanumeric with hyphens, max 63 chars |
| `#PackagePathType` | `types.cue` | PackagePathType: the path a *primitive* declares — a package path inside a module, carrying no major suffix |
| `#SnakeNameType` | `types.cue` | SnakeNameType: snake_case name — lowercase alphanumeric with underscores |
| `#UUIDType` | `types.cue` | UUIDType: RFC 4122 UUID in standard format (lowercase hex) |
| `#VersionType` | `types.cue` | Semver 2 |

---

