# OPM Elements Reference

This document catalogs the available elements (traits and resources) in the Open Platform Model architecture. Elements are the atomic building blocks that can be composed into components and ultimately assembled into modules.

## Element Architecture Oveview

Elements in OPM follow a unified pattern based on the `#Element` foundation:

- **Type**: Either `trait` (behavioral capabilities) or `resource` (infrastructure primitives)
- **Kind**: `primitive`, `composite`, `modifier`, or `custom`
- **Target**: Where applicable - `component`, `scope`, or both
- **Modifies**: For modifier elements, declares which primitives they can modify
- **Labels**: Systematic organization using labels like `core.opm.dev/category`

### Workload Architecture Summary

> **Key Design Decision**: OPM uses explicit workload primitives instead of a generic Container.
>
> - `StatelessWorkload` → Creates Deployment
> - `StatefulWorkload` → Creates StatefulSet  
> - `DaemonSetWorkload` → Creates DaemonSet
> - `TaskWorkload` → Creates Job
> - `ScheduledTaskWorkload` → Creates CronJob
>
> Each workload type is a distinct primitive element with its own configuration field (`stateless:`, `stateful:`, `daemonSet:`, `task:`, `scheduledTask:`). This eliminates ambiguity and provides direct 1:1 platform resource mapping.

### Benefits of Explicit Workload Primitives

The OPM architecture uses explicit workload primitives (StatelessWorkload, StatefulWorkload, etc.) instead of a generic Container primitive. This design provides:

1. **Clear Intent**: Developers explicitly declare what type of workload they're creating
2. **Direct Platform Mapping**: Each primitive maps to exactly one platform resource (no ambiguity)
3. **Type Safety**: Modifiers can be restricted to appropriate workload types
4. **Simpler Providers**: No need to interpret workloadType metadata - the primitive itself defines the resource
5. **Better Validation**: Components can validate that workloadType matches the primitive used

### Element Categories

1. **Primitive Elements**: Create or represent standalone resources
   - **Workload Primitives**: `StatelessWorkload`, `StatefulWorkload`, `DaemonSetWorkload`, `TaskWorkload`, `ScheduledTaskWorkload`
   - **Data Primitives**: `Volume`, `ConfigMap`, `Secret`  
   - **Networking Primitives**: `Expose`, `HTTPRoute`, `ServiceMesh`

2. **Modifier Elements**: Enhance primitives without creating resources
   - **Container modifiers**: `SidecarContainers`, `InitContainers`, `EphemeralContainers`
   - **Scaling modifiers**: `Replicas`, `HorizontalAutoscaler`, `VerticalAutoscaler`
   - **Behavioral modifiers**: `HealthCheck`, `Resources`, `UpdateStrategy`, `RestartPolicy`
   - Must declare which primitives they modify via `modifies` field

3. **Composite Elements**: Combine primitives and modifiers for common patterns

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
        #schema: #ContainerSpec
    }

    stateless: #ContainerSpec
}

// Primitive Trait - Creates StatefulSet workload
#StatefulWorkload: #ElementBase & {
    #elements: StatefulWorkload: #PrimitiveTrait & {
        description: "Workload with stable identity and persistent storage"
        target: ["component"]
        labels: {"core.opm.dev/category": "workload"}
        #schema: #ContainerSpec
    }

    stateful: #ContainerSpec
}

// Primitive Resource - Creates storage
#Volume: #ElementBase & {
    #elements: Volume: #PrimitiveResource & {
        description: "Volume storage primitive"
        target: ["component"]
        labels: {"core.opm.dev/category": "data"}
        #schema: #VolumeSpec
    }

    volumes: [string]: #VolumeSpec
}
```

### Modifier Element Pattern

Modifiers enhance primitives and must declare what they modify:

```cue
// Modifier Trait - Enhances Stateless and Stateful workloads
#Replicas: #ElementBase & {
    #elements: Replicas: #ModifierTrait & {
        description: "Scale workload instances"
        target: ["component"]
        modifies: [
            "core.opm.dev/v1alpha1.StatelessWorkload",
            "core.opm.dev/v1alpha1.StatefulWorkload"
        ]  // Using fullyQualifiedName
        labels: {"core.opm.dev/category": "workload"}
        #schema: #ReplicasSpec
    }

    replicas: #ReplicasSpec
}

// Modifier Trait - Enhances all workloads
#HealthCheck: #ElementBase & {
    #elements: HealthCheck: #ModifierTrait & {
        description: "Health probes for workloads"
        target: ["component"]
        modifies: [
            "core.opm.dev/v1alpha1.StatelessWorkload",
            "core.opm.dev/v1alpha1.StatefulWorkload",
            "core.opm.dev/v1alpha1.DaemonSetWorkload",
            "core.opm.dev/v1alpha1.TaskWorkload",
            "core.opm.dev/v1alpha1.ScheduledTaskWorkload"
        ]
        labels: {"core.opm.dev/category": "workload"}
        #schema: #HealthCheckSpec
    }

    healthCheck: #HealthCheckSpec
}
```

### Component Composition with Validation

Components validate that modifiers have their required primitives:

```cue
web: #Component & {
    #metadata: {
        #id: "web"
    }

    // Primitives (create resources)
    #StatelessWorkload  // Creates Deployment
    #Volume            // Creates PersistentVolumeClaim

    // Modifiers (enhance StatelessWorkload)
    #SidecarContainers  // Valid: StatelessWorkload exists
    #InitContainers     // Valid: StatelessWorkload exists
    #Replicas          // Valid: StatelessWorkload exists
    #HealthCheck       // Valid: StatelessWorkload exists
    #Resources         // Valid: StatelessWorkload exists
    
    // Configure primary workload (required)
    stateless: {
        name: "web"
        image: "nginx:latest"
        ports: http: {containerPort: 80}
    }
    
    // Configure volumes
    volumes: {
        data: {persistentClaim: {size: "10Gi"}}
    }
    
    // Configure additional containers (modifiers)
    sidecarContainers: {
        logging: {
            name: "fluentd"
            image: "fluentd:latest"
            volumeMounts: logs: {mountPath: "/var/log"}
        }
    }
    initContainers: {
        migration: {
            name: "migrate"
            image: "migrate:latest"
            command: ["./migrate.sh"]
        }
    }
    
    // Configure other modifiers
    replicas: {count: 3}
    healthCheck: {
        liveness: {httpGet: {path: "/health"}}
    }
}

// Database component example
database: #Component & {
    #metadata: {
        #id: "database"
    }

    // Primitives
    #StatefulWorkload  // Creates StatefulSet
    #Volume           // Creates PersistentVolumeClaim
    #Secret           // Creates Secret

    // Modifiers
    #InitContainers    // Valid: StatefulWorkload exists
    #Resources        // Valid: StatefulWorkload exists
    #UpdateStrategy   // Valid: StatefulWorkload exists
    
    // Configure stateful workload
    stateful: {
        name: "postgres"
        image: "postgres:15"
        ports: db: {containerPort: 5432}
        env: {
            POSTGRES_DB: {name: "POSTGRES_DB", value: "mydb"}
        }
    }
    
    volumes: {
        data: {persistentClaim: {size: "50Gi"}}
    }
    
    secrets: {
        credentials: {
            type: "Opaque"
            data: {
                password: "base64encodedpassword"
            }
        }
    }
    
    initContainers: {
        setup: {
            name: "db-setup"
            image: "postgres:15"
            command: ["./init-db.sh"]
        }
    }
}
```

## Primitive Traits

Primitive traits create or represent standalone resources.

### Workload Primitives

| Element | Target | Description | Creates | Configuration |
|---------|--------|-------------|---------|---------------|
| **Container** | component | Single container | Deployment | `container: #ContainerSpec` |
| **Function** | component | A serverless function (Not yet implemented) |  A serverless function | `function: #FunctionSpec` |

### Connectivity Primitives

| Element | Target | Description | Creates | Configuration |
|---------|--------|-------------|---------|---------------|
| **Expose** | component | Service exposure | Service | `expose: #ExposeSpec` |
| **HTTPRoute** | component, scope | HTTP routing | Ingress/Route | `httpRoute: #HTTPRouteSpec` |
| **ServiceMesh** | scope | Service mesh integration | Mesh configuration | `serviceMesh: #ServiceMeshSpec` |

## Modifier Traits

Modifier traits enhance primitives without creating separate resources.

### Workload Modifiers

Note: "All Workloads" refers to StatelessWorkload, StatefulWorkload, DaemonSetWorkload, TaskWorkload, and ScheduledTaskWorkload.

| Element | Modifies | Target | Description | Configuration |
|---------|----------|--------|-------------|---------------|
| **SidecarContainers** | StatelessWorkload, StatefulWorkload, DaemonSetWorkload | component | Additional containers as sidecars | `sidecarContainers: [string]: #ContainerSpec` |
| **InitContainers** | StatelessWorkload, StatefulWorkload, DaemonSetWorkload, TaskWorkload | component | Pre-start initialization containers | `initContainers: [string]: #ContainerSpec` |
| **EphemeralContainers** | StatelessWorkload, StatefulWorkload, DaemonSetWorkload | component | Debug/troubleshooting containers | `ephemeralContainers: [string]: #ContainerSpec` |
| **Replicas** | StatelessWorkload, StatefulWorkload | component | Scale instance count | `replicas: #ReplicasSpec` |
| **UpdateStrategy** | StatelessWorkload, StatefulWorkload, DaemonSetWorkload | component | Rollout policy | `updateStrategy: #UpdateStrategySpec` |
| **Resources** | All Workloads | component | CPU/memory limits | `resources: #ResourceRequirements` |
| **HealthCheck** | All Workloads | component | Liveness/readiness probes | `healthCheck: #HealthCheckSpec` |
| **LifecycleHooks** | All Workloads | component | Pre/post hooks | `lifecycle: #LifecycleSpec` |
| **Scheduling** | All Workloads | component | Placement constraints | `scheduling: #SchedulingSpec` |
| **Runtime** | All Workloads | component | Runtime selection | `runtime: #RuntimeSpec` |
| **Termination** | All Workloads | component | Graceful shutdown | `termination: #TerminationSpec` |
| **RestartPolicy** | TaskWorkload, ScheduledTaskWorkload | component | Restart behavior | `restartPolicy: #RestartPolicySpec` |

### Security Modifiers

| Element | Modifies | Target | Description | Configuration |
|---------|----------|--------|-------------|---------------|
| **PodSecurity** | All Workloads | component, scope | Security context | `podSecurity: #PodSecuritySpec` |
| **ServiceAccount** | All Workloads | component | Pod identity | `serviceAccount: #ServiceAccountSpec` |
| **PodSecurityStandards** | All Workloads | scope | Policy enforcement | `standards: #SecurityStandardsSpec` |
| **Sysctls** | All Workloads | component | Kernel parameters | `sysctls: #SysctlsSpec` |

### Governance Modifiers

| Element | Modifies | Target | Description | Configuration |
|---------|----------|--------|-------------|---------------|
| **Priority** | All Workloads | component | Scheduling priority | `priority: #PrioritySpec` |
| **HorizontalAutoscaler** | StatelessWorkload, StatefulWorkload | component | Horizontal scaling | `horizontalAutoscaler: #HPASpec` |
| **VerticalAutoscaler** | StatelessWorkload, StatefulWorkload | component | Vertical scaling | `verticalAutoscaler: #VPASpec` |
| **DisruptionBudget** | StatelessWorkload, StatefulWorkload | component | Disruption tolerance | `disruptionBudget: #PDBSpec` |

### Connectivity Modifiers

| Element | Modifies | Target | Description | Configuration |
|---------|----------|--------|-------------|---------------|
| **NetworkPolicy** | Expose, HTTPRoute | scope | Network access control | `networkPolicy: #NetworkPolicySpec` |
| **TrafficPolicy** | Expose, ServiceMesh | scope | Traffic management | `trafficPolicy: #TrafficPolicySpec` |
| **DNSPolicy** | All Workloads, Expose | scope | DNS configuration | `dnsPolicy: #DNSPolicySpec` |
| **RateLimiting** | Expose, HTTPRoute | component, scope | Request rate limits | `rateLimit: #RateLimitSpec` |

### Observability Modifiers

| Element | Modifies | Target | Description | Configuration |
|---------|----------|--------|-------------|---------------|
| **OTelMetrics** | All Workloads | component | Metrics export | `otelMetrics: #OTelMetricsSpec` |
| **OTelLogging** | All Workloads | component | Logging export | `otelLogs: #OTelLogsSpec` |
| **ObservabilityPolicy** | All Workloads | scope | Telemetry policies | `observabilityPolicy: #ObservabilityPolicySpec` |

## Primitive Resources

Primitive resources create infrastructure elements.

### Data Resources

| Element | Target | Description | Creates | Configuration |
|---------|--------|-------------|---------|---------------|
| **Volume** | component | Storage volumes | PersistentVolumeClaim/Volume | `volumes: [string]: #VolumeSpec` |
| **ConfigMap** | component | Configuration data | ConfigMap | `configMaps: [string]: #ConfigMapSpec` |
| **Secret** | component | Sensitive data | Secret | `secrets: [string]: #SecretSpec` |
| **ProjectedVolume** | component | Multi-source volumes | Projected Volume | `projected: #ProjectedVolumeSpec` |

## Modifier Resources

Modifier resources enhance data resource behavior.

### Data Modifiers

| Element | Modifies | Target | Description | Configuration |
|---------|----------|--------|-------------|---------------|
| **BackupPolicy** | Volume, PersistentClaims | scope | Backup requirements | `backupPolicy: #BackupPolicySpec` |
| **DisasterRecovery** | Volume, PersistentClaims | scope | DR policies | `disasterRecovery: #DRSpec` |
| **CachingPolicy** | ConfigMap, Secret | scope | Caching strategies | `cachingPolicy: #CachingSpec` |

### Governance Resource Modifiers

| Element | Modifies | Target | Description | Configuration |
|---------|----------|--------|-------------|---------------|
| **ResourceQuota** | Volume, ConfigMap, Secret | scope | Consumption limits | `resourceQuota: #ResourceQuotaSpec` |
| **ResourceLimit** | Volume, ConfigMap, Secret | scope | Resource boundaries | `resourceLimits: #ResourceLimitSpec` |
| **CostAllocation** | Volume, PersistentClaims | scope | Cost tracking | `costAllocation: #CostAllocationSpec` |

### Cross-cutting Modifiers

These modifiers can apply to both trait and resource primitives:

| Element | Modifies | Target | Description | Configuration |
|---------|----------|--------|-------------|---------------|
| **AuditPolicy** | All Workloads, Secret, ConfigMap, Volume | scope | Audit requirements | `auditPolicy: #AuditPolicySpec` |
| **CompliancePolicy** | All Workloads, Secret, ConfigMap, Volume | scope | Compliance rules | `compliance: #CompliancePolicySpec` |

## Composite Elements

Composite elements combine primitives and modifiers for common patterns:

| Composite | Type | Description | Primitives | Modifiers | Workload Type | Use Case |
|-----------|------|-------------|------------|-----------|---------------|----------|
| **StatelessWorkload** | Trait | A horizontally scalable containerized workload with no requirement for stable identity or storage | Container | Replicas, RestartPolicy, UpdateStrategy, HealthCheck, SidecarContainers, InitContainers | `stateless` | A stateless workload |
| **StatefulWorkload** | Trait | A containerized workload that needs stable identity, persistent storage, and ordered lifecycle across replicas | Container | Replicas, RestartPolicy, UpdateStrategy, HealthCheck, SidecarContainers, InitContainers, Volume | `stateful` | A stateful workload |
| **DaemonSetWorkload** | Trait | A containerized workload meant to run one (or more) instance per node for background or node-local services | Container | RestartPolicy, UpdateStrategy, HealthCheck, SidecarContainers, InitContainers | `daemonset` | A daemonSet workload |
| **TaskWorkload** | Trait | A run-to-completion containerized workload that executes and then exits | Container | RestartPolicy, SidecarContainers, InitContainers | `task` | A task workload |
| **ScheduledTaskWorkload** | Trait | A Task that is triggered repeatedly on a defined schedule | Container | RestartPolicy, SidecarContainers, InitContainers | `scheduled-task` | A scheduled task workload |
| **SimpleDatabase** | Trait | A simple containerized database | StatefulWorkload, Volume, ConfigMap, Secret | N/A | `stateful` | Complete database service |

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
// INVALID: Replicas without compatible workload
invalid1: #Component & {
    #metadata: {
        #id: "invalid1"
    }
    
    #DaemonSetWorkload
    #Replicas  // ERROR: Replicas only modifies StatelessWorkload/StatefulWorkload
    
    daemon: {
        name: "node-exporter"
        image: "prom/node-exporter"
    }
    replicas: {count: 3}  // DaemonSets don't support replicas
}

// INVALID: SidecarContainers without workload
invalid2: #Component & {
    #metadata: {
        #id: "invalid2"
    }
    
    #Volume
    #SidecarContainers  // ERROR: SidecarContainers requires a workload primitive
    
    volumes: {data: {emptyDir: {}}}
    sidecarContainers: {
        logging: {
            name: "fluentd"
            image: "fluentd:latest"
        }
    }
}

// INVALID: RestartPolicy on wrong workload type
invalid3: #Component & {
    #metadata: {
        #id: "invalid3"
    }
    
    #StatelessWorkload
    #RestartPolicy  // ERROR: RestartPolicy only modifies TaskWorkload/ScheduledTaskWorkload
    
    stateless: {
        name: "web"
        image: "nginx"
    }
    restartPolicy: {policy: "OnFailure"}
}

// INVALID: HorizontalAutoscaler on DaemonSetWorkload
invalid4: #Component & {
    #metadata: {
        #id: "invalid4"
    }
    
    #DaemonSetWorkload
    #HorizontalAutoscaler  // ERROR: HPA only modifies StatelessWorkload/StatefulWorkload
    
    daemon: {
        name: "logging-agent"
        image: "fluentd"
    }
    horizontalAutoscaler: {
        minReplicas: 1
        maxReplicas: 10
    }
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

The #SelectTransformer provides generic logic for matching component primitives to available transformers. **For now, each primitive maps to exactly one transformer** - this may change in the future to support multiple transformer options per primitive:

```cue
#SelectTransformer: {
    component: #Component
    availableTransformers: #TransformerMap

    // Extract ALL primitive elements from component
    primitiveElements: [
        for name, elem in component.#elements
        if elem.kind == "primitive" {
            fullyQualifiedName: elem.#fullyQualifiedName
            element: elem
        }
    ]

    // Direct mapping: each primitive gets exactly one transformer
    // Future versions may support multiple transformers per primitive with selection logic
    selectedTransformers: [
        for primitive in primitiveElements {
            for _, transformer in availableTransformers {
                if list.Contains(transformer.required, primitive.fullyQualifiedName) {
                    // Current implementation assumes 1:1 mapping
                    primitive: primitive.fullyQualifiedName
                    transformer: transformer.#fullyQualifiedName
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

    // Required OPM primitive elements for this transformer to work
    required!: [...string] // e.g. ["core.opm.dev/v1alpha1.StatelessWorkload"] or ["core.opm.dev/v1alpha1.StatefulWorkload", "core.opm.dev/v1alpha1.Volume"]

    // Optional OPM modifier elements that can enhance the resource
    optional: [...string] | *[] // e.g. ["core.opm.dev/v1alpha1.SidecarContainers", "core.opm.dev/v1alpha1.Replicas", "core.opm.dev/v1alpha1.UpdateStrategy", "core.opm.dev/v1alpha1.Expose", "core.opm.dev/v1alpha1.HealthCheck"]


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

```cue
#DeploymentTransformer: #Transformer & {
    #kind:       "Deployment"
    #apiVersion: "apps/v1"

    // This transformer specifically handles StatelessWorkload
    required: ["core.opm.dev/v1alpha1.StatelessWorkload"]
    optional: [
        "core.opm.dev/v1alpha1.SidecarContainers",
        "core.opm.dev/v1alpha1.InitContainers",
        "core.opm.dev/v1alpha1.Replicas",
        "core.opm.dev/v1alpha1.UpdateStrategy",
        "core.opm.dev/v1alpha1.Resources",
        "core.opm.dev/v1alpha1.HealthCheck"
    ]

    transform: {
        component: #Component
        context:   #ProviderContext
        output: {
            apiVersion: #apiVersion
            kind: #kind
            metadata: {
                name: context.componentMetadata.name
                namespace: context.namespace
                labels: context.unifiedLabels
                annotations: context.unifiedAnnotations
            }
            spec: {
                replicas: component.replicas.count | *1
                strategy: component.updateStrategy | *{type: "RollingUpdate"}
                template: {
                    spec: {
                        containers: [
                            component.stateless & {
                                resources: component.resources | *{}
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

#PersistentVolumeClaimTransformer: #Transformer & {
    #kind:       "PersistentVolumeClaim"
    #apiVersion: "v1"

    // This transformer specifically handles Volume primitive
    required: ["core.opm.dev/v1alpha1.Volume"]
    optional: [
        "core.opm.dev/v1alpha1.BackupPolicy",
        "core.opm.dev/v1alpha1.ResourceQuota"
    ]

    transform: {
        component: #Component
        context:   #ProviderContext
        output: [
            for volumeName, volumeSpec in component.volumes {
                apiVersion: #apiVersion
                kind: #kind
                metadata: {
                    name: "\(context.componentMetadata.name)-\(volumeName)"
                    namespace: context.namespace
                    labels: context.unifiedLabels
                    annotations: context.unifiedAnnotations
                }
                spec: {
                    accessModes: volumeSpec.accessModes | *["ReadWriteOnce"]
                    resources: requests: storage: volumeSpec.size
                    storageClassName: volumeSpec.storageClass | *_|_
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

**Primitives → Resources (Direct 1:1 Mapping):**

- StatelessWorkload → Deployment
- StatefulWorkload → StatefulSet
- DaemonSetWorkload → DaemonSet
- TaskWorkload → Job
- ScheduledTaskWorkload → CronJob
- Volume → PersistentVolumeClaim
- ConfigMap → ConfigMap
- Secret → Secret
- Expose → Service
- HTTPRoute → Ingress

**Modifiers → Resource Fields:**

- SidecarContainers → `spec.template.spec.containers[1:]` (additional containers)
- InitContainers → `spec.template.spec.initContainers`
- EphemeralContainers → `spec.template.spec.ephemeralContainers`
- Replicas → `spec.replicas` (Deployment/StatefulSet only)
- UpdateStrategy → `spec.strategy` (Deployment) or `spec.updateStrategy` (StatefulSet/DaemonSet)
- Resources → `containers[*].resources`
- HealthCheck → `containers[*].livenessProbe/readinessProbe`
- PodSecurity → `spec.template.spec.securityContext`
- RestartPolicy → `spec.backoffLimit` and `spec.template.spec.restartPolicy` (Job/CronJob only)

### Docker Compose Mappings

**Primitives → Resources:**

- Container → `services.<name>`
- Volume → `volumes:`
- ConfigMap → `configs:`
- Secret → `secrets:`
- Expose → `ports:`

**Modifiers → Resource Fields:**

- Replicas → `deploy.replicas`
- UpdateStrategy → `deploy.update_config`
- Resources → `deploy.resources`
- RestartPolicy → `restart:`

## Key Principles

1. **Direct Resource Mapping**: Each primitive element maps to exactly one platform resource type (StatelessWorkload→Deployment, StatefulWorkload→StatefulSet, Volume→PersistentVolumeClaim, etc.) - **for now**
2. **1:1 Primitive-to-Transformer Mapping**: Currently, each primitive has exactly one compatible transformer; future versions may support multiple transformer options per primitive
3. **Explicit Workload Types**: No ambiguity - workload type is encoded in the element itself, not metadata
4. **Clear Modifier Dependencies**: Modifiers declare what they modify via `modifies` field using fullyQualifiedNames
5. **Validation**: Components validate that modifiers have their required primitives
6. **Simplified Transformation**: Only primitives need platform transformers; direct 1:1 mapping (no scoring logic needed currently)
7. **Type-Appropriate Modifiers**: Some modifiers only apply to specific workload types (e.g., Replicas doesn't apply to DaemonSetWorkload)
8. **Global Uniqueness**: All elements use `#fullyQualifiedName` for global identification

This architecture ensures clarity, maintainability, and predictable platform transformations while preserving all compositional flexibility. The current 1:1 mapping approach keeps transformer selection simple and deterministic.
