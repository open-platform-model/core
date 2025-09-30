package schema

/////////////////////////////////////////////////////////////////
//// Data Schema Definitions
/////////////////////////////////////////////////////////////////

// Volume specification
#VolumeSpec: {
	emptyDir?: {
		medium?:    *"node" | "memory"
		sizeLimit?: string
	}
	persistentClaim?: #PersistentClaimSpec
	configMap?:       #ConfigMapSpec
	secret?:          #SecretSpec
	...
}

// Persistent claim specification
#PersistentClaimSpec: {
	size:          string
	accessMode:    "ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany" | *"ReadWriteOnce"
	storageClass?: string | *"standard"
}

// ConfigMap specification
#ConfigMapSpec: {
	data: [string]: string
}

// Secret specification
#SecretSpec: {
	type?: string | *"Opaque"
	data: [string]: string // Base64-encoded values
}

// Simple database specification
#SimpleDatabaseSpec: {
	engine:   "postgres" | "mysql" | "mongodb" | "redis" | *"postgres"
	version:  string | *"latest"
	dbName:   string | *"appdb"
	username: string | *"admin"
	password: string | *"password"
	persistence: {
		enabled: bool | *true
		size:    string | *"1Gi"
	}
}
