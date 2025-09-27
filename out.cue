#apiVersion: "core.opm.dev/v1"
#kind:       "Module"
#metadata: {
    name:    "my-app-instance"
    version: "0.1.0"
    labels: {
        environment: "production"
        team:        "frontend"
    }
    annotations?: {}
    #id: "my-app-instance"
}
#moduleDefinition: {
    #apiVersion: "core.opm.dev/v1"
    #kind:       "ModuleDefinition"
    #metadata: {
        name:              "my-app"
        defaultNamespace?: "default"
        version:           "0.1.0"
        description?:      string
        labels: {
            environment: "production"
            team:        "frontend"
        }
        annotations?: {}
        #id: "my-app"
    }
    components: {
        web: {
            #kind:       "Component"
            #apiVersion: "core.opm.dev/v1alpha1"
            #metadata: {
                #id:          "web"
                name:         "web"
                type:         "workload"
                workloadType: "stateless"
                labels: {
                    app: "web"
                }
                annotations?: {}
            }
            #elements: {
                Container: {
                    #name!:              "Container"
                    #apiVersion:         "core.opm.dev/v1alpha1"
                    #fullyQualifiedName: "core.opm.dev/v1alpha1.Container"
                    description:         "Single container primitive"
                    kind:                "primitive"
                    labels: {
                        "core.opm.dev/category": "workload"
                    }
                    target: ["component"]
                    type: "trait"
                    #schema: {
                        name:            string
                        image:           string
                        imagePullPolicy: "IfNotPresent"
                        ports?: {}
                        env?: {}
                        resources?: {
                            limits?: {
                                cpu?:    string
                                memory?: string
                            }
                            requests?: {
                                cpu?:    string
                                memory?: string
                            }
                        }
                        volumeMounts?: {}
                    }
                }
                Volume: {
                    #name!:              "Volume"
                    #apiVersion:         "core.opm.dev/v1alpha1"
                    #fullyQualifiedName: "core.opm.dev/v1alpha1.Volume"
                    description:         "A set of volume types for data storage and sharing"
                    kind:                "primitive"
                    labels: {
                        "core.opm.dev/category": "data"
                    }
                    target: ["component"]
                    type: "resource"
                    #schema: {
                        emptyDir?: {
                            medium?:    "node"
                            sizeLimit?: string
                        }
                        persistentClaim?: {
                            size:          "1Gi"
                            accessMode:    "ReadWriteOnce"
                            storageClass?: "standard"
                        }
                        configMap?: {
                            data: {}
                        }
                        secret?: {
                            type?: "Opaque"
                            data: {}
                        }
                    }
                }
            }
            #primitiveElements: ["core.opm.dev/v1alpha1.Container", "core.opm.dev/v1alpha1.Volume"]
            container: {
                image:           "ghcr.io/example/web:2.0.0"
                name:            "web"
                imagePullPolicy: "IfNotPresent"
                ports: {
                    http: {
                        containerPort: 80
                        protocol?:     "TCP"
                    }
                }
                env: {
                    DB_HOST: {
                        name:  "DB_HOST"
                        value: "db"
                    }
                    DB_PORT: {
                        name:  "DB_PORT"
                        value: "5432"
                    }
                    DB_NAME: {
                        name:  "DB_NAME"
                        value: "my-web-app"
                    }
                }
                resources?: {
                    limits?: {
                        cpu?:    string
                        memory?: string
                    }
                    requests?: {
                        cpu?:    string
                        memory?: string
                    }
                }
                volumeMounts: {
                    data: {
                        emptyDir?: {
                            medium?:    "node"
                            sizeLimit?: string
                        }
                        mountPath: "/var/lib/data"
                        persistentClaim: {
                            size:          "10Gi"
                            accessMode:    "ReadWriteOnce"
                            storageClass?: "standard"
                        }
                        configMap?: {
                            data: {}
                        }
                        secret?: {
                            type?: "Opaque"
                            data: {}
                        }
                        subPath?:  string
                        readOnly?: false
                    }
                }
            }
            volumes: {
                data: {
                    emptyDir?: {
                        medium?:    "node"
                        sizeLimit?: string
                    }
                    persistentClaim: {
                        size:          "10Gi"
                        accessMode:    "ReadWriteOnce"
                        storageClass?: "standard"
                    }
                    configMap?: {
                        data: {}
                    }
                    secret?: {
                        type?: "Opaque"
                        data: {}
                    }
                }
            }
        }
        db: {
            #kind:       "Component"
            #apiVersion: "core.opm.dev/v1alpha1"
            #metadata: {
                #id:           "db"
                name!:         "db"
                type:          "resource"
                workloadType?: string
                labels: {
                    app:             "database"
                    "database-type": "postgres"
                }
                annotations?: {}
            }
            #elements: {
                Volume: {
                    #name!:              "Volume"
                    #apiVersion:         "core.opm.dev/v1alpha1"
                    #fullyQualifiedName: "core.opm.dev/v1alpha1.Volume"
                    description:         "A set of volume types for data storage and sharing"
                    kind:                "primitive"
                    labels: {
                        "core.opm.dev/category": "data"
                    }
                    target: ["component"]
                    type: "resource"
                    #schema: {
                        emptyDir?: {
                            medium?:    "node"
                            sizeLimit?: string
                        }
                        persistentClaim?: {
                            size:          "1Gi"
                            accessMode:    "ReadWriteOnce"
                            storageClass?: "standard"
                        }
                        configMap?: {
                            data: {}
                        }
                        secret?: {
                            type?: "Opaque"
                            data: {}
                        }
                    }
                }
            }
            #primitiveElements: ["core.opm.dev/v1alpha1.Volume"]
            volumes: {
                data: {
                    emptyDir?: {
                        medium?:    "node"
                        sizeLimit?: string
                    }
                    persistentClaim: {
                        size:          "20Gi"
                        accessMode:    "ReadWriteOnce"
                        storageClass?: "standard"
                    }
                    configMap?: {
                        data: {}
                    }
                    secret?: {
                        type?: "Opaque"
                        data: {}
                    }
                }
            }
        }
    }
    scopes: {
        network: {
            #kind:       "Scope"
            #apiVersion: "core.opm.dev/v1alpha1"
            #metadata: {
                #id:   "network"
                name!: "network"
                labels?: {}
                annotations?: {}
            }
            #elements: {
                NetworkScope: {
                    #name!:              "NetworkScope"
                    #apiVersion:         "core.opm.dev/v1alpha1"
                    #fullyQualifiedName: "core.opm.dev/v1alpha1.NetworkScope"
                    description:         "Primitive scope to define a shared network boundary"
                    kind:                "primitive"
                    labels: {
                        "core.opm.dev/category": "connectivity"
                    }
                    target: ["scope"]
                    type: "trait"
                    #schema: {
                        policy: {
                            internalCommunication?: true
                            externalCommunication?: false
                        }
                    }
                }
            }
            #primitiveElements: ["core.opm.dev/v1alpha1.NetworkScope"]
            appliesTo: [{
                #kind:       "Component"
                #apiVersion: "core.opm.dev/v1alpha1"
                #elements: {
                    Container: {
                        #name!:              "Container"
                        #apiVersion:         "core.opm.dev/v1alpha1"
                        #fullyQualifiedName: "core.opm.dev/v1alpha1.Container"
                        description:         "Single container primitive"
                        kind:                "primitive"
                        labels: {
                            "core.opm.dev/category": "workload"
                        }
                        target: ["component"]
                        type: "trait"
                        #schema: {
                            name:            string
                            image:           string
                            imagePullPolicy: "IfNotPresent"
                            ports?: {}
                            env?: {}
                            resources?: {
                                limits?: {
                                    cpu?:    string
                                    memory?: string
                                }
                                requests?: {
                                    cpu?:    string
                                    memory?: string
                                }
                            }
                            volumeMounts?: {}
                        }
                    }
                    Volume: {
                        #name!:              "Volume"
                        #apiVersion:         "core.opm.dev/v1alpha1"
                        #fullyQualifiedName: "core.opm.dev/v1alpha1.Volume"
                        description:         "A set of volume types for data storage and sharing"
                        kind:                "primitive"
                        labels: {
                            "core.opm.dev/category": "data"
                        }
                        target: ["component"]
                        type: "resource"
                        #schema: {
                            emptyDir?: {
                                medium?:    "node"
                                sizeLimit?: string
                            }
                            persistentClaim?: {
                                size:          "1Gi"
                                accessMode:    "ReadWriteOnce"
                                storageClass?: "standard"
                            }
                            configMap?: {
                                data: {}
                            }
                            secret?: {
                                type?: "Opaque"
                                data: {}
                            }
                        }
                    }
                }
                #metadata: {
                    #id:          "web"
                    name:         "web"
                    type:         "workload"
                    workloadType: "stateless"
                    labels: {
                        app: "web"
                    }
                    annotations?: {}
                }
                #primitiveElements: ["core.opm.dev/v1alpha1.Container", "core.opm.dev/v1alpha1.Volume"]
                container: {
                    image:           "ghcr.io/example/web:2.0.0"
                    name:            "web"
                    imagePullPolicy: "IfNotPresent"
                    ports: {
                        http: {
                            containerPort: 80
                            protocol?:     "TCP"
                        }
                    }
                    env: {
                        DB_HOST: {
                            name:  "DB_HOST"
                            value: "db"
                        }
                        DB_PORT: {
                            name:  "DB_PORT"
                            value: "5432"
                        }
                        DB_NAME: {
                            name:  "DB_NAME"
                            value: "my-web-app"
                        }
                    }
                    resources?: {
                        limits?: {
                            cpu?:    string
                            memory?: string
                        }
                        requests?: {
                            cpu?:    string
                            memory?: string
                        }
                    }
                    volumeMounts: {
                        data: {
                            emptyDir?: {
                                medium?:    "node"
                                sizeLimit?: string
                            }
                            mountPath: "/var/lib/data"
                            persistentClaim: {
                                size:          "10Gi"
                                accessMode:    "ReadWriteOnce"
                                storageClass?: "standard"
                            }
                            configMap?: {
                                data: {}
                            }
                            secret?: {
                                type?: "Opaque"
                                data: {}
                            }
                            subPath?:  string
                            readOnly?: false
                        }
                    }
                }
                volumes: {
                    data: {
                        emptyDir?: {
                            medium?:    "node"
                            sizeLimit?: string
                        }
                        persistentClaim: {
                            size:          "10Gi"
                            accessMode:    "ReadWriteOnce"
                            storageClass?: "standard"
                        }
                        configMap?: {
                            data: {}
                        }
                        secret?: {
                            type?: "Opaque"
                            data: {}
                        }
                    }
                }
            }, {
                #kind:       "Component"
                #apiVersion: "core.opm.dev/v1alpha1"
                #elements: {
                    Volume: {
                        #name!:              "Volume"
                        #apiVersion:         "core.opm.dev/v1alpha1"
                        #fullyQualifiedName: "core.opm.dev/v1alpha1.Volume"
                        description:         "A set of volume types for data storage and sharing"
                        kind:                "primitive"
                        labels: {
                            "core.opm.dev/category": "data"
                        }
                        target: ["component"]
                        type: "resource"
                        #schema: {
                            emptyDir?: {
                                medium?:    "node"
                                sizeLimit?: string
                            }
                            persistentClaim?: {
                                size:          "1Gi"
                                accessMode:    "ReadWriteOnce"
                                storageClass?: "standard"
                            }
                            configMap?: {
                                data: {}
                            }
                            secret?: {
                                type?: "Opaque"
                                data: {}
                            }
                        }
                    }
                }
                #metadata: {
                    #id:           "db"
                    name!:         "db"
                    type:          "resource"
                    workloadType?: string
                    labels: {
                        app:             "database"
                        "database-type": "postgres"
                    }
                    annotations?: {}
                }
                #primitiveElements: ["core.opm.dev/v1alpha1.Volume"]
                volumes: {
                    data: {
                        emptyDir?: {
                            medium?:    "node"
                            sizeLimit?: string
                        }
                        persistentClaim: {
                            size:          "20Gi"
                            accessMode:    "ReadWriteOnce"
                            storageClass?: "standard"
                        }
                        configMap?: {
                            data: {}
                        }
                        secret?: {
                            type?: "Opaque"
                            data: {}
                        }
                    }
                }
            }]
            networkScope: {
                policy: {
                    internalCommunication?: true
                    externalCommunication?: false
                }
            }
            policy: {
                allowInternal: true
                allowExternal: false
            }
        }
    }
    values: {
        web: {
            image: "ghcr.io/example/web:2.0.0"
        }
        dbVolume: {
            emptyDir?: {
                medium?:    "node"
                sizeLimit?: string
            }
            persistentClaim: {
                size:          "50Gi"
                accessMode:    "ReadWriteOnce"
                storageClass?: "standard"
            }
            configMap?: {
                data: {}
            }
            secret?: {
                type?: "Opaque"
                data: {}
            }
        }
    }
    #status: {
        componentCount: 2
        scopeCount:     1
    }
}
components: {
    auditLogging: {
        #kind:       "Component"
        #apiVersion: "core.opm.dev/v1alpha1"
        #metadata: {
            #id:          "auditLogging"
            name!:        "auditLogging"
            type:         "workload"
            workloadType: "stateless"
            labels: {
                app: "audit-logging"
            }
            annotations?: {}
        }
        #elements: {
            Container: {
                #name!:              "Container"
                #apiVersion:         "core.opm.dev/v1alpha1"
                #fullyQualifiedName: "core.opm.dev/v1alpha1.Container"
                description:         "Single container primitive"
                kind:                "primitive"
                labels: {
                    "core.opm.dev/category": "workload"
                }
                target: ["component"]
                type: "trait"
                #schema: {
                    name:            string
                    image:           string
                    imagePullPolicy: "IfNotPresent"
                    ports?: {}
                    env?: {}
                    resources?: {
                        limits?: {
                            cpu?:    string
                            memory?: string
                        }
                        requests?: {
                            cpu?:    string
                            memory?: string
                        }
                    }
                    volumeMounts?: {}
                }
            }
        }
        #primitiveElements: ["core.opm.dev/v1alpha1.Container"]
        container: {
            name:            "audit-logging"
            image:           "ghcr.io/example/audit-logging:1.0.0"
            imagePullPolicy: "IfNotPresent"
            ports: {
                http: {
                    containerPort: 8080
                    protocol?:     "TCP"
                }
            }
            env: {
                LOG_LEVEL: {
                    name:  "LOG_LEVEL"
                    value: "info"
                }
            }
            resources?: {
                limits?: {
                    cpu?:    string
                    memory?: string
                }
                requests?: {
                    cpu?:    string
                    memory?: string
                }
            }
            volumeMounts?: {}
        }
    }
}
#allComponents: {
    auditLogging: {
        #kind:       "Component"
        #apiVersion: "core.opm.dev/v1alpha1"
        #metadata: {
            #id:          "auditLogging"
            name!:        "auditLogging"
            type:         "workload"
            workloadType: "stateless"
            labels: {
                app: "audit-logging"
            }
            annotations?: {}
        }
        #elements: {
            Container: {
                #name!:              "Container"
                #apiVersion:         "core.opm.dev/v1alpha1"
                #fullyQualifiedName: "core.opm.dev/v1alpha1.Container"
                description:         "Single container primitive"
                kind:                "primitive"
                labels: {
                    "core.opm.dev/category": "workload"
                }
                target: ["component"]
                type: "trait"
                #schema: {
                    name:            string
                    image:           string
                    imagePullPolicy: "IfNotPresent"
                    ports?: {}
                    env?: {}
                    resources?: {
                        limits?: {
                            cpu?:    string
                            memory?: string
                        }
                        requests?: {
                            cpu?:    string
                            memory?: string
                        }
                    }
                    volumeMounts?: {}
                }
            }
        }
        #primitiveElements: ["core.opm.dev/v1alpha1.Container"]
        container: {
            image:           "ghcr.io/example/audit-logging:1.0.0"
            name:            "audit-logging"
            imagePullPolicy: "IfNotPresent"
            ports: {
                http: {
                    containerPort: 8080
                    protocol?:     "TCP"
                }
            }
            env: {
                LOG_LEVEL: {
                    name:  "LOG_LEVEL"
                    value: "info"
                }
            }
            resources?: {
                limits?: {
                    cpu?:    string
                    memory?: string
                }
                requests?: {
                    cpu?:    string
                    memory?: string
                }
            }
            volumeMounts?: {}
        }
    }
    web: {
        #kind:       "Component"
        #apiVersion: "core.opm.dev/v1alpha1"
        #metadata: {
            #id:          "web"
            name:         "web"
            type:         "workload"
            workloadType: "stateless"
            labels: {
                app: "web"
            }
            annotations?: {}
        }
        #elements: {
            Container: {
                #name!:              "Container"
                #apiVersion:         "core.opm.dev/v1alpha1"
                #fullyQualifiedName: "core.opm.dev/v1alpha1.Container"
                description:         "Single container primitive"
                kind:                "primitive"
                labels: {
                    "core.opm.dev/category": "workload"
                }
                target: ["component"]
                type: "trait"
                #schema: {
                    name:            string
                    image:           string
                    imagePullPolicy: "IfNotPresent"
                    ports?: {}
                    env?: {}
                    resources?: {
                        limits?: {
                            cpu?:    string
                            memory?: string
                        }
                        requests?: {
                            cpu?:    string
                            memory?: string
                        }
                    }
                    volumeMounts?: {}
                }
            }
            Volume: {
                #name!:              "Volume"
                #apiVersion:         "core.opm.dev/v1alpha1"
                #fullyQualifiedName: "core.opm.dev/v1alpha1.Volume"
                description:         "A set of volume types for data storage and sharing"
                kind:                "primitive"
                labels: {
                    "core.opm.dev/category": "data"
                }
                target: ["component"]
                type: "resource"
                #schema: {
                    emptyDir?: {
                        medium?:    "node"
                        sizeLimit?: string
                    }
                    persistentClaim?: {
                        size:          "1Gi"
                        accessMode:    "ReadWriteOnce"
                        storageClass?: "standard"
                    }
                    configMap?: {
                        data: {}
                    }
                    secret?: {
                        type?: "Opaque"
                        data: {}
                    }
                }
            }
        }
        #primitiveElements: ["core.opm.dev/v1alpha1.Container", "core.opm.dev/v1alpha1.Volume"]
        container: {
            image:           "ghcr.io/example/web:2.0.0"
            name:            "web"
            imagePullPolicy: "IfNotPresent"
            ports: {
                http: {
                    containerPort: 80
                    protocol?:     "TCP"
                }
            }
            env: {
                DB_HOST: {
                    name:  "DB_HOST"
                    value: "db"
                }
                DB_PORT: {
                    name:  "DB_PORT"
                    value: "5432"
                }
                DB_NAME: {
                    name:  "DB_NAME"
                    value: "my-web-app"
                }
            }
            resources?: {
                limits?: {
                    cpu?:    string
                    memory?: string
                }
                requests?: {
                    cpu?:    string
                    memory?: string
                }
            }
            volumeMounts: {
                data: {
                    emptyDir?: {
                        medium?:    "node"
                        sizeLimit?: string
                    }
                    mountPath: "/var/lib/data"
                    persistentClaim: {
                        size:          "10Gi"
                        accessMode:    "ReadWriteOnce"
                        storageClass?: "standard"
                    }
                    configMap?: {
                        data: {}
                    }
                    secret?: {
                        type?: "Opaque"
                        data: {}
                    }
                    subPath?:  string
                    readOnly?: false
                }
            }
        }
        volumes: {
            data: {
                emptyDir?: {
                    medium?:    "node"
                    sizeLimit?: string
                }
                persistentClaim: {
                    size:          "10Gi"
                    accessMode:    "ReadWriteOnce"
                    storageClass?: "standard"
                }
                configMap?: {
                    data: {}
                }
                secret?: {
                    type?: "Opaque"
                    data: {}
                }
            }
        }
    }
    db: {
        #kind:       "Component"
        #apiVersion: "core.opm.dev/v1alpha1"
        #metadata: {
            #id:           "db"
            name!:         "db"
            type:          "resource"
            workloadType?: string
            labels: {
                app:             "database"
                "database-type": "postgres"
            }
            annotations?: {}
        }
        #elements: {
            Volume: {
                #name!:              "Volume"
                #apiVersion:         "core.opm.dev/v1alpha1"
                #fullyQualifiedName: "core.opm.dev/v1alpha1.Volume"
                description:         "A set of volume types for data storage and sharing"
                kind:                "primitive"
                labels: {
                    "core.opm.dev/category": "data"
                }
                target: ["component"]
                type: "resource"
                #schema: {
                    emptyDir?: {
                        medium?:    "node"
                        sizeLimit?: string
                    }
                    persistentClaim?: {
                        size:          "1Gi"
                        accessMode:    "ReadWriteOnce"
                        storageClass?: "standard"
                    }
                    configMap?: {
                        data: {}
                    }
                    secret?: {
                        type?: "Opaque"
                        data: {}
                    }
                }
            }
        }
        #primitiveElements: ["core.opm.dev/v1alpha1.Volume"]
        volumes: {
            data: {
                emptyDir?: {
                    medium?:    "node"
                    sizeLimit?: string
                }
                persistentClaim: {
                    size:          "20Gi"
                    accessMode:    "ReadWriteOnce"
                    storageClass?: "standard"
                }
                configMap?: {
                    data: {}
                }
                secret?: {
                    type?: "Opaque"
                    data: {}
                }
            }
        }
    }
}
scopes?: {}
#allScopes: {
    network: {
        #kind:       "Scope"
        #apiVersion: "core.opm.dev/v1alpha1"
        #metadata: {
            #id:   "network"
            name!: "network"
            labels?: {}
            annotations?: {}
        }
        #elements: {
            NetworkScope: {
                #name!:              "NetworkScope"
                #apiVersion:         "core.opm.dev/v1alpha1"
                #fullyQualifiedName: "core.opm.dev/v1alpha1.NetworkScope"
                description:         "Primitive scope to define a shared network boundary"
                kind:                "primitive"
                labels: {
                    "core.opm.dev/category": "connectivity"
                }
                target: ["scope"]
                type: "trait"
                #schema: {
                    policy: {
                        internalCommunication?: true
                        externalCommunication?: false
                    }
                }
            }
        }
        #primitiveElements: ["core.opm.dev/v1alpha1.NetworkScope"]
        appliesTo: [{
            #kind:       "Component"
            #apiVersion: "core.opm.dev/v1alpha1"
            #metadata: {
                #id:          "web"
                name:         "web"
                type:         "workload"
                workloadType: "stateless"
                labels: {
                    app: "web"
                }
                annotations?: {}
            }
            #elements: {
                Container: {
                    #name!:              "Container"
                    #apiVersion:         "core.opm.dev/v1alpha1"
                    #fullyQualifiedName: "core.opm.dev/v1alpha1.Container"
                    description:         "Single container primitive"
                    kind:                "primitive"
                    labels: {
                        "core.opm.dev/category": "workload"
                    }
                    target: ["component"]
                    type: "trait"
                    #schema: {
                        name:            string
                        image:           string
                        imagePullPolicy: "IfNotPresent"
                        ports?: {}
                        env?: {}
                        resources?: {
                            limits?: {
                                cpu?:    string
                                memory?: string
                            }
                            requests?: {
                                cpu?:    string
                                memory?: string
                            }
                        }
                        volumeMounts?: {}
                    }
                }
                Volume: {
                    #name!:              "Volume"
                    #apiVersion:         "core.opm.dev/v1alpha1"
                    #fullyQualifiedName: "core.opm.dev/v1alpha1.Volume"
                    description:         "A set of volume types for data storage and sharing"
                    kind:                "primitive"
                    labels: {
                        "core.opm.dev/category": "data"
                    }
                    target: ["component"]
                    type: "resource"
                    #schema: {
                        emptyDir?: {
                            medium?:    "node"
                            sizeLimit?: string
                        }
                        persistentClaim?: {
                            size:          "1Gi"
                            accessMode:    "ReadWriteOnce"
                            storageClass?: "standard"
                        }
                        configMap?: {
                            data: {}
                        }
                        secret?: {
                            type?: "Opaque"
                            data: {}
                        }
                    }
                }
            }
            #primitiveElements: ["core.opm.dev/v1alpha1.Container", "core.opm.dev/v1alpha1.Volume"]
            container: {
                image:           "ghcr.io/example/web:2.0.0"
                name:            "web"
                imagePullPolicy: "IfNotPresent"
                ports: {
                    http: {
                        containerPort: 80
                        protocol?:     "TCP"
                    }
                }
                env: {
                    DB_HOST: {
                        name:  "DB_HOST"
                        value: "db"
                    }
                    DB_PORT: {
                        name:  "DB_PORT"
                        value: "5432"
                    }
                    DB_NAME: {
                        name:  "DB_NAME"
                        value: "my-web-app"
                    }
                }
                resources?: {
                    limits?: {
                        cpu?:    string
                        memory?: string
                    }
                    requests?: {
                        cpu?:    string
                        memory?: string
                    }
                }
                volumeMounts: {
                    data: {
                        emptyDir?: {
                            medium?:    "node"
                            sizeLimit?: string
                        }
                        mountPath: "/var/lib/data"
                        persistentClaim: {
                            size:          "10Gi"
                            accessMode:    "ReadWriteOnce"
                            storageClass?: "standard"
                        }
                        configMap?: {
                            data: {}
                        }
                        secret?: {
                            type?: "Opaque"
                            data: {}
                        }
                        subPath?:  string
                        readOnly?: false
                    }
                }
            }
            volumes: {
                data: {
                    emptyDir?: {
                        medium?:    "node"
                        sizeLimit?: string
                    }
                    persistentClaim: {
                        size:          "10Gi"
                        accessMode:    "ReadWriteOnce"
                        storageClass?: "standard"
                    }
                    configMap?: {
                        data: {}
                    }
                    secret?: {
                        type?: "Opaque"
                        data: {}
                    }
                }
            }
        }, {
            #kind:       "Component"
            #apiVersion: "core.opm.dev/v1alpha1"
            #metadata: {
                #id:           "db"
                name!:         "db"
                type:          "resource"
                workloadType?: string
                labels: {
                    app:             "database"
                    "database-type": "postgres"
                }
                annotations?: {}
            }
            #elements: {
                Volume: {
                    #name!:              "Volume"
                    #apiVersion:         "core.opm.dev/v1alpha1"
                    #fullyQualifiedName: "core.opm.dev/v1alpha1.Volume"
                    description:         "A set of volume types for data storage and sharing"
                    kind:                "primitive"
                    labels: {
                        "core.opm.dev/category": "data"
                    }
                    target: ["component"]
                    type: "resource"
                    #schema: {
                        emptyDir?: {
                            medium?:    "node"
                            sizeLimit?: string
                        }
                        persistentClaim?: {
                            size:          "1Gi"
                            accessMode:    "ReadWriteOnce"
                            storageClass?: "standard"
                        }
                        configMap?: {
                            data: {}
                        }
                        secret?: {
                            type?: "Opaque"
                            data: {}
                        }
                    }
                }
            }
            #primitiveElements: ["core.opm.dev/v1alpha1.Volume"]
            volumes: {
                data: {
                    emptyDir?: {
                        medium?:    "node"
                        sizeLimit?: string
                    }
                    persistentClaim: {
                        size:          "20Gi"
                        accessMode:    "ReadWriteOnce"
                        storageClass?: "standard"
                    }
                    configMap?: {
                        data: {}
                    }
                    secret?: {
                        type?: "Opaque"
                        data: {}
                    }
                }
            }
        }]
        networkScope: {
            policy: {
                internalCommunication?: true
                externalCommunication?: false
            }
        }
        policy: {
            allowInternal: true
            allowExternal: false
        }
    }
}
values: {
    web: {
        image: "ghcr.io/example/web:2.0.0"
    }
    dbVolume: {
        emptyDir?: {
            medium?:    "node"
            sizeLimit?: string
        }
        persistentClaim: {
            size:          "50Gi"
            accessMode:    "ReadWriteOnce"
            storageClass?: "standard"
        }
        configMap?: {
            data: {}
        }
        secret?: {
            type?: "Opaque"
            data: {}
        }
    }
    auditLogging: {
        image: "ghcr.io/example/audit-logging:1.0.1"
    }
}
#status: {
    totalComponentCount: 3
    platformScopes: [
        for id, scope in scopes if scope.#metadata.immutable {
            id
        }]
    platformComponentCount: 1
    platformScopeCount:     0
}
