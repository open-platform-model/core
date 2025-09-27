# OPM Design Document: Self-Deployment and Module Dependencies

2025/01/18

**Status:** Incoherent Rambling  
**Lifecycle:** Ideation  
**Authors:** emil-jacero@  
**Tracking Issue:** open-platform-model/opm#TBD  
**Related Roadmap Items:** CLI helper tool, Platform provider implementations  
**Reviewers:** TBD  
**Discussion:** TBD  

> **Note**: This proposal is in early ideation phase. Ideas are being explored and may change significantly.

## Objective

Enable OPM to deploy and manage itself along with its dependencies, solving the bootstrapping problem while maintaining complete platform agnosticism through trait-based abstractions with guaranteed fallback implementations.

## Background

### Current State

Currently, OPM assumes an existing platform runtime where modules can be deployed. There's no standardized way for:

- OPM to deploy itself (the operator/runtime)
- Modules to declare dependencies in a platform-agnostic way
- Guaranteed deployment across diverse platforms

### Problem Statement

The "chicken and egg" problem: How does OPM deploy the infrastructure it needs to function? When a module needs database capabilities, there's no mechanism to:

1. Declare these needs without platform knowledge
2. Ensure modules work everywhere from Kubernetes to Docker Compose
3. Bootstrap OPM without pre-existing infrastructure

### Goals

- [ ] Enable OPM to bootstrap itself on any platform
- [ ] Maintain complete platform agnosticism in module definitions
- [ ] Provide guaranteed deployment through trait fallbacks
- [ ] Support simple dependency declarations

### Non-Goals

- Complex dependency resolution (initially)
- Provider selection mechanisms (future proposal)
- Stack composition (separate proposal)

## Proposal

### Core Concept: Trait Fallback Implementations

Every trait can provide an optional reference implementation using OPM elements, guaranteeing it can always be deployed:

```cue
#SQLDatabase: #PrimitiveTrait & {
    type: "trait"
    kind: "primitive"
    
    // The contract - what developers configure
    #schema: {
        engine: "postgresql" | "mysql" | "mariadb"
        name: string
        database: string
        size?: string | *"10Gi"
        version?: string
    }
    
    // Optional: Reference implementation using OPM elements
    #fallbackImplementation?: #Component & {
        #metadata: {
            type: "workload"
            workloadType: "stateful"
        }
        
        // Can use primitives and composites
        #Container
        container: {
            name: #schema.name
            image: "\(#schema.engine):\(#schema.version | *"latest")"
            ports: {
                sql: {containerPort: 5432}
            }
            env: {
                DB_NAME: {value: #schema.database}
                DB_USER: {value: #schema.name}
            }
        }
        
        #Volume
        volumes: {
            data: {
                persistentClaim: {
                    size: #schema.size
                    accessMode: "ReadWriteOnce"
                }
            }
        }
        
        #Secret
        secrets: {
            credentials: {
                type: "Opaque"
                data: {
                    password: "CHANGE_ME"  // Platform generates
                }
            }
        }
        
        // Can also use composites
        #HealthCheck  // Composite trait
        healthCheck: {
            liveness: {
                exec: {command: ["pg_isready"]}
            }
        }
    }
}

#NoSQLDatabase: #PrimitiveTrait & {
    type: "trait"
    kind: "primitive"
    
    #schema: {
        engine: "redis" | "mongodb" | "cassandra"
        name: string
        size?: string | *"10Gi"
    }
    
    #fallbackImplementation?: #Component & {
        #metadata: {
            type: "workload"
            workloadType: "stateful"
        }
        
        #Container
        container: {
            name: #schema.name
            image: "\(#schema.engine):latest"
        }
        
        #Volume
        volumes: {
            data: {
                persistentClaim: {size: #schema.size}
            }
        }
    }
}
```

### Simple Dependency System

Modules declare dependencies on traits without any platform awareness:

```cue
#ModuleDefinition: {
    // Module dependencies - completely platform agnostic
    dependencies?: [string]: #ModuleDependency
}

#ModuleDependency: {
    capability: string  // e.g., "trait:SQLDatabase"
    version: string     // Version constraint
    required: bool | *true  // Is this required?
    
    onMissing?: {
        message?: string  // Optional warning
    }
}
```

> **Note**: Provider selection and maturity mechanisms will be addressed in a future proposal for advanced platform capabilities.

### Platform Provider Resolution

Platform providers own all implementation decisions:

```cue
#PlatformProvider: {
    name: string
    capabilities: {...}  // Runtime detected
    
    // How this platform implements traits
    traitImplementations: [traitName=string]: #TraitImplementation
}

#TraitImplementation: {
    resolutionChain: [...#ImplementationStrategy]
    
    onFallback?: {
        message: string
        degradedFeatures?: [...string]
    }
}

#ImplementationStrategy: {
    name: string
    when: bool | string  // Condition
    
    transformer: {
        input: _  // Trait schema
        output: _  // Platform resources or OPM component
    }
}
```

## User Experience

### OPM Self-Bootstrap Module

```cue
#ModuleDefinition: {
    #metadata: {
        name: "opm-operator"
        version: "1.0.0"
        description: "OPM operator that manages OPM modules"
    }
    
    // Simple, platform-agnostic dependencies
    dependencies: {
        "catalog-database": {
            capability: "trait:SQLDatabase"
            version: "^1.0"
            required: false  // OPM can work without it
            
            onMissing: {
                message: "Using embedded SQLite"
            }
        }
        
        "cache": {
            capability: "trait:NoSQLDatabase"
            version: "^1.0"
            required: false
            
            onMissing: {
                message: "Running without cache"
            }
        }
    }
    
    components: {
        operator: {
            #metadata: {
                type: "workload"
                workloadType: "stateless"
            }
            
            #Container
            container: {
                image: "opm.dev/operator:1.0.0"
                env: {
                    // Application adapts internally
                    CATALOG_MODE: {value: "auto"}
                    CACHE_MODE: {value: "auto"}
                }
            }
            
            #Volume
            volumes: {
                data: {
                    // Always have storage for embedded mode
                    emptyDir: {sizeLimit: "1Gi"}
                }
            }
        }
        
        // Database component - always defined
        database: {
            #metadata: {
                type: "workload"
                workloadType: "stateful"
            }
            
            #SQLDatabase
            sqlDatabase: {
                engine: "postgresql"
                name: "opm_catalog"
                database: "catalog"
                size: "10Gi"
            }
        }
        
        // Cache component - always defined
        cache: {
            #metadata: {
                type: "workload"
                workloadType: "stateful"
            }
            
            #NoSQLDatabase
            noSqlDatabase: {
                engine: "redis"
                name: "opm_cache"
                size: "2Gi"
            }
        }
    }
}
```

### Enterprise Application

```cue
#ModuleDefinition: {
    #metadata: {
        name: "enterprise-app"
        version: "1.0.0"
    }
    
    dependencies: {
        "database": {
            capability: "trait:SQLDatabase"
            version: "^1.0"
            required: true
        }
        
        "cache": {
            capability: "trait:NoSQLDatabase"
            version: "^1.0"
            required: false
            
            onMissing: {
                message: "Cache unavailable, using database only"
            }
        }
    }
    
    components: {
        api: {
            #metadata: {
                type: "workload"
                workloadType: "stateless"
            }
            
            #Container
            container: {
                image: "enterprise/api:3.0"
                env: {
                    // App handles cache availability internally
                    CACHE_MODE: {value: "auto"}
                }
            }
            
            #Replicas
            replicas: 3
        }
        
        // All components always defined
        database: {
            #metadata: {
                type: "workload"
                workloadType: "stateful"
            }
            
            #SQLDatabase
            sqlDatabase: {
                engine: "postgresql"
                name: "enterprise"
                database: "main"
                size: "100Gi"
                version: "15"
            }
        }
        
        cache: {
            #metadata: {
                type: "workload"
                workloadType: "stateful"
            }
            
            #NoSQLDatabase
            noSqlDatabase: {
                engine: "redis"
                name: "cache"
                size: "10Gi"
            }
        }
    }
}
```

## Platform Provider Examples

### Kubernetes Provider

```cue
#KubernetesPlatformProvider: #PlatformProvider & {
    name: "kubernetes"
    
    capabilities: {
        operators: {
            "cnpg.io": detected
            "redis-operator": detected
        }
    }
    
    traitImplementations: {
        #SQLDatabase: {
            resolutionChain: [
                {
                    name: "cnpg-operator"
                    when: capabilities.operators["cnpg.io"] == detected
                    
                    transformer: {
                        output: {
                            apiVersion: "postgresql.cnpg.io/v1"
                            kind: "Cluster"
                            spec: {
                                instances: 3
                                // ... CNPG config
                            }
                        }
                    }
                },
                {
                    name: "trait-fallback"
                    when: "always"
                    
                    transformer: {
                        // Use trait's built-in fallback
                        output: #SQLDatabase.#fallbackImplementation & {
                            #schema: input
                        }
                    }
                }
            ]
            
            onFallback: {
                message: "Using basic StatefulSet"
                degradedFeatures: ["backup", "HA"]
            }
        }
    }
}
```

### Docker Compose Provider

```cue
#DockerComposePlatformProvider: #PlatformProvider & {
    name: "docker-compose"
    
    capabilities: {
        volumes: true
        networks: true
        containers: true
    }
    
    traitImplementations: {
        #SQLDatabase: {
            resolutionChain: [
                {
                    name: "docker-native"
                    when: "always"
                    
                    transformer: {
                        // Convert trait fallback to docker format
                        input: #SQLDatabase.#fallbackImplementation & {
                            #schema: input
                        }
                        
                        output: {
                            services: {
                                (input.name): {
                                    image: input.container.image
                                    environment: [...]
                                    volumes: [...]
                                }
                            }
                        }
                    }
                }
            ]
        }
    }
}
```

## Module Release

The beauty is that module releases are identical regardless of platform:

```cue
// Deploy OPM anywhere
opmRelease: #ModuleRelease & {
    module: "opm.dev/operator:1.0.0"
    
    values: {
        environment: "production"
    }
    
    // That's it! Platform handles everything:
    // - Kubernetes with CNPG: Full PostgreSQL
    // - Kubernetes without: Fallback StatefulSet
    // - Docker Compose: Container from fallback
    // - Podman: Container from fallback
}

// Deploy enterprise app anywhere  
enterpriseRelease: #ModuleRelease & {
    module: "enterprise-app:3.0.0"
    
    values: {
        environment: "production"
    }
    
    // Works on any platform automatically
}
```

## Key Principles

### Platform Agnosticism

- **No Platform References**: Modules never mention platforms
- **Trait Abstraction**: Only use traits and resources
- **No Conditional Logic**: No "if platform == X" anywhere
- **Always Define Components**: All components always present

### Fallback Guarantees

- **Every Trait Works**: Fallback implementations ensure deployment
- **Use OPM Elements**: Fallbacks use primitives and composites
- **Platform Choice**: Platforms can use fallback or better implementation

### Clear Separation

- **Module Authors**: Write platform-agnostic modules using traits
- **Trait Authors**: Provide optional fallback implementations
- **Platform Providers**: Decide how to implement each trait
- **End Users**: Deploy without platform concerns

## Implementation Phases

### Phase 1: Trait Fallbacks

- Define fallback implementation structure
- Create fallbacks for core traits
- Validate composite resolution

### Phase 2: Platform Providers

- Build provider framework
- Implement Kubernetes, Docker, Podman providers
- Test fallback usage

### Phase 3: Dependencies

- Add simple dependency system
- Handle required/optional dependencies
- Implement missing dependency messages

### Phase 4: Bootstrap

- Create OPM operator module
- Test self-deployment on all platforms
- Document bootstrap procedures

## Trade-offs

### Advantages

- Complete platform agnosticism
- Guaranteed deployment everywhere
- Simple developer experience
- Flexible fallback system (primitives and composites)
- True write-once-run-anywhere

### Disadvantages

- Trait authors must provide fallbacks
- Feature disparity across platforms
- Testing complexity for multiple paths
- Performance differences with fallbacks

## Future Work

- Stack composition for multi-module deployments
- Provider selection and maturity mechanisms
- Enhanced fallback optimizations
- Migration tools between implementations

## Conclusion

This proposal solves OPM's bootstrapping problem through trait fallback implementations while maintaining complete platform agnosticism. Modules are written once using only traits and work everywhere - the platform determines the quality of implementation.

The key innovation: traits provide optional reference implementations using OPM's own elements, guaranteeing every module can deploy on any platform. OPM can bootstrap itself anywhere, applications work everywhere, and developers never need platform knowledge.

The module → component → trait hierarchy provides all deployment information without platform coupling. Platform providers have complete freedom in how they implement traits while modules remain truly portable.
