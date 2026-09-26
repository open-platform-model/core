---
title: "What enforces a rule"
description: "The four places a rule can be enforced, from CUE to plain convention, and why it matters which one."
type: explanation
sidebar:
  order: 38
---

<!-- Open with OPM as the subject: OPM checks its rules in four places, and every rule on a Concepts or Reference page carries a badge naming the one that refuses a violation: `cue` (the value itself fails to evaluate), `kernel` (the render refuses it), `publish` (a publish command refuses the artifact) and `convention` (nothing refuses it). The page explains what each place can see, when a violation surfaces there, and why the badge matters: on the page a `convention` rule reads as firmly as a `cue` rule, and it is not. Check against: enhancements/0018/02-design.md (Enforcement badges), enhancements/0018/contracts/contracts.cue (#EnforcementLayer) 
Kubernetes comparison, only if it helps: weave it into the sentence that introduces the concept, or into How it works, never as a section of its own. Researched candidate: Nearest ideas: a custom resource's OpenAPI schema, which the API server uses to reject a malformed object on create; a controller, which accepts the object and then reports a failed condition when it cannot act on it; and the recommended `app.kubernetes.io/*` labels, which nothing enforces. `cue` is like the schema, `kernel` like the controller, `convention` like the recommended labels. Where it stops: in Kubernetes one API server sits in front of every write. OPM has no single gate. CUE runs wherever a module is evaluated, usually on the author's machine before any cluster is involved; the kernel runs the same way inside the CLI and inside the operator; and `publish` has no Kubernetes counterpart, because it runs only when an artifact is pushed with `opm module publish` or `opm catalog publish`. Check against: cli/internal/cmd/instance/vet.go, cli/internal/workflow/render/render.go, opm-operator/internal/render/kernel_module_renderer.go, cli/internal/publish/gates.go -->

## How it works

<!-- One diagram: a module's path from authoring to cluster, marking where each badge fires. Writing the module: `cue` fires at `cue vet`, `opm module vet` and every later load. Publishing: `publish` fires in `opm module publish` (a catalog's in `opm catalog publish`). Rendering against a platform: `kernel` fires in `opm instance vet`, `build`, `diff` and `apply`, in `opm module build` and `apply`, and in the operator's reconcile. `convention` fires nowhere. Show that a module rendered from a local directory never passes a publish gate. Check against: cli/internal/cmd/module/mod.go, cli/internal/cmd/instance/instance.go, cli/internal/publish/gates.go, library/opm/kernel/render.go -->

### Refused by CUE

<!-- What `cue` means: the rule is part of a core or catalog definition, so a violating value does not evaluate, and every tool that evaluates it fails the same way with CUE's own error. CUE sees one value and nothing outside it. Example: a module's `metadata.name` must equal the last segment of its `metadata.modulePath`. `name: "postgres"` with `modulePath: "opmodel.dev/modules/mysql@v1"` fails `cue vet` before any OPM tool runs, with `metadata._leaf: conflicting values false and true`. Check against: core/src/module.cue (_leaf), core/src/identity_pins.cue (_failLeafMismatch), core/src/types.cue (#SnakeNameType) -->

### Refused by the kernel at render

<!-- What `kernel` means: the rule depends on the platform, which one value cannot see, so the render checks it. The CLI and the operator both render through the same library kernel, so a refusal on a laptop is the same refusal in the cluster, given the same platform. Say which platform each command judges against: `opm instance vet` and `build` never read the cluster, so they use `--platform` or the local default; `apply` and `diff` use the cluster Platform when they can read it. Example: every resource a component declares is a required demand. If no transformer on the platform requires that contract key, the render fails with an unresolved demand (`component "<name>": unresolved resource demand "<fqn>"`, followed by which of three cases applies). In the CLI that fails `opm instance vet`, `build`, `diff` and `apply`; on the operator the ModuleInstance goes `Ready=False` with reason `ResolutionFailed`. Link Unresolved demands. Verify: the CLI and the operator can pin different library releases, so "the same refusal" holds only when their kernels match. Check against: library/opm/errors/match.go (UnresolvedDemand, UnresolvedDemandsError), library/opm/kernel/doc.go, cli/internal/workflow/render/env.go, cli/internal/cmd/instance/apply.go, cli/internal/cmd/instance/diff.go, opm-operator/internal/reconcile/resolution.go, core/SPEC.md (§3.1 Constraints on required demands) -->

### Refused at publish

<!-- What `publish` means: the rule is about how an artifact relates to something outside it (its identity file, its own published history, which layer wrote a value), so the publish command checks it before pushing. It protects consumers from a broken release and nothing else. Example: a beta or GA contract may only grow. `opm catalog publish` compares each beta or GA member with the newest published build that carried the same name and apiVersion, and refuses a removed field, a new required field, a changed or removed default, a narrowed domain or a field made required (`<repo> would break a contract it already published`). It skips alpha members, dev builds, and beta or GA members while the tag being published is a release prerelease. `opm catalog registry check --compat` runs the same comparison against published builds as a report. Link The Catalog Contract and Publish refusals. Check against: cli/internal/publish/compat.go, cli/internal/compat/compat.go (violation kinds), cli/internal/compat/level.go, cli/internal/cmd/catalog/registry.go -->

### Checked by nothing

<!-- What `convention` means: the rule is real and breaking it causes a failure somewhere, but no tool refuses the violation itself, so the failure surfaces later and points at the wrong place. Example: a module author writes defaults (`*`) only inside `#config` and puts plain values or references into component fields. Core's specification states it as a must, and nothing checks it; CUE cannot, because unification forgets which layer wrote a default. When a module's default meets a blueprint's default on the same field, the two cancel, and the render fails on a value that is not concrete, with an error that names neither author. Check against: core/SPEC.md (§6 Layering Contract, rules L4 and L5, and §6.1 on why CUE cannot enforce it), cli/internal/publish (no layering check exists) -->

## Why it is built this way

### Why one layer cannot hold every rule

<!-- Each layer sees a different amount. CUE sees one value, so it cannot know which transformers a platform carries; the render can. CUE cannot tell who wrote a value, so "a catalog may default a trait's `optional` but may not fix it" needs the publish step, which knows the value came from the catalog. And CUE forgets where a constraint came from, so the layering rules cannot be checked from the evaluated value at all. Check against: core/SPEC.md (§2.2 Rationale on `optional`, §5.1 Rationale, §6.1), core/src/trait.cue (#TraitOptionalGate) -->

### Why publish gates are CUE definitions

<!-- The rules the publish commands apply to catalogs and identity files (`#IdentityPackage`, `#CatalogMemberFQNGate`, `#TraitOptionalGate`) ship in core beside the shapes they check, and the CLI unifies against them instead of comparing strings in Go. The rule is written once, and the author reads CUE's own error at the field. Check against: core/SPEC.md (§5 Rationale), core/src/identity_package.cue, core/src/trait.cue, cli/internal/publish/identity.go, cli/internal/publish/catalog_gates.go -->

### Why an unmet demand fails the render

<!-- It used to render successfully: a component asking for a contract nothing on the platform implemented matched its other transformers, deployed without that part and reported success. Once a contract can be implemented by another catalog on another release schedule that is the ordinary case, so the render now refuses and names the contract. Check against: core/SPEC.md (§3.1 Rationale, "Why an unmet demand is an error at all"), library/opm/errors/match.go -->

### Why every rule carries a badge

<!-- OPM's specifications state rules as musts whether or not anything checks them, and the wording does not show the difference. The badge says what stops a violation and when, so a reader knows which rules they have to check themselves. Check against: enhancements/0018/01-problem.md ("Nothing tells a reader what stops them"), core/SPEC.md (§6.1) -->

## Common mistakes

### A must in the specification is not always enforced

<!-- Misreading: every MUST in core's specification is checked by a tool. Correct: some are conventions; the layering rules say so themselves. A second case: core's specification says a trait attached to a component with no resource in the trait's `appliesTo` fails at unification, but nothing in core, the kernel or the CLI reads `appliesTo` today. Verify by vetting a component that attaches a trait outside its `appliesTo`, and badge the rule convention until something checks it. Check against: core/SPEC.md (§2.2 Constraints), core/src/trait.cue, core/src/component.cue, cli/internal/compat/compat.go -->

### A clean `cue vet` does not mean the module renders

<!-- Misreading: a module that passes `cue vet` or `opm module vet` will deploy. Correct: those check the module alone. Whether its components match transformers on a given platform is a kernel check, so run `opm instance vet` or `opm module build` against the platform you deploy to. Check against: cli/internal/cmd/module/vet.go, cli/internal/cmd/instance/vet.go, library/opm/kernel/doc.go -->

### Publish gates guard only what was published through them

<!-- Misreading: anything in an OPM registry has passed the publish gates. Correct: only artifacts pushed with `opm module publish` or `opm catalog publish` have; plain `cue mod publish` pushes without them, and the registry does not record which path an artifact took. A module rendered from a local directory never meets a publish gate. Check against: cli/internal/publish/gates.go, cli/internal/publish/registry.go, catalog_opm/docs/site/reference/catalog-contract.md -->

### `opm module vet` runs several publish checks early

<!-- Misreading: a `publish` badge means the problem shows up only at publish. Correct: `opm module vet` runs part of the module publish checks: the identity file against `#IdentityPackage`, `metadata` against the identity file, `cue.mod` against the declared path, the version major against the path major, and whether the kernel can load the module. The badge names the point where the check is certain to run. Check against: cli/internal/publish/vet.go (VetChecks), cli/internal/cmd/module/vet.go -->

### The alpha exemption covers only the compatibility check

<!-- Misreading: an alpha contract is exempt from publish checks. Correct: alpha members skip only the additive-only comparison; the check of each member's key, filing path and `catalogVersion`, and the check of a trait's `optional` posture, apply to every member at every level. Check against: cli/internal/publish/catalog_gates.go, cli/internal/publish/compat.go (eligibleByPackage) -->

## What enforces this

<!-- Recap the four example rules with their badges: a module's name equals its path's last segment (cue); every declared resource is a required demand (kernel); beta and GA contracts only grow (publish); defaults only inside `#config` (convention). Verify with the author which badge covers refusals that live in the CLI or the operator rather than in core, the kernel or a publish command: the CLI's pre-apply CRD and operator-version checks, the duplicate object identity refusal both frontends run through a library helper, and the operator's platform refusals such as `OverSubscribedContracts`. Check against: enhancements/0018/contracts/contracts.cue, cli/internal/inventory/gates.go, library/opm/helper/objectset/objectset.go, cli/internal/workflow/render/validation.go, opm-operator/internal/status/conditions.go -->
