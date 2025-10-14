// Component Rendering Integration Tests
// Tests component → platform resource transformation
package integration

import (
	opm "github.com/open-platform-model/core"
	core "github.com/open-platform-model/core/elements/core"
)

renderingTests: {
	//////////////////////////////////////////////////////////////////
	// StatelessWorkload → Kubernetes Deployment
	//////////////////////////////////////////////////////////////////

	"rendering/stateless-to-deployment": {
		// Define component
		_component: core.#StatelessWorkload & {
			#metadata: {
				#id:  "web"
				name: "web"
			}
			statelessWorkload: {
				container: {
					name:  "nginx"
					image: "nginx:latest"
					ports: http: {
						name:       "http"
						targetPort: 80
					}
				}
				replicas: count: 3
			}
		}

		// TODO: Define transformer that converts to K8s Deployment
		// TODO: Apply transformer
		// TODO: Validate output structure
	}

	//////////////////////////////////////////////////////////////////
	// StatefulWorkload → Kubernetes StatefulSet
	//////////////////////////////////////////////////////////////////

	"rendering/stateful-to-statefulset": {
		// Define component
		_component: core.#StatefulWorkload & {
			#metadata: {
				#id:  "db"
				name: "postgres"
			}
			statefulWorkload: {
				container: {
					name:  "postgres"
					image: "postgres:15"
					ports: db: {
						name:       "db"
						targetPort: 5432
					}
				}
				serviceName: "postgres-service"
			}
		}

		// TODO: Define transformer that converts to K8s StatefulSet
		// TODO: Apply transformer
		// TODO: Validate output structure
	}

	//////////////////////////////////////////////////////////////////
	// SimpleDatabase → StatefulSet + Volume
	//////////////////////////////////////////////////////////////////

	"rendering/simple-database-to-statefulset-volume": {
		// Define component
		_component: core.#SimpleDatabase & {
			#metadata: {
				#id:  "db"
				name: "database"
			}
			simpleDatabase: {
				engine:   "postgres"
				dbName:   "myapp"
				username: "admin"
				password: "secret"
				persistence: {
					enabled: true
					size:    "10Gi"
				}
			}
		}

		// TODO: Define transformer
		// TODO: Validate StatefulSet created with correct env vars
		// TODO: Validate PVC created with correct size
		// TODO: Validate volume mount in container
	}

	//////////////////////////////////////////////////////////////////
	// Multiple Composites → Multiple Resources
	//////////////////////////////////////////////////////////////////

	"rendering/expose-creates-service": {
		// Define component with StatelessWorkload + Expose
		_component: opm.#Component & {
			#metadata: {
				#id:  "web"
				name: "web"
			}
			core.#StatelessWorkload
			core.#Expose

			statelessWorkload: container: {
				name:  "nginx"
				image: "nginx:latest"
				ports: http: {
					name:       "http"
					targetPort: 80
				}
			}

			expose: {
				type: "LoadBalancer"
				ports: http: {
					port:       80
					targetPort: 80
				}
			}
		}

		// TODO: Validate Deployment created
		// TODO: Validate Service created with type LoadBalancer
		// TODO: Validate port mapping in both resources
	}
}
