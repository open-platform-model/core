# OPM Elements Reference

This document catalogs the available elements (traits and resources) in the Open Platform Model architecture. Elements are the atomic building blocks that can be composed into components and ultimately assembled into modules.

## Element Architecture Overview

Elements in OPM follow a unified pattern based on the `#Element` foundation:

- **Type**: Either `trait` (behavioral capabilities) or `resource` (infrastructure primitives)
- **Kind**: `primitive`, `composite`, `modifier`, or `custom`
- **Target**: Where applicable - `component`, `scope`, or both
- **WorkloadType**: Optional field that claims a component's workload identity (see below)
- **Modifies**: For modifier elements, declares which primitives they can modify
- **Labels**: Systematic organization using labels like `core.opm.dev/category`

## Implementation Status

This document includes both implemented and planned elements:

- ✅ **Implemented** - Available in the current codebase
- 📋 **Planned** - Documented for future implementation

### Current Implementation Summary

**Implemented Elements:**

- **Workload**: ✅ Container (primitive), 8 modifiers, 5 composites
- **Data**: ✅ Volume, ConfigMap, Secret (primitive resources), SimpleDatabase (composite)
- **Connectivity**: ✅ NetworkScope (primitive), Expose (modifier)

**Planned Elements:**

- Additional workload, security, governance, observability, and connectivity elements documented below

### Workload Architecture Summary

> **Key Design Decision**: OPM uses `Container` as the single workload primitive, then provides **composite traits** that combine Container with modifiers for different workload patterns.
>
> **Architecture:**

> - ✅ `Container` (primitive trait) → The base container definition
> - ✅ `StatelessWorkload` (composite) → Container + Replicas + modifiers → Creates Deployment
> - ✅ `StatefulWorkload` (composite) → Container + Volume + modifiers → Creates StatefulSet
> - ✅ `DaemonSetWorkload` (composite) → Container + modifiers → Creates DaemonSet
> - ✅ `TaskWorkload` (composite) → Container + modifiers → Creates Job
> - ✅ `ScheduledTaskWorkload` (composite) → Container + modifiers → Creates CronJob
>
> Each composite sets a `workloadType` field that enforces single workload type per component. This eliminates ambiguity and provides clear platform resource mapping.

### WorkloadType Enforcement Mechanism

The `workloadType` field on elements is critical for component validation:

- **Purpose**: Ensures each component has exactly one workload type (stateless, stateful, daemonSet, task, scheduled-task, function)
- **Set By**: Any trait (primitive or composite) can declare a `workloadType`
- **Validation**: Components automatically reject multiple traits with conflicting `workloadType` values
- **Examples**:
  - ✅ `Container` primitive declares `workloadType: "stateless" | "stateful" | "daemonSet" | "task" | "scheduled-task"` (flexible)
  - ✅ `StatelessWorkload` composite declares `workloadType: "stateless"` (fixed)
  - ✅ `StatefulWorkload` composite declares `workloadType: "stateful"` (fixed)
  - ❌ Cannot use both `#StatelessWorkload` and `#StatefulWorkload` in same component (conflicting workloadTypes)

### Benefits of Composite Workload Elements

The OPM architecture uses composite workload elements (StatelessWorkload, StatefulWorkload, etc.) built on top of the Container primitive. This design provides:

1. **Clear Intent**: Developers explicitly declare what type of workload they're creating
2. **Direct Platform Mapping**: Each composite maps to exactly one platform resource (no ambiguity)
3. **Type Safety**: The `workloadType` field prevents mixing incompatible workload types
4. **Simpler Providers**: Transformers can match against composite elements that bundle all necessary primitives
5. **Better Validation**: Components validate that only one workloadType is present
6. **Reusability**: Modifiers can be shared across different workload composites
7. **Flexibility**: Advanced users can still use Container primitive directly with modifiers

### Element Categories

1. **Primitive Elements**: Create or represent standalone resources
   - **Workload Primitives**: ✅ `Container`, 📋 `Function`
   - **Data Primitives**: ✅ `Volume`, `ConfigMap`, `Secret`
   - **Connectivity Primitives**: ✅ `NetworkScope`, 📋 `HTTPRoute`, `ServiceMesh`

2. **Modifier Elements**: Enhance primitives without creating resources
   - **Container modifiers**: ✅ `SidecarContainers`, `InitContainers`, `EphemeralContainers`
   - **Scaling modifiers**: ✅ `Replicas`, 📋 `HorizontalAutoscaler`, `VerticalAutoscaler`
   - **Behavioral modifiers**: ✅ `HealthCheck`, `RestartPolicy`, `UpdateStrategy`, 📋 `Resources`, `LifecycleHooks`, `Scheduling`, `Runtime`, `Termination`
   - Must declare which primitives they modify via `modifies` field

3. **Composite Elements**: Combine primitives and modifiers for common patterns
   - **Workload Composites**: ✅ `StatelessWorkload`, `StatefulWorkload`, `DaemonSetWorkload`, `TaskWorkload`, `ScheduledTaskWorkload`
   - **Data Composites**: ✅ `SimpleDatabase`

4. **Custom Elements**: Special handling outside OPM spec

## Element Implementation Patterns

### Primitive Element Pattern

Primitives create resources and can stand alone:

```cue
// Primitive Trait - Creates Deployment workload
#StatelessWorkload: #ElementBase & {
    #elements: StatelessWorkload: #PrimitiveTrait & {
        description: "Horizontally scalable containerized workload"
        target: ["component"]
        labels: {"core.opm.dev/category": "workload"}
        schema: #ContainerSpec
    }

    stateless: #ContainerSpec
}

// Primitive Trait - Creates StatefulSet workload
#StatefulWorkload: #ElementBase & {
    #elements: StatefulWorkload: #PrimitiveTrait & {
        description: "Workload with stable identity and persistent storage"
        target: ["component"]
        labels: {"core.opm.dev/category": "workload"}
        schema: #ContainerSpec
    }

    stateful: #ContainerSpec
}

// Primitive Resource - Creates storage
#Volume: #ElementBase & {
    #elements: Volume: #PrimitiveResource & {
        description: "Volume storage primitive"
        target: ["component"]
        labels: {"core.opm.dev/category": "data"}
        schema: #VolumeSpec
    }

    volumes: [string]: #VolumeSpec
}
```

### Composite Element Pattern

Composites combine multiple elements and set workloadType:

```cue
// Composite Trait - Combines Container with scaling modifiers
#StatelessWorkload: #ElementBase & {
    #elements: StatelessWorkload: #CompositeTrait & {
        name: "StatelessWorkload"
        description: "Horizontally scalable containerized workload"
        target: ["component"]
        workloadType: "stateless"  // Fixed workload type
        composes: [
            #ContainerElement,
            #ReplicasElement,
            #RestartPolicyElement,
            #UpdateStrategyElement,
            #HealthCheckElement,
            #SidecarContainersElement,
            #InitContainersElement
        ]
        labels: {"core.opm.dev/category": "workload"}
        schema: #StatelessSpec
    }

    stateless: #StatelessSpec
}

// Composite Trait - Container + Volume + modifiers for stateful workloads
#StatefulWorkload: #ElementBase & {
    #elements: StatefulWorkload: #CompositeTrait & {
        name: "StatefulWorkload"
        description: "Containerized workload with stable identity and storage"
        target: ["component"]
        workloadType: "stateful"  // Fixed workload type
        composes: [
            #ContainerElement,
            #VolumeElement,
            #ReplicasElement,
            #RestartPolicyElement,
            #UpdateStrategyElement,
            #HealthCheckElement,
            #SidecarContainersElement,
            #InitContainersElement
        ]
        labels: {"core.opm.dev/category": "workload"}
        schema: #StatefulWorkloadSpec
    }

    stateful: #StatefulWorkloadSpec
}
```

### Modifier Element Pattern

Modifiers enhance primitives and composites without declaring specific dependencies:

```cue
// Modifier Trait - Can be used with Container or any workload composite
#Replicas: #ElementBase & {
    #elements: Replicas: #ModifierTrait & {
        name: "Replicas"
        description: "Scale workload instances"
        target: ["component"]
        modifies: []  // Compatible with Container and scalable composites
        labels: {"core.opm.dev/category": "workload"}
        schema: #ReplicasSpec
    }

    replicas: #ReplicasSpec
}

// Modifier Trait - Can be used with any workload
#HealthCheck: #ElementBase & {
    #elements: HealthCheck: #ModifierTrait & {
        name: "HealthCheck"
        description: "Health probes for workloads"
        target: ["component"]
        modifies: []  // Compatible with Container and all workload composites
        labels: {"core.opm.dev/category": "workload"}
        schema: #HealthCheckSpec
    }

    healthCheck: #HealthCheckSpec
}
```

### Component Composition Examples

Components use composites to declare workload type and can be enhanced with additional modifiers and resources:

```cue
// Web component using StatelessWorkload composite
web: #Component & {
    #metadata: {
        #id: "web"
    }

    // Composite (sets workloadType: "stateless" and includes Container + modifiers)
    #StatelessWorkload  // Composite includes: Container, Replicas, RestartPolicy, etc.

    // Additional resources
    #Volume  // Primitive resource - creates PersistentVolumeClaim

    // Additional modifiers to enhance the composite
    #Expose  // Modifier - exposes the workload as a service

    // Configure the stateless workload
    stateless: {
        container: {
            name: "web"
            image: "nginx:latest"
            ports: http: {
                name: "http"
                targetPort: 80
            }
        }
        replicas: {count: 3}
        healthCheck: {
            liveness: {
                httpGet: {
                    path: "/health"
                    port: 80
                    scheme: "HTTP"
                }
            }
        }
        sidecarContainers: [{
            name: "fluentd"
            image: "fluentd:latest"
        }]
    }

    // Configure additional volume
    volumes: {
        data: {persistentClaim: {size: "10Gi"}}
    }

    // Configure service exposure
    expose: {
        ports: http: {
            name: "http"
            targetPort: 80
            exposedPort: 80
        }
        type: "LoadBalancer"
    }
}

// Database component using StatefulWorkload composite
database: #Component & {
    #metadata: {
        #id: "database"
    }

    // Composite (sets workloadType: "stateful" and includes Container + Volume + modifiers)
    #StatefulWorkload  // Composite includes: Container, Volume, Replicas, etc.

    // Additional resources
    #Secret  // Primitive resource - creates Secret

    // Configure stateful workload
    stateful: {
        container: {
            name: "postgres"
            image: "postgres:15"
            ports: db: {
                name: "db"
                targetPort: 5432
            }
            env: {
                POSTGRES_DB: {name: "POSTGRES_DB", value: "mydb"}
            }
        }
        volume: {
            persistentClaim: {
                size: "50Gi"
                accessMode: "ReadWriteOnce"
            }
        }
        updateStrategy: {
            type: "RollingUpdate"
        }
        initContainers: [{
            name: "db-setup"
            image: "postgres:15"
            command: ["./init-db.sh"]
        }]
    }

    // Configure secret
    secrets: {
        credentials: {
            type: "Opaque"
            data: {
                password: "base64encodedpassword"
            }
        }
    }
}

// Advanced: Using Container primitive directly instead of composite
custom: #Component & {
    #metadata: {
        #id: "custom"
    }

    // Using Container primitive gives full flexibility
    #Container  // Primitive sets workloadType: flexible

    // Add modifiers as needed
    #Replicas
    #HealthCheck

    // Configure container
    container: {
        name: "custom-app"
        image: "myapp:latest"
        ports: api: {
            name: "api"
            targetPort: 8080
        }
    }

    replicas: {count: 2}
    healthCheck: {
        liveness: {
            httpGet: {path: "/health", port: 8080, scheme: "HTTP"}
        }
    }
}
```

## Primitive Traits

Primitive traits create or represent standalone resources.

### Workload Primitives

| Status | Element | Target | Description | WorkloadType | Configuration |
|--------|---------|--------|-------------|--------------|---------------|
| ✅ | **Container** | component | Base container definition | stateless \| stateful \| daemonSet \| task \| scheduled-task | `container: #ContainerSpec` |
| 📋 | **Function** | component | A serverless function | function | `function: #FunctionSpec` |

### Connectivity Primitives

| Status | Element | Target | Description | Creates | Configuration |
|--------|---------|--------|-------------|---------|---------------|
| ✅ | **NetworkScope** | scope | Network boundary/scope | NetworkPolicy | `networkScope: #NetworkScopeSpec` |
| 📋 | **HTTPRoute** | component, scope | HTTP routing | Ingress/Route | `httpRoute: #HTTPRouteSpec` |
| 📋 | **ServiceMesh** | scope | Service mesh integration | Mesh configuration | `serviceMesh: #ServiceMeshSpec` |

## Modifier Traits

Modifier traits enhance primitives and composites without creating separate resources.

### Workload Modifiers

Note: "All Workload Composites" refers to StatelessWorkload, StatefulWorkload, DaemonSetWorkload, TaskWorkload, and ScheduledTaskWorkload composites.

| Status | Element | Modifies | Target | Description | Configuration |
|--------|---------|----------|--------|-------------|---------------|
| ✅ | **SidecarContainers** | Container, All Workload Composites | component | Additional containers as sidecars | `sidecarContainers: [#ContainerSpec]` |
| ✅ | **InitContainers** | Container, All Workload Composites | component | Pre-start initialization containers | `initContainers: [#ContainerSpec]` |
| ✅ | **EphemeralContainers** | Container, All Workload Composites | component | Debug/troubleshooting containers | `ephemeralContainers: [#ContainerSpec]` |
| ✅ | **Replicas** | Container, StatelessWorkload, StatefulWorkload | component | Scale instance count | `replicas: #ReplicasSpec` |
| ✅ | **UpdateStrategy** | Container, StatelessWorkload, StatefulWorkload, DaemonSetWorkload | component | Rollout policy | `updateStrategy: #UpdateStrategySpec` |
| ✅ | **HealthCheck** | Container, All Workload Composites | component | Liveness/readiness probes | `healthCheck: #HealthCheckSpec` |
| ✅ | **RestartPolicy** | Container, All Workload Composites | component | Restart behavior | `restartPolicy: #RestartPolicySpec` |
| 📋 | **Resources** | Container, All Workload Composites | component | CPU/memory limits | `resources: #ResourceRequirements` |
| 📋 | **LifecycleHooks** | Container, All Workload Composites | component | Pre/post hooks | `lifecycle: #LifecycleSpec` |
| 📋 | **Scheduling** | Container, All Workload Composites | component | Placement constraints | `scheduling: #SchedulingSpec` |
| 📋 | **Runtime** | Container, All Workload Composites | component | Runtime selection | `runtime: #RuntimeSpec` |
| 📋 | **Termination** | Container, All Workload Composites | component | Graceful shutdown | `termination: #TerminationSpec` |

### Security Modifiers

| Status | Element | Modifies | Target | Description | Configuration |
|--------|---------|----------|--------|-------------|---------------|
| 📋 | **PodSecurity** | Container, All Workload Composites | component, scope | Security context | `podSecurity: #PodSecuritySpec` |
| 📋 | **ServiceAccount** | Container, All Workload Composites | component | Pod identity | `serviceAccount: #ServiceAccountSpec` |
| 📋 | **PodSecurityStandards** | Container, All Workload Composites | scope | Policy enforcement | `standards: #SecurityStandardsSpec` |
| 📋 | **Sysctls** | Container, All Workload Composites | component | Kernel parameters | `sysctls: #SysctlsSpec` |

### Governance Modifiers

| Status | Element | Modifies | Target | Description | Configuration |
|--------|---------|----------|--------|-------------|---------------|
| 📋 | **Priority** | Container, All Workload Composites | component | Scheduling priority | `priority: #PrioritySpec` |
| 📋 | **HorizontalAutoscaler** | Container, StatelessWorkload, StatefulWorkload | component | Horizontal scaling | `horizontalAutoscaler: #HPASpec` |
| 📋 | **VerticalAutoscaler** | Container, StatelessWorkload, StatefulWorkload | component | Vertical scaling | `verticalAutoscaler: #VPASpec` |
| 📋 | **DisruptionBudget** | Container, StatelessWorkload, StatefulWorkload | component | Disruption tolerance | `disruptionBudget: #PDBSpec` |

### Connectivity Modifiers

| Status | Element | Modifies | Target | Description | Configuration |
|--------|---------|----------|--------|-------------|---------------|
| ✅ | **Expose** | Container, All Workload Composites | component | Service exposure | `expose: #ExposeSpec` |
| 📋 | **NetworkPolicy** | NetworkScope, HTTPRoute | scope | Network access control | `networkPolicy: #NetworkPolicySpec` |
| 📋 | **TrafficPolicy** | Expose, ServiceMesh | scope | Traffic management | `trafficPolicy: #TrafficPolicySpec` |
| 📋 | **DNSPolicy** | Container, All Workload Composites, Expose | scope | DNS configuration | `dnsPolicy: #DNSPolicySpec` |
| 📋 | **RateLimiting** | Expose, HTTPRoute | component, scope | Request rate limits | `rateLimit: #RateLimitSpec` |

### Observability Modifiers

| Status | Element | Modifies | Target | Description | Configuration |
|--------|---------|----------|--------|-------------|---------------|
| 📋 | **OTelMetrics** | Container, All Workload Composites | component | Metrics export | `otelMetrics: #OTelMetricsSpec` |
| 📋 | **OTelLogging** | Container, All Workload Composites | component | Logging export | `otelLogs: #OTelLogsSpec` |
| 📋 | **ObservabilityPolicy** | Container, All Workload Composites | scope | Telemetry policies | `observabilityPolicy: #ObservabilityPolicySpec` |

## Primitive Resources

Primitive resources create infrastructure elements.

### Data Resources

| Status | Element | Target | Description | Creates | Configuration |
|--------|---------|--------|-------------|---------|---------------|
| ✅ | **Volume** | component | Storage volumes | PersistentVolumeClaim/Volume | `volumes: [string]: #VolumeSpec` |
| ✅ | **ConfigMap** | component | Configuration data | ConfigMap | `configMaps: [string]: #ConfigMapSpec` |
| ✅ | **Secret** | component | Sensitive data | Secret | `secrets: [string]: #SecretSpec` |
| 📋 | **ProjectedVolume** | component | Multi-source volumes | Projected Volume | `projected: #ProjectedVolumeSpec` |

## Modifier Resources

Modifier resources enhance data resource behavior.

### Data Modifiers

| Status | Element | Modifies | Target | Description | Configuration |
|--------|---------|----------|--------|-------------|---------------|
| 📋 | **BackupPolicy** | Volume, PersistentClaims | scope | Backup requirements | `backupPolicy: #BackupPolicySpec` |
| 📋 | **DisasterRecovery** | Volume, PersistentClaims | scope | DR policies | `disasterRecovery: #DRSpec` |
| 📋 | **CachingPolicy** | ConfigMap, Secret | scope | Caching strategies | `cachingPolicy: #CachingSpec` |

### Governance Resource Modifiers

| Status | Element | Modifies | Target | Description | Configuration |
|--------|---------|----------|--------|-------------|---------------|
| 📋 | **ResourceQuota** | Volume, ConfigMap, Secret | scope | Consumption limits | `resourceQuota: #ResourceQuotaSpec` |
| 📋 | **ResourceLimit** | Volume, ConfigMap, Secret | scope | Resource boundaries | `resourceLimits: #ResourceLimitSpec` |
| 📋 | **CostAllocation** | Volume, PersistentClaims | scope | Cost tracking | `costAllocation: #CostAllocationSpec` |

### Cross-cutting Modifiers

These modifiers can apply to both trait and resource primitives:

| Status | Element | Modifies | Target | Description | Configuration |
|--------|---------|----------|--------|-------------|---------------|
| 📋 | **AuditPolicy** | All Workload Composites, Secret, ConfigMap, Volume | scope | Audit requirements | `auditPolicy: #AuditPolicySpec` |
| 📋 | **CompliancePolicy** | All Workload Composites, Secret, ConfigMap, Volume | scope | Compliance rules | `compliance: #CompliancePolicySpec` |

## Composite Elements

Composite elements combine primitives and modifiers for common patterns. Each composite sets a fixed `workloadType` to enforce component validation.

| Status | Composite | Type | Description | Composes | WorkloadType | Configuration |
|--------|-----------|------|-------------|----------|--------------|---------------|
| ✅ | **StatelessWorkload** | Trait | Horizontally scalable containerized workload with no requirement for stable identity or storage | Container, Replicas, RestartPolicy, UpdateStrategy, HealthCheck, SidecarContainers, InitContainers | `stateless` | `stateless: #StatelessSpec` |
| ✅ | **StatefulWorkload** | Trait | Containerized workload that needs stable identity, persistent storage, and ordered lifecycle across replicas | Container, Volume, Replicas, RestartPolicy, UpdateStrategy, HealthCheck, SidecarContainers, InitContainers | `stateful` | `stateful: #StatefulWorkloadSpec` |
| ✅ | **DaemonSetWorkload** | Trait | Containerized workload meant to run one instance per node for background or node-local services | Container, RestartPolicy, UpdateStrategy, HealthCheck, SidecarContainers, InitContainers | `daemonSet` | `daemonSet: #DaemonSetSpec` |
| ✅ | **TaskWorkload** | Trait | Run-to-completion containerized workload that executes and then exits | Container, RestartPolicy, SidecarContainers, InitContainers | `task` | `task: #TaskWorkloadSpec` |
| ✅ | **ScheduledTaskWorkload** | Trait | Task that is triggered repeatedly on a defined schedule | Container, RestartPolicy, SidecarContainers, InitContainers | `scheduled-task` | `scheduledTask: #ScheduledTaskWorkloadSpec` |
| ✅ | **SimpleDatabase** | Trait | Simple containerized database (composes into StatefulWorkload pattern) | Volume | `stateful` | `database: #SimpleDatabaseSpec` |

## Component Validation

Components automatically validate modifier dependencies:

```cue
#Component: {
    // ... existing fields ...
    
    #validation: {
        // Extract primitives and modifiers
        primitives: [
            for name, elem in #elements 
            if elem.kind == "primitive" {elem.#fullyQualifiedName}
        ]
        
        modifiers: [
            for name, elem in #elements 
            if elem.kind == "modifier" {
                name: elem.#fullyQualifiedName
                elem: elem
            }
        ]
        
        // Validate each modifier has a valid target primitive
        modifierValidation: [
            for mod in modifiers {
                valid: or([
                    for primitive in primitives {
                        list.Contains(mod.elem.modifies, primitive)
                    }
                ]) | error("Modifier '\(mod.name)' requires one of \(mod.elem.modifies)")
            }
        ]
        
        // Validate workloadType matches the workload primitive
        workloadValidation: {
            if #metadata.workloadType == "stateless" {
                hasStateless: list.Contains(primitives, "core.opm.dev/v1alpha1.StatelessWorkload") | 
                             error("workloadType 'stateless' requires StatelessWorkload primitive")
            }
            if #metadata.workloadType == "stateful" {
                hasStateful: list.Contains(primitives, "core.opm.dev/v1alpha1.StatefulWorkload") | 
                            error("workloadType 'stateful' requires StatefulWorkload primitive")
            }
            // ... similar for other workload types
        }
    }
}
```

## Invalid Component Examples

```cue
// INVALID: Multiple workloadTypes in same component
invalid1: #Component & {
    #metadata: {
        #id: "invalid1"
    }

    #StatelessWorkload  // Sets workloadType: "stateless"
    #StatefulWorkload   // ERROR: Attempts to set workloadType: "stateful" - CONFLICT!

    // Cannot have both stateless and stateful in same component
}

// INVALID: Mixing composites with Container primitive (workloadType conflict)
invalid2: #Component & {
    #metadata: {
        #id: "invalid2"
    }

    #Container          // Sets workloadType: flexible (stateless|stateful|etc)
    #StatelessWorkload  // ERROR: Sets fixed workloadType: "stateless" - CONFLICT!

    // Should use either Container + modifiers OR StatelessWorkload composite, not both
}

// INVALID: Task composite with stateless modifier inappropriate
invalid3: #Component & {
    #metadata: {
        #id: "invalid3"
    }

    #TaskWorkload  // workloadType: "task"
    #Replicas      // ERROR: Replicas modifier not appropriate for task workloads

    task: {
        container: {
            name: "batch-job"
            image: "processor:latest"
        }
    }
    replicas: {count: 3}  // Tasks don't scale like stateless workloads
}

// INVALID: DaemonSet with replicas
invalid4: #Component & {
    #metadata: {
        #id: "invalid4"
    }

    #DaemonSetWorkload  // workloadType: "daemonSet"
    #Replicas           // ERROR: DaemonSets run one pod per node, can't set replicas

    daemonSet: {
        container: {
            name: "node-exporter"
            image: "prom/node-exporter:latest"
        }
    }
    replicas: {count: 3}  // Invalid for DaemonSets
}

// INVALID: Modifier without compatible workload
invalid5: #Component & {
    #metadata: {
        #id: "invalid5"
    }

    #Volume             // Just a resource, no workload
    #SidecarContainers  // ERROR: SidecarContainers requires a workload (Container or composite)

    volumes: {data: {emptyDir: {}}}
    sidecarContainers: [{
        name: "fluentd"
        image: "fluentd:latest"
    }]
}
```

## Platform Transformation

### Provider Interface

The #Provider interface from provider.cue defines how platform transformations are handled:

```cue
#Provider: {
    #kind:       "Provider"
    #apiVersion: "core.opm.dev/v1alpha1"
    #metadata: {
        name:        string // The name of the provider
        description: string // A brief description of the provider
        version:     string // The version of the provider
        minVersion:  string // The minimum version of the provider
    }

    // Transformer registry - maps platform resources to transformers
    transformers: #TransformerMap
    // Example:
    // transformers: {
    //     "k8s.io/api/apps/v1.Deployment":            #DeploymentTransformer
    //     "k8s.io/api/apps/v1.StatefulSet":           #StatefulSetTransformer
    //     "k8s.io/api/apps/v1.DaemonSet":             #DaemonSetTransformer
    //     "k8s.io/api/batch/v1.Job":                  #JobTransformer
    //     "k8s.io/api/batch/v1.CronJob":              #CronJobTransformer
    //     "k8s.io/api/core/v1.PersistentVolumeClaim": #PersistentVolumeClaimTransformer
    //     "k8s.io/api/core/v1.Service":               #ServiceTransformer
    // }

    // Auto-computed supported elements from all transformers
    #supportedElements: #ElementMap
    #supportedElements: {
        if transformers != null {
            for _, transformer in transformers {
                for elementName, element in transformer.#supportedElements {
                    if element != _|_ {
                        (elementName): element
                    }
                }
            }
        }
    }

    // Render function
    render: {
        module: #Module
        output: _ // Provider-specific output format. e.g., Kubernetes List object
    }
}

#TransformerMap: [string]: #Transformer
```

### Transformer Selection Logic

The #SelectTransformer provides generic logic for matching component elements to available transformers. **Transformers work with composite elements**, matching against the primitives they contain:

```cue
#SelectTransformer: {
    component: #Component
    availableTransformers: #TransformerMap

    // Extract ALL composite and primitive elements from component
    componentElements: [
        for name, elem in component.#elements {
            fullyQualifiedName: elem.#fullyQualifiedName
            kind: elem.kind
            element: elem
            // For composites, also track their primitive elements
            if elem.kind == "composite" {
                primitiveElements: elem.#primitiveElements
            }
        }
    ]

    // Match transformers based on required elements
    // Composites are matched if they contain the required primitives
    selectedTransformers: [
        for elem in componentElements {
            for _, transformer in availableTransformers {
                // Direct match: element is exactly what transformer requires
                if list.Contains(transformer.required, elem.fullyQualifiedName) {
                    element: elem.fullyQualifiedName
                    transformer: transformer.#fullyQualifiedName
                }
                // Composite match: composite contains required primitives
                if elem.kind == "composite" {
                    for requiredElem in transformer.required {
                        if list.Contains(elem.primitiveElements, requiredElem) {
                            element: elem.fullyQualifiedName
                            transformer: transformer.#fullyQualifiedName
                        }
                    }
                }
            }
        }
    ]
}
```

### Transformer Interface

The #Transformer interface from provider.cue defines how individual transformers work:

```cue
#Transformer: {
    #kind:       string // e.g. "Deployment"
    #apiVersion: string // e.g. "apps/v1"
    #fullyQualifiedName: "\(#apiVersion).\(#kind)" // e.g. "apps/v1.Deployment"

    // Element registry - must be populated by provider implementation
    _registry: #ElementRegistry

    // Required OPM elements (primitives or composites) for this transformer to work
    // Can match composites directly OR primitives contained within composites
    required!: [...string] // e.g. ["core.opm.dev/v1alpha1.StatelessWorkload"] (composite)
                           // or ["core.opm.dev/v1alpha1.Container"] (primitive)
                           // or ["core.opm.dev/v1alpha1.Volume"] (primitive resource)

    // Optional OPM elements (modifiers) that can enhance the resource
    optional: [...string] | *[] // e.g. ["core.opm.dev/v1alpha1.SidecarContainers",
                                 //      "core.opm.dev/v1alpha1.Replicas",
                                 //      "core.opm.dev/v1alpha1.UpdateStrategy",
                                 //      "core.opm.dev/v1alpha1.Expose",
                                 //      "core.opm.dev/v1alpha1.HealthCheck"]


    // All element names (required + optional)
    #allElementNames: [...string] & list.Concat([required, optional])

    // Auto-computed supported elements from registry
    #supportedElements: #ElementMap
    #supportedElements: {
        for elementName in #allElementNames {
            let resolvedElement = #ResolveElement & {
                name:      elementName
                _reg: _registry
            }
            if resolvedElement.element != _|_ {
                (elementName): resolvedElement.element
            }
        }
    }

    // Auto-generated defaults from optional element schemas
    defaults: {
        // Resolve schemas from optional elements only
        for elementName in (optional | *[]) {
            let resolvedSchema = #ResolveElement & {
                name:      elementName
                _reg: _registry
            }
            if resolvedSchema.elementSchema != _|_ {
                resolvedSchema.elementSchema
            }
        }
        // Allow transformer-specific additional defaults
        ...
    }

    // Transform function
    transform: {
        component: #Component
        context:   #ProviderContext
        output:    _ // Provider-specific output format
    }
}
```

### Kubernetes Transformer Examples

These transformers can match either composites directly or primitives within composites:

```cue
// Transformer for StatelessWorkload composite → Kubernetes Deployment
#DeploymentTransformer: #Transformer & {
    #kind:       "Deployment"
    #apiVersion: "apps/v1"

    // Matches StatelessWorkload composite (which contains Container primitive)
    required: ["core.opm.dev/v1alpha1.StatelessWorkload"]

    // Optional modifiers that might be present
    optional: [
        "core.opm.dev/v1alpha1.Expose"  // If present, creates Service
    ]

    transform: {
        component: #Component
        context:   #ProviderContext
        output: {
            apiVersion: "apps/v1"
            kind: "Deployment"
            metadata: {
                name: context.componentMetadata.name
                namespace: context.namespace
                labels: context.unifiedLabels
                annotations: context.unifiedAnnotations
            }
            spec: {
                // StatelessWorkload composite includes these fields
                replicas: component.stateless.replicas.count | *1
                strategy: component.stateless.updateStrategy | *{type: "RollingUpdate"}
                template: {
                    spec: {
                        // Container from composite
                        containers: [
                            component.stateless.container & {
                                livenessProbe: component.stateless.healthCheck.liveness | *_|_
                                readinessProbe: component.stateless.healthCheck.readiness | *_|_
                            }
                        ] + (component.stateless.sidecarContainers | *[])

                        // Init containers from composite
                        initContainers: component.stateless.initContainers | *[]

                        restartPolicy: component.stateless.restartPolicy.policy | *"Always"
                    }
                }
            }
        }
    }
}

// Alternative: Transformer for Container primitive → Kubernetes Deployment
// (For advanced users who want to build their own composition)
#ContainerToDeploymentTransformer: #Transformer & {
    #kind:       "Deployment"
    #apiVersion: "apps/v1"

    // Matches Container primitive directly
    required: ["core.opm.dev/v1alpha1.Container"]

    // All modifiers are optional since Container is flexible
    optional: [
        "core.opm.dev/v1alpha1.Replicas",
        "core.opm.dev/v1alpha1.UpdateStrategy",
        "core.opm.dev/v1alpha1.HealthCheck",
        "core.opm.dev/v1alpha1.RestartPolicy",
        "core.opm.dev/v1alpha1.SidecarContainers",
        "core.opm.dev/v1alpha1.InitContainers",
        "core.opm.dev/v1alpha1.Expose"
    ]

    transform: {
        component: #Component
        context:   #ProviderContext
        output: {
            apiVersion: "apps/v1"
            kind: "Deployment"
            metadata: {
                name: context.componentMetadata.name
                namespace: context.namespace
            }
            spec: {
                replicas: component.replicas.count | *1
                strategy: component.updateStrategy | *{type: "RollingUpdate"}
                template: {
                    spec: {
                        containers: [
                            component.container & {
                                livenessProbe: component.healthCheck.liveness | *_|_
                            }
                        ] + (component.sidecarContainers | *[])
                        initContainers: component.initContainers | *[]
                    }
                }
            }
        }
    }
}

// Transformer for Volume primitive resource → PersistentVolumeClaim
#PersistentVolumeClaimTransformer: #Transformer & {
    #kind:       "PersistentVolumeClaim"
    #apiVersion: "v1"

    // Matches Volume primitive resource
    required: ["core.opm.dev/v1alpha1.Volume"]
    optional: []  // No optional modifiers yet (BackupPolicy is planned)

    transform: {
        component: #Component
        context:   #ProviderContext
        output: [
            for volumeName, volumeSpec in component.volumes {
                apiVersion: "v1"
                kind: "PersistentVolumeClaim"
                metadata: {
                    name: "\(context.componentMetadata.name)-\(volumeName)"
                    namespace: context.namespace
                    labels: context.unifiedLabels
                }
                spec: {
                    accessModes: [volumeSpec.accessMode] | *["ReadWriteOnce"]
                    resources: requests: storage: volumeSpec.persistentClaim.size
                    storageClassName: volumeSpec.persistentClaim.storageClass | *"standard"
                }
            }
        ]
    }
}
```

### Multiple Primitives Example

A component with multiple primitives generates multiple platform resources through the #SelectTransformer:

```cue
// Component with multiple primitives
webWithStorage: #Component & {
    #metadata: {
        #id: "web-with-storage"
        name: "web-app"
    }

    // Two primitives - each will get its own transformer
    #StatelessWorkload  // Will match DeploymentTransformer
    #Volume            // Will match PersistentVolumeClaimTransformer

    // Modifiers that enhance the StatelessWorkload
    #Replicas          // Will be handled by DeploymentTransformer
    #HealthCheck       // Will be handled by DeploymentTransformer

    // Configuration
    stateless: {
        name: "web"
        image: "nginx:latest"
        ports: http: {containerPort: 80}
        volumeMounts: data: {mountPath: "/data"}
    }

    volumes: {
        data: {
            size: "10Gi"
            accessModes: ["ReadWriteOnce"]
            storageClass: "fast-ssd"
        }
    }

    replicas: {count: 3}
    healthCheck: {
        liveness: {httpGet: {path: "/health", port: 80}}
        readiness: {httpGet: {path: "/ready", port: 80}}
    }
}

// #SelectTransformer would produce:
// selectedTransformers: [
//     {
//         primitive: "core.opm.dev/v1alpha1.StatelessWorkload",
//         transformer: "k8s.io/api/apps/v1.Deployment",
//     },
//     {
//         primitive: "core.opm.dev/v1alpha1.Volume",
//         transformer: "k8s.io/api/core/v1.PersistentVolumeClaim"
//     }
// ]

// Generated Platform Resources:
// 1. Deployment (from StatelessWorkload + Replicas + HealthCheck)
// 2. PersistentVolumeClaim (from Volume)
```

This demonstrates how:

1. **Each primitive maps to exactly one transformer**
2. **Multiple primitives = multiple platform resources**
3. **Modifiers enhance their target primitive's transformer**
4. **Selection is automatic based on direct matching**

## Platform Mappings

### Kubernetes Mappings

**Composites → Resources (Recommended Pattern):**

- ✅ StatelessWorkload (composite) → Deployment
- ✅ StatefulWorkload (composite) → StatefulSet
- ✅ DaemonSetWorkload (composite) → DaemonSet
- ✅ TaskWorkload (composite) → Job
- ✅ ScheduledTaskWorkload (composite) → CronJob
- ✅ SimpleDatabase (composite) → StatefulSet + Volume + Secret

**Primitives → Resources (Advanced Pattern):**

- ✅ Container (primitive) → Deployment (with modifiers)
- ✅ Volume (primitive resource) → PersistentVolumeClaim
- ✅ ConfigMap (primitive resource) → ConfigMap
- ✅ Secret (primitive resource) → Secret

**Modifiers → Resource Enhancement:**

Modifiers enhance composites or primitives, mapped to specific Kubernetes fields:

- ✅ Expose → Service (creates additional resource)
- ✅ SidecarContainers → `spec.template.spec.containers[1:]` (additional containers)
- ✅ InitContainers → `spec.template.spec.initContainers`
- ✅ EphemeralContainers → `spec.template.spec.ephemeralContainers`
- ✅ Replicas → `spec.replicas` (within composites or with Container)
- ✅ UpdateStrategy → `spec.strategy` (Deployment) or `spec.updateStrategy` (StatefulSet/DaemonSet)
- ✅ HealthCheck → `containers[*].livenessProbe/readinessProbe`
- ✅ RestartPolicy → `spec.template.spec.restartPolicy`
- 📋 Resources → `containers[*].resources`
- 📋 PodSecurity → `spec.template.spec.securityContext`

### Docker Compose Mappings (Planned)

**Composites → Services:**

- 📋 StatelessWorkload → `services.<name>` with `deploy.replicas`
- 📋 StatefulWorkload → `services.<name>` with volumes

**Primitives → Resources:**

- 📋 Container → `services.<name>`
- 📋 Volume → `volumes:`
- 📋 ConfigMap → `configs:`
- 📋 Secret → `secrets:`

**Modifiers → Service Fields:**

- 📋 Expose → `ports:`
- 📋 Replicas → `deploy.replicas`
- 📋 UpdateStrategy → `deploy.update_config`
- 📋 Resources → `deploy.resources`
- 📋 RestartPolicy → `restart:`

## Key Principles

1. **Container as Foundation**: Container is the single primitive workload trait; all workload patterns are built as composites on top of it
2. **Composites for Common Patterns**: StatelessWorkload, StatefulWorkload, etc. are composite elements that bundle Container + appropriate modifiers for common use cases
3. **WorkloadType Enforcement**: Each component can have exactly one `workloadType`, enforced by elements that declare this field; prevents mixing incompatible workload patterns
4. **Flexible or Fixed WorkloadTypes**:
   - Container primitive: flexible `workloadType` (can be stateless, stateful, daemonSet, task, scheduled-task)
   - Composites: fixed `workloadType` (e.g., StatelessWorkload always sets "stateless")
   - Validation prevents conflicts (can't have both StatelessWorkload and StatefulWorkload in one component)
5. **Transformer Matching**: Transformers can match composites directly OR primitives contained within composites
6. **Modifiers Enhance Any Compatible Element**: Modifiers work with Container primitive or any workload composite; some modifiers are workload-type-specific (e.g., Replicas for scalable workloads)
7. **Two Usage Patterns**:
   - **Recommended**: Use composites (StatelessWorkload, StatefulWorkload, etc.) for standard patterns
   - **Advanced**: Use Container primitive + modifiers for custom compositions
8. **Element Kind Hierarchy**:
   - Primitives: Basic building blocks (Container, Volume, ConfigMap, Secret, NetworkScope)
   - Modifiers: Enhance primitives/composites (Replicas, HealthCheck, Expose, etc.)
   - Composites: Bundle primitives + modifiers (StatelessWorkload, StatefulWorkload, etc.)
9. **Clear Platform Mapping**: Each composite or primitive maps predictably to platform resources
10. **Global Uniqueness**: All elements use `#fullyQualifiedName` for global identification
11. **Implementation Status**: Elements are marked as ✅ implemented or 📋 planned for future releases

This architecture ensures clarity, maintainability, and predictable platform transformations while preserving compositional flexibility. The composite pattern provides convenience without sacrificing the power of primitive-level composition.
