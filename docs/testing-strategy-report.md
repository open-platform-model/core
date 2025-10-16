# Testing Strategy Report: OPM Core Module System

**Date:** 2025-10-16
**Version:** 1.0
**Status:** Recommendation

---

## Executive Summary

This report provides recommendations for integrating testing into the Open Platform Model (OPM) core module system, specifically focusing on `ModuleDefinition` and `Module` types. The key insight driving this strategy is: **leverage CUE's constraint system for validation, reserve testing for complex behavioral logic**.

### Key Recommendations

1. **Use CUE constraints for structural validation** - Don't write tests for what CUE can validate natively
2. **Implement inline tests for behavioral logic** - Test computed values, transformations, and multi-step processes
3. **Add contract-based validation** - Ensure architectural invariants are maintained
4. **Create targeted integration tests** - Test cross-component interactions and value flow

---

## Philosophy: Don't Test What CUE Already Validates

### The Problem with Over-Testing in CUE

Many testing patterns from imperative languages don't make sense in CUE:

```cue
// ❌ BAD: Testing what CUE already validates
testModuleHasComponents: {
    subject: opm.#ModuleDefinition & {
        components: {
            web: core.#StatelessWorkload & {...}
        }
    }
    // Pointless assertion - CUE already ensures this
    result: len(subject.components) > 0
    result: 1
}
```

**Why this is bad:**

- CUE's type system already ensures `components` exists and has the correct structure
- If `components` were required to be non-empty, this should be a **constraint**, not a **test**
- Tests add maintenance burden without providing value

### The CUE Way: Constraints Over Tests

```cue
// ✅ GOOD: Define constraint directly in type definition
#ModuleDefinition: {
    #kind: "ModuleDefinition"
    #apiVersion: "core.opm.dev/v1"

    // Existing fields...
    components: [Id=string]: #Component

    // Add validation constraint
    _validateNonEmpty: len(components) > 0 |
        error("ModuleDefinition must have at least one component")
}
```

**Why this is better:**

- Fails immediately when violated (fail-fast)
- Self-documenting (shows intent in type definition)
- No separate test maintenance
- Cannot be forgotten or skipped
- Provides clear error message to users

---

## What Should NOT Be Tested (Use Constraints Instead)

### Category 1: Structural Validation

**Use constraints, not tests, for:**

1. **Field presence/absence**

   ```cue
   // ❌ Don't test
   test: subject.#metadata.name != _|_

   // ✅ Use constraint
   #metadata: name!: string  // Required field
   ```

2. **Type correctness**

   ```cue
   // ❌ Don't test
   test: (subject.values.replicas & int) != _|_

   // ✅ Use constraint
   values: replicas?: uint  // Type enforced
   ```

3. **Value ranges**

   ```cue
   // ❌ Don't test
   test: subject.values.replicas > 0

   // ✅ Use constraint
   values: replicas?: uint & >0  // Enforced at definition
   ```

4. **String patterns**

   ```cue
   // ❌ Don't test
   test: subject.#metadata.version =~ "^\\d+\\.\\d+\\.\\d+$"

   // ✅ Use constraint
   #metadata: version!: string & =~"^\\d+\\.\\d+\\.\\d+$"
   ```

5. **Required relationships**

   ```cue
   // ❌ Don't test
   test: len(subject.#elements) == 1  // Scopes have single trait

   // ✅ Use constraint
   #Scope: {
       #elements: [string]: #Element
       _validateSingleTrait: len(#elements) == 1 |
           error("Scope must have exactly one trait element")
   }
   ```

### Category 2: Simple Computations

**Use constraints, not tests, for:**

1. **Field derivations**

   ```cue
   // ❌ Don't test
   test: subject.#metadata.name == subject.#metadata.#id

   // ✅ Define derivation
   #metadata: {
       #id: string
       name: string | *#id  // Defaults to #id
   }
   ```

2. **Count aggregations**

   ```cue
   // ❌ Don't test
   test: subject.#status.componentCount == len(subject.components)

   // ✅ Define computation
   #status: componentCount: len(components)
   ```

3. **Boolean flags**

   ```cue
   // ❌ Don't test
   test: subject.#status.hasComponents == (len(subject.components) > 0)

   // ✅ Define computation
   #status: hasComponents: len(components) > 0
   ```

---

## What SHOULD Be Tested (Complex Behavioral Logic)

### Category 1: Multi-Step Transformations

**Write tests for complex transformations that involve multiple steps:**

```cue
// ✅ GOOD: Test composite element field flattening
"composite/field-flattening": {
    subject: core.#StatelessWorkload & {
        statelessWorkload: {
            container: {
                image: "nginx:latest"
                name: "web"
            }
            replicas: count: 3
            healthCheck: {
                httpGet: {
                    path: "/health"
                    port: 8080
                }
            }
        }
    }

    // Test that nested fields are correctly flattened
    subject.container.image: "nginx:latest"
    subject.replicas.count: 3
    subject.healthCheck.httpGet.path: "/health"

    // Test conditional flattening
    if subject.statelessWorkload.updateStrategy != _|_ {
        subject.updateStrategy: subject.statelessWorkload.updateStrategy
    }
}
```

**Why test this:**

- Involves conditional logic (`if` statements)
- Multiple template transformations
- Non-obvious behavior that could break
- Documents expected flattening behavior

### Category 2: Recursive Operations

**Write tests for recursive algorithms:**

```cue
// ✅ GOOD: Test recursive primitive extraction
"element/recursive-primitive-extraction": {
    // Deeply nested composite
    subject: #Composite & {
        name: "ComplexWorkload"
        composes: [
            #StatelessWorkloadElement,  // Contains Container, Replicas, etc.
            #ExposeElement,             // Primitive
            #HealthCheckElement,        // Primitive
        ]
    }

    // StatelessWorkload itself composes primitives
    _statelessPrimitives: [
        "elements.opm.dev/core/v0.Container",
        "elements.opm.dev/core/v0.Replicas",
        "elements.opm.dev/core/v0.RestartPolicy",
        "elements.opm.dev/core/v0.UpdateStrategy",
    ]

    // Test recursive extraction includes all nested primitives
    subject.#primitiveElements: list.Concat([
        _statelessPrimitives,
        ["elements.opm.dev/core/v0.Expose"],
        ["elements.opm.dev/core/v0.HealthCheck"],
    ])
}
```

**Why test this:**

- Recursive logic is error-prone
- Edge cases (deeply nested, circular references)
- Non-trivial algorithm behavior

### Category 3: Value Flow Through Layers

**Write tests for value inheritance/unification across module layers:**

```cue
// ✅ GOOD: Test value flow ModuleDefinition → Module → ModuleRelease
"values/three-layer-flow": {
    // Layer 1: ModuleDefinition (constraints only)
    definition: opm.#ModuleDefinition & {
        values: {
            replicas?: uint            // Constraint: must be uint
            image?: string             // Constraint: must be string
            region?: "us-east" | "us-west"  // Constraint: enum
        }
    }

    // Layer 2: Module (adds defaults and refinements)
    module: opm.#Module & {
        moduleDefinition: definition
        values: {
            replicas: uint | *3        // Add default
            image: string & =~".*\\.myplatform\\.com$"  // Refine constraint
            region: "us-east" | "us-west" | *"us-east"  // Add default
        }
    }

    // Layer 3: ModuleRelease (user concrete values)
    release: opm.#ModuleRelease & {
        module: module
        values: {
            replicas: 5                // Override default
            image: "nginx.myplatform.com/nginx:1.25"  // Concrete value
            // region: uses module default "us-east"
        }
    }

    // Test final unified values
    release.values: {
        replicas: 5
        image: "nginx.myplatform.com/nginx:1.25"
        region: "us-east"
    }
}
```

**Why test this:**

- Multi-layer unification is complex
- Easy to break with refactoring
- Documents intended value flow pattern
- Validates constraint refinement works correctly

### Category 4: Component/Scope Merging

**Write tests for merging definition and platform components:**

```cue
// ✅ GOOD: Test platform additions don't override definition
"module/platform-addition-validation": {
    definition: opm.#ModuleDefinition & {
        components: {
            web: core.#StatelessWorkload & {
                statelessWorkload: container: {
                    name: "web"
                    image: "nginx:latest"
                }
            }
        }
    }

    module: opm.#Module & {
        moduleDefinition: definition

        // Platform adds monitoring (should succeed)
        components: {
            monitoring: core.#DaemonWorkload & {
                daemonWorkload: container: {
                    name: "prometheus"
                    image: "prometheus:latest"
                }
            }
        }
    }

    // Test both components present in unified view
    module.#allComponents: {
        web: _        // From definition
        monitoring: _ // From platform
    }

    // Test counts computed correctly
    module.#status: {
        totalComponentCount: 2
        platformComponentCount: 1
    }

    // Test definition component preserved exactly
    module.#allComponents.web.container.image: "nginx:latest"
}
```

**Why test this:**

- Complex merging logic with business rules
- Must prevent platform from overriding definition
- Non-obvious computation of counts
- Documents platform extension pattern

### Category 5: Provider Selection & Transformer Matching

**Write tests for transformer selection algorithm:**

```cue
// ✅ GOOD: Test transformer selection matches primitives correctly
"provider/transformer-selection": {
    component: opm.#Component & {
        #primitiveElements: [
            "elements.opm.dev/core/v0.Container",
            "elements.opm.dev/core/v0.Volume",
        ]
    }

    provider: opm.#Provider & {
        transformers: {
            Deployment: {
                required: ["elements.opm.dev/core/v0.Container"]
                optional: [
                    "elements.opm.dev/core/v0.Replicas",
                    "elements.opm.dev/core/v0.HealthCheck",
                ]
            }
            PersistentVolumeClaim: {
                required: ["elements.opm.dev/core/v0.Volume"]
            }
        }
    }

    selector: opm.#SelectTransformer & {
        component: component
        availableTransformers: provider.transformers
    }

    // Test correct transformers selected for each primitive
    selector.selectedTransformers: [
        {
            primitive: "elements.opm.dev/core/v0.Container"
            transformer: "k8s.io/api/apps/v1.Deployment"
        },
        {
            primitive: "elements.opm.dev/core/v0.Volume"
            transformer: "k8s.io/api/core/v1.PersistentVolumeClaim"
        },
    ]
}
```

**Why test this:**

- Complex matching algorithm (O(n*m) optimization)
- Critical path for rendering
- Multiple edge cases (no match, multiple matches, optional elements)
- Currently identified as a **test coverage gap**

### Category 6: Catalog Validation

**Write tests for admission validation logic:**

```cue
// ✅ GOOD: Test module admission validation
"catalog/admission-validation": {
    catalog: opm.#PlatformCatalog & {
        #availableElements: {
            "elements.opm.dev/core/v0.Container": core.#ContainerElement
            "elements.opm.dev/core/v0.Volume": core.#VolumeElement
            // Note: Expose element NOT in catalog
        }

        providers: {
            kubernetes: {
                transformers: {
                    Deployment: {
                        required: ["elements.opm.dev/core/v0.Container"]
                    }
                    // Note: No transformer for Volume
                }
            }
        }
    }

    module: opm.#Module & {
        components: {
            web: {
                #primitiveElements: [
                    "elements.opm.dev/core/v0.Container",
                    "elements.opm.dev/core/v0.Volume",
                    "elements.opm.dev/core/v0.Expose",  // Not in catalog
                ]
            }
        }
    }

    validation: opm.#ValidateModuleAdmission & {
        catalog: catalog
        module: module
        targetProvider: "kubernetes"
    }

    // Test validation catches missing elements
    validation.result.valid: false
    validation.result.missingInCatalog: [
        "elements.opm.dev/core/v0.Expose",
    ]
    validation.result.unsupportedByProvider: [
        "elements.opm.dev/core/v0.Volume",
    ]

    // Test admission denied
    validation.admitted: false
}
```

**Why test this:**

- Complex multi-step validation
- Critical for platform admission decisions
- Multiple validation paths
- Documents validation behavior

---

## Recommended Testing Strategy

### Tier 1: Built-in Constraints (Always On)

**Implementation:** Enhance type definitions with validation constraints

**File:** `core/module.cue`

```cue
#ModuleDefinition: {
    #kind: "ModuleDefinition"
    #apiVersion: "core.opm.dev/v1"

    // Existing fields...
    #metadata: {
        name!: string & =~"^[a-z0-9-]+$" |
            error("name must be lowercase alphanumeric with hyphens")
        version!: #VersionType |
            error("version must be valid semver")
    }

    components: [Id=string]: #Component

    // Validation: Must have at least one component
    _validateHasComponents: len(components) > 0 |
        error("ModuleDefinition must define at least one component")

    // Validation: Component IDs must match component metadata
    _validateComponentIds: {
        for id, comp in components {
            (id): comp.#metadata.#id == id |
                error("component ID '\(id)' doesn't match metadata.#id '\(comp.#metadata.#id)'")
        }
    }

    // Validation: Values should not contain concrete values (only constraints)
    // This is a guideline check - hard to enforce perfectly in CUE
    _validateValuesAreConstraints: {
        // Could add heuristics here if needed
        // For now, rely on documentation and convention
    }

    scopes?: [Id=string]: #ModuleScope

    values: {...} | *{}

    #status: {
        componentCount: len(components)
        scopeCount: len(scopes)
    }
}

#Module: {
    #kind: "Module"
    #apiVersion: "core.opm.dev/v1"

    moduleDefinition!: #ModuleDefinition

    components?: [Id=string]: #Component

    // Validation: Platform cannot override definition components
    _validateNoComponentOverride: {
        for id, _ in components {
            (id): moduleDefinition.components[id] == _|_ |
                error("platform cannot override definition component '\(id)'")
        }
    }

    scopes?: [Id=string]: #PlatformScope

    // Validation: Platform cannot override definition scopes
    _validateNoScopeOverride: {
        for id, _ in scopes {
            (id): moduleDefinition.scopes[id] == _|_ |
                error("platform cannot override definition scope '\(id)'")
        }
    }

    values?: {...}

    // Validation: Module values must be compatible with definition values
    _validateValuesCompatible: {
        _unified: moduleDefinition.values & values
        _unified: values  // Must unify successfully
    }

    // ... rest of Module definition
}

#Component: {
    #kind: "Component"
    #apiVersion: "core.opm.dev/v0"

    #metadata: {
        #id!: string
        name: string | *#id
        workloadType: string | *""
    }

    #elements: [string]: #Element

    // Validation: Must have at least one element
    _validateHasElements: len(#elements) > 0 |
        error("component '\(#metadata.#id)' must have at least one element")

    // Validation: All elements must have same workload type (if applicable)
    _validateSingleWorkloadType: {
        let types = [for _, elem in #elements
            if elem.annotations["core.opm.dev/workload-type"] != _|_ {
                elem.annotations["core.opm.dev/workload-type"]
            }
        ]
        let unique = list.UniqueItems(types)
        len(unique) <= 1 |
            error("component '\(#metadata.#id)' has multiple workload types: \(unique)")
    }

    // ... rest of Component definition
}

#Scope: {
    #kind: "Scope"
    #apiVersion: "core.opm.dev/v0"

    #metadata: {
        #id!: string
        name: string | *#id
        immutable: bool
    }

    #elements: [string]: #Element

    // Validation: Scope must have exactly one trait element
    _validateSingleTrait: len(#elements) == 1 |
        error("scope '\(#metadata.#id)' must have exactly one trait element, found \(len(#elements))")

    appliesTo!: [...#Component] | "*"

    // ... rest of Scope definition
}
```

**Benefits:**

- ✅ Zero maintenance overhead (runs automatically)
- ✅ Fail-fast on violations
- ✅ Clear error messages guide users
- ✅ Self-documenting constraints
- ✅ Cannot be bypassed or forgotten

**Coverage:**

- Field presence/types
- Value constraints
- Business rules (no overrides, single workload type, etc.)
- Structural invariants

---

### Tier 2: Behavioral Unit Tests (Targeted)

**Implementation:** Write tests for complex logic only

**File:** `core/tests/unit/module.cue` (enhance existing)

**What to test:**

1. ✅ Recursive primitive extraction from nested composites
2. ✅ Field flattening in composite elements
3. ✅ Value flow through ModuleDefinition → Module → ModuleRelease
4. ✅ Component/scope merging logic
5. ✅ Computed aggregations (#allComponents, #allPrimitiveElements)

**What NOT to test:**

1. ❌ Field presence (use constraints)
2. ❌ Type correctness (use constraints)
3. ❌ Simple computations like `len(components)` (use constraints)
4. ❌ Default value application (CUE handles this)

**Example test structure:**

```cue
// core/tests/unit/module.cue
package unit

import (
    opm "github.com/open-platform-model/core"
    core "github.com/open-platform-model/core/elements/core"
)

moduleTests: {
    //////////////////////////////////////////////////////////////////
    // Value Flow Tests (Behavioral - KEEP THESE)
    //////////////////////////////////////////////////////////////////

    "values/three-layer-unification": {
        // Test complex value flow as shown above
        // This tests BEHAVIOR, not structure
    }

    "values/constraint-refinement": {
        // Test that Module can refine ModuleDefinition constraints
        // This is non-trivial behavior worth testing
    }

    //////////////////////////////////////////////////////////////////
    // Component Merging Tests (Behavioral - KEEP THESE)
    //////////////////////////////////////////////////////////////////

    "module/component-merging-preserves-definition": {
        // Test that platform additions don't override definition
        // This tests BEHAVIOR enforced by constraints + merging logic
    }

    "module/allComponents-aggregation": {
        // Test #allComponents correctly merges definition + platform
        // This is computed behavior worth testing
    }

    //////////////////////////////////////////////////////////////////
    // REMOVE THESE (Redundant with Constraints)
    //////////////////////////////////////////////////////////////////

    // ❌ REMOVE: Constraint should handle this
    // "module-definition/has-components": {
    //     subject: opm.#ModuleDefinition & {...}
    //     result: len(subject.components) > 0
    // }

    // ❌ REMOVE: Status computation is simple, constraint can validate
    // "module-definition/status-component-count": {
    //     subject: opm.#ModuleDefinition & {
    //         components: {web: _, api: _}
    //     }
    //     subject.#status.componentCount: 2
    // }
}
```

---

### Tier 3: Provider/Transformer Tests (New - Fill Gap)

**Implementation:** Add missing unit tests for provider logic

**File:** `core/tests/unit/provider.cue` (NEW)

```cue
package unit

import (
    opm "github.com/open-platform-model/core"
    core "github.com/open-platform-model/core/elements/core"
)

providerTests: {
    //////////////////////////////////////////////////////////////////
    // Transformer Selection Tests (CRITICAL - MISSING)
    //////////////////////////////////////////////////////////////////

    "transformer/select-single-primitive": {
        // Test selecting transformer for single primitive element
        component: opm.#Component & {
            #primitiveElements: [
                "elements.opm.dev/core/v0.Container",
            ]
        }

        provider: opm.#Provider & {
            transformers: {
                Deployment: {
                    required: ["elements.opm.dev/core/v0.Container"]
                }
            }
        }

        selector: opm.#SelectTransformer & {
            component: component
            availableTransformers: provider.transformers
        }

        // Verify correct transformer selected
        selector.selectedTransformers: [{
            primitive: "elements.opm.dev/core/v0.Container"
            transformer: "k8s.io/api/apps/v1.Deployment"
        }]
    }

    "transformer/select-multiple-primitives": {
        // Test selecting transformers for multiple primitives
        // Component with Container + Volume should select Deployment + PVC
    }

    "transformer/no-match-primitive": {
        // Test behavior when primitive has no transformer
        // Should return empty or error appropriately
    }

    "transformer/optional-elements": {
        // Test that optional elements don't affect required matching
        // Deployment requires Container, has optional Replicas/HealthCheck
    }

    //////////////////////////////////////////////////////////////////
    // Provider Context Tests
    //////////////////////////////////////////////////////////////////

    "provider/context-label-merging": {
        // Test unifiedLabels merges module + component labels correctly
    }

    "provider/context-annotation-merging": {
        // Test unifiedAnnotations handles conflicts appropriately
    }

    //////////////////////////////////////////////////////////////////
    // Dependency Resolution Tests
    //////////////////////////////////////////////////////////////////

    "dependency/all-supported": {
        // Test #ModuleDependencyResolver when all elements supported
        module: opm.#Module & {
            #allPrimitiveElements: [
                "elements.opm.dev/core/v0.Container",
                "elements.opm.dev/core/v0.Volume",
            ]
        }

        provider: opm.#Provider & {
            #declaredElements: [
                "elements.opm.dev/core/v0.Container",
                "elements.opm.dev/core/v0.Volume",
                "elements.opm.dev/core/v0.ConfigMap",
            ]
        }

        resolver: opm.#ModuleDependencyResolver & {
            requiredElements: module.#allPrimitiveElements
            supportedElements: provider.#declaredElements
        }

        // All elements supported
        resolver.resolved: true
        resolver.unsupportedElements: []
    }

    "dependency/unsupported-elements": {
        // Test #ModuleDependencyResolver detects unsupported elements
        // Module requires [Container, Expose], Provider only supports [Container]
        // Should detect Expose as unsupported
    }
}
```

**Priority:** HIGH - This is an identified gap in test coverage

---

### Tier 4: Integration Tests (Realistic Scenarios)

**Implementation:** Keep existing integration tests, enhance with realistic scenarios

**File:** `core/tests/integration/*.cue` (enhance existing)

**Focus on:**

1. ✅ End-to-end value flow through all layers
2. ✅ Real-world application scenarios (3-tier apps, databases, etc.)
3. ✅ Platform composition patterns
4. ✅ Provider rendering (Component → Kubernetes resources)

**Keep tests that validate:**

- Multi-component interactions
- Cross-cutting concerns (scopes applied to multiple components)
- Value templating with conditionals
- Realistic module catalog scenarios

**Example realistic scenario:**

```cue
// core/tests/integration/real_world_scenarios.cue
package integration

import (
    opm "github.com/open-platform-model/core"
    core "github.com/open-platform-model/core/elements/core"
)

realWorldTests: {
    "scenario/three-tier-app-with-platform-additions": {
        // Developer defines 3-tier app
        definition: opm.#ModuleDefinition & {
            #metadata: {
                name: "ecommerce-app"
                version: "1.0.0"
            }

            components: {
                web: core.#StatelessWorkload & {
                    statelessWorkload: {
                        container: {
                            image: values.webImage
                            name: "web"
                            ports: http: {targetPort: 80}
                        }
                        replicas: count: values.webReplicas
                    }
                }

                api: core.#StatelessWorkload & {
                    statelessWorkload: {
                        container: {
                            image: values.apiImage
                            name: "api"
                            ports: http: {targetPort: 8080}
                        }
                        replicas: count: values.apiReplicas
                    }
                }

                db: core.#SimpleDatabase & {
                    simpleDatabase: {
                        engine: "postgres"
                        version: "15"
                        dbName: values.dbName
                        username: values.dbUser
                        password: values.dbPassword
                        persistence: {
                            enabled: true
                            size: values.dbSize
                        }
                    }
                }
            }

            values: {
                webImage?: string | *"nginx:latest"
                webReplicas?: uint | *3
                apiImage?: string | *"api:latest"
                apiReplicas?: uint | *3
                dbName?: string | *"ecommerce"
                dbUser?: string | *"app_user"
                dbPassword?: string  // No default - must be provided
                dbSize?: string | *"50Gi"
            }
        }

        // Platform adds observability and security
        module: opm.#Module & {
            moduleDefinition: definition

            // Platform adds monitoring
            components: {
                monitoring: core.#DaemonWorkload & {
                    daemonWorkload: container: {
                        name: "prometheus"
                        image: "prometheus:latest"
                    }
                }

                logging: core.#DaemonWorkload & {
                    daemonWorkload: container: {
                        name: "fluentd"
                        image: "fluentd:latest"
                    }
                }
            }

            // Platform adds security scope
            scopes: {
                security: opm.#PlatformScope & {
                    #metadata: {
                        #id: "security"
                        immutable: true
                    }
                    #elements: {
                        NetworkScope: core.#NetworkScopeElement
                    }
                    networkScope: networkPolicy: {
                        internalCommunication: true
                        externalCommunication: false
                    }
                    appliesTo: "*"
                }
            }

            // Platform refines values
            values: {
                // Enforce image registry constraint
                webImage: string & =~"^registry\\.myplatform\\.com/.*$"
                apiImage: string & =~"^registry\\.myplatform\\.com/.*$"

                // Add platform defaults
                webImage: "registry.myplatform.com/nginx:1.25"
                apiImage: "registry.myplatform.com/api:v2.1"

                // Enforce replica limits
                webReplicas: >=1 & <=10
                apiReplicas: >=1 & <=10
            }
        }

        // User deploys with overrides
        release: opm.#ModuleRelease & {
            module: module
            provider: kubernetesProvider

            values: {
                // User overrides
                webReplicas: 5
                apiReplicas: 3
                dbPassword: "supersecret123"
                dbSize: "100Gi"

                // Uses platform defaults for images
            }
        }

        // Validate final configuration
        release.values: {
            webImage: "registry.myplatform.com/nginx:1.25"
            webReplicas: 5
            apiImage: "registry.myplatform.com/api:v2.1"
            apiReplicas: 3
            dbName: "ecommerce"
            dbUser: "app_user"
            dbPassword: "supersecret123"
            dbSize: "100Gi"
        }

        // Validate component count
        release.module.#status.totalComponentCount: 5  // 3 app + 2 platform
        release.module.#status.platformComponentCount: 2

        // Validate all primitives collected
        let allPrimitives = release.module.#allPrimitiveElements
        // Should include Container (multiple), Volume (from db), etc.
        len(allPrimitives) > 0
    }
}
```

---

### Tier 5: Contract Validation (Architectural Invariants)

**Implementation:** Add contract validation for architectural rules

**File:** `core/tests/contracts/module_contracts.cue` (NEW)

```cue
package contracts

import (
    opm "github.com/open-platform-model/core"
    "list"
)

// Contract: ModuleDefinition architectural rules
#ModuleDefinitionContract: {
    subject: opm.#ModuleDefinition

    // Rule: Metadata must be complete
    _metadataComplete: {
        subject.#metadata.name != _|_ & subject.#metadata.name != ""
        subject.#metadata.version =~ "^\\d+\\.\\d+\\.\\d+"
    }

    // Rule: Must have at least one component
    // NOTE: This should actually be a constraint in #ModuleDefinition!
    // Leaving here as example of contract test
    _hasComponents: len(subject.components) > 0

    // Rule: Values should be constraints only (no concrete values)
    // This is a guideline - hard to enforce perfectly
    _valuesAreConstraints: {
        // Check for default markers or optional fields
        for field, value in subject.values {
            // All values should be optional (?) or have default marker (*)
            // This is more of a convention check
            true  // Placeholder - perfect detection is complex
        }
    }

    // Rule: All components must be valid
    _componentsValid: {
        for id, comp in subject.components {
            (id): {
                comp.#kind == "Component"
                comp.#metadata.#id == id
                len(comp.#primitiveElements) > 0
            }
        }
    }

    // Rule: All scopes must be valid
    _scopesValid: {
        for id, scope in subject.scopes {
            (id): {
                scope.#kind == "Scope"
                scope.#metadata.#id == id
                len(scope.#elements) == 1  // Single trait
            }
        }
    }
}

// Contract: Module must preserve ModuleDefinition
#ModulePreservationContract: {
    definition: opm.#ModuleDefinition
    module: opm.#Module

    // Rule: Module references the definition
    _referencesDefinition: module.moduleDefinition == definition

    // Rule: All definition components present in module
    _preservesComponents: {
        for id, _ in definition.components {
            (id): module.#allComponents[id] != _|_
        }
    }

    // Rule: All definition scopes present in module
    _preservesScopes: {
        for id, _ in definition.scopes {
            (id): module.#allScopes[id] != _|_
        }
    }

    // Rule: Platform cannot override definition components
    _noComponentOverride: {
        for id, _ in module.components {
            (id): definition.components[id] == _|_
        }
    }

    // Rule: Platform cannot override definition scopes
    _noScopeOverride: {
        for id, _ in module.scopes {
            (id): definition.scopes[id] == _|_
        }
    }

    // Rule: Module values compatible with definition
    _valuesCompatible: {
        _unified: definition.values & module.values
        _unified: module.values  // Must unify successfully
    }
}

// Contract: Module can be released with any valid provider
#ModuleReleaseContract: {
    module: opm.#Module
    release: opm.#ModuleRelease

    // Rule: Release references the module
    _referencesModule: release.module == module

    // Rule: Release has a provider
    _hasProvider: release.provider != _|_

    // Rule: Release values compatible with module
    _valuesCompatible: {
        _unified: module.values & release.values
        _unified: release.values
    }

    // Rule: All module primitives supported by provider
    _providerSupportsElements: {
        let required = module.#allPrimitiveElements
        let supported = release.provider.#declaredElements

        // All required must be in supported
        for elem in required {
            list.Contains(supported, elem)
        }
    }
}
```

**Usage in tests:**

```cue
// In any test file
"validate/module-definition-contract": {
    subject: myAppDefinition

    // Apply contract
    _contract: contracts.#ModuleDefinitionContract & {
        subject: subject
    }

    // Contract validates automatically via constraints
}
```

**Benefits:**

- ✅ Enforces architectural invariants
- ✅ Prevents contract violations
- ✅ Self-documenting architecture rules
- ✅ Can be applied to any module/definition

**Note:** Many contract rules should eventually move to being **constraints** in the type definitions themselves. Contracts are useful for:

1. Rules that span multiple types
2. Rules that are guidelines rather than hard requirements
3. Cross-cutting concerns that don't fit naturally in a single type

---

## Testing Priority Matrix

| Test Category | Priority | Effort | Current Status | Recommendation |
|---------------|----------|--------|----------------|----------------|
| **Structural Constraints** | P0 | Low | Partial | ✅ Add to type definitions |
| **Provider/Transformer Tests** | P0 | Medium | Missing | ✅ Implement immediately |
| **Value Flow Tests** | P1 | Low | Good | ✅ Keep existing |
| **Component Merging Tests** | P1 | Low | Good | ✅ Keep existing |
| **Integration Scenarios** | P1 | Medium | Good | ✅ Enhance with edge cases |
| **Contract Validation** | P2 | Medium | Missing | ✅ Add for major contracts |
| **Catalog Validation Tests** | P2 | Low | Partial | ✅ Expand coverage |
| **Negative Tests** | P2 | Medium | Sparse | ⚠️ Add gradually |
| **Edge Case Tests** | P3 | High | Sparse | ⚠️ Add as bugs found |

---

## Implementation Roadmap

### Phase 1: Add Constraints (Week 1)

**Goal:** Move structural validation from tests to type constraints

1. Enhance `#ModuleDefinition` with validation constraints
   - Non-empty components
   - Component ID consistency
   - Metadata completeness

2. Enhance `#Module` with validation constraints
   - No component override
   - No scope override
   - Values compatibility

3. Enhance `#Component` with validation constraints
   - Non-empty elements
   - Single workload type

4. Enhance `#Scope` with validation constraints
   - Single trait element
   - Valid appliesTo

**Deliverable:** All structural validations enforced automatically

---

### Phase 2: Fill Test Gaps (Week 2)

**Goal:** Add missing critical tests

1. Create `tests/unit/provider.cue`
   - Transformer selection tests (10+ test cases)
   - Provider context tests (5+ test cases)
   - Dependency resolution tests (5+ test cases)

2. Expand `tests/unit/module.cue`
   - Remove redundant structural tests
   - Keep behavioral tests
   - Add edge cases for value flow

3. Expand `tests/unit/component.cue`
   - Add complex recursive extraction tests
   - Add edge cases for field flattening

**Deliverable:** 80%+ coverage of complex behavioral logic

---

### Phase 3: Add Contracts (Week 3)

**Goal:** Enforce architectural invariants

1. Create `tests/contracts/module_contracts.cue`
   - ModuleDefinition contract
   - Module preservation contract
   - ModuleRelease contract

2. Apply contracts to existing examples
   - Validate all example modules pass contracts
   - Document contract patterns

3. Create contract validation tool
   - `cue cmd validate:contract -t module=myApp`

**Deliverable:** Architectural rules encoded and enforced

---

### Phase 4: Enhanced Integration Tests (Week 4)

**Goal:** Test realistic scenarios

1. Add real-world scenario tests
   - 3-tier applications
   - Microservices with service mesh
   - Stateful applications with persistence

2. Add negative scenario tests
   - Invalid configurations
   - Constraint violations
   - Unsupported elements

3. Add edge case tests
   - Empty/minimal modules
   - Maximum scale modules (50+ components)
   - Unicode/special characters

**Deliverable:** Comprehensive real-world test coverage

---

## Testing Anti-Patterns to Avoid

### Anti-Pattern 1: Testing CUE's Type System

```cue
// ❌ BAD: Testing that a string is a string
test: {
    subject: opm.#ModuleDefinition & {
        #metadata: name: "test"
    }
    result: (subject.#metadata.name & string) != _|_
    result: true
}
```

**Why bad:** CUE already guarantees `name` is a string. This test provides no value.

**Better:** Use a constraint if `name` needs additional validation (e.g., regex pattern)

---

### Anti-Pattern 2: Testing Simple Computations

```cue
// ❌ BAD: Testing that len() works correctly
test: {
    subject: {
        items: [1, 2, 3]
    }
    result: len(subject.items)
    result: 3
}
```

**Why bad:** Testing CUE's built-in `len()` function is pointless.

**Better:** Only test if the *logic choosing what to count* is complex

---

### Anti-Pattern 3: Testing Default Values

```cue
// ❌ BAD: Testing default value application
test: {
    subject: {
        value: int | *42
    }
    result: subject.value
    result: 42
}
```

**Why bad:** CUE handles default application automatically.

**Better:** Test that defaults *flow through multiple layers correctly* (e.g., ModuleDefinition → Module → ModuleRelease)

---

### Anti-Pattern 4: Over-Specifying Test Assertions

```cue
// ❌ BAD: Asserting every field when only one matters
test: {
    subject: myModule

    // All of these assertions when you only care about one field
    subject.#metadata.name: "test"
    subject.#metadata.version: "1.0.0"
    subject.#kind: "Module"
    subject.#apiVersion: "core.opm.dev/v1"
    subject.components.web.container.image: "nginx:latest"
    // ... 50 more lines ...
}
```

**Why bad:** Brittle - test breaks when unrelated fields change

**Better:** Only assert what you're testing

```cue
// ✅ GOOD: Assert only what matters for this test
test: {
    subject: myModule

    // Only testing that image value flows correctly
    subject.components.web.container.image: "nginx:latest"
}
```

---

## Test Maintenance Guidelines

### When to Add a Test

Add a test when:

1. ✅ Logic involves multiple steps or transformations
2. ✅ Behavior is non-obvious or could break during refactoring
3. ✅ You found a bug and want to prevent regression
4. ✅ Documentation would be insufficient to explain the behavior
5. ✅ Multiple components interact in complex ways

Do NOT add a test when:

1. ❌ A constraint could enforce the rule instead
2. ❌ CUE's type system already validates it
3. ❌ It's a simple field computation
4. ❌ It tests CUE language features, not OPM logic

### When to Remove a Test

Remove a test when:

1. ✅ Replaced by a constraint in the type definition
2. ✅ Testing behavior that's no longer relevant
3. ✅ Redundant with another test
4. ✅ Testing CUE features instead of OPM logic

### When to Convert Test to Constraint

Convert a test to a constraint when:

1. ✅ Rule is always true (invariant)
2. ✅ Violation should fail immediately (not just in tests)
3. ✅ Rule is structural rather than behavioral
4. ✅ Error message would help users more than developers

**Example:**

```cue
// Before: Test that catches issue only when running tests
"test/scope-single-trait": {
    subject: myScope
    result: len(subject.#elements)
    result: 1
}

// After: Constraint that always enforces rule
#Scope: {
    #elements: [string]: #Element
    _validateSingleTrait: len(#elements) == 1 |
        error("scope '\(#metadata.#id)' must have exactly one trait element")
}
```

---

## Metrics for Success

### Coverage Metrics

**Current State:**

- ~50 test cases
- ~70% behavioral logic covered
- 0% provider/transformer logic covered (identified gap)

**Target State (After Implementation):**

- ~80 test cases
- 90%+ complex behavioral logic covered
- 80%+ provider/transformer logic covered
- 100% architectural invariants enforced via constraints

### Quality Metrics

**Measure:**

1. **Test Maintenance Burden:** Time to update tests after refactoring
   - Target: <10% of refactoring time

2. **Bug Detection Rate:** Bugs caught by tests vs. found in usage
   - Target: >80% caught by tests

3. **False Positive Rate:** Tests failing when nothing is broken
   - Target: <5%

4. **Constraint Violation Rate:** How often users hit constraint errors
   - Target: >90% of structural errors caught by constraints, not tests

---

## Conclusion

### Key Takeaways

1. **Constraints > Tests for Structural Validation**
   - CUE's constraint system should be the first line of defense
   - Tests should focus on complex behavioral logic

2. **Don't Test CUE's Type System**
   - If CUE already validates it, don't write a test for it
   - Trust CUE to do what it's designed to do

3. **Test Complex Behavior, Not Simple Computations**
   - Multi-step transformations: YES
   - Recursive algorithms: YES
   - Simple field derivations: NO

4. **Provider/Transformer Testing is Critical Gap**
   - This is the highest priority missing test coverage
   - Complex selection logic needs thorough testing

5. **Integration Tests for Realistic Scenarios**
   - Keep integration tests focused on real-world usage
   - Test the "happy path" with realistic configurations

### Next Steps

1. **Immediate (This Week):**
   - Add `_validate*` constraints to `#ModuleDefinition`, `#Module`, `#Component`, `#Scope`
   - Create `tests/unit/provider.cue` with transformer selection tests

2. **Short-term (Next 2 Weeks):**
   - Review existing tests and remove redundant ones
   - Create `tests/contracts/module_contracts.cue`
   - Enhance integration tests with edge cases

3. **Long-term (Next Month):**
   - Establish testing guidelines for contributors
   - Create test generation helpers for common patterns
   - Monitor test maintenance burden and adjust strategy

---

**Document Version:** 1.0
**Last Updated:** 2025-10-16
**Next Review:** 2025-11-16
