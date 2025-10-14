// Component Logic Tests
// Tests for component-level computed values and logic
package unit

import (
	opm "github.com/open-platform-model/core"
	core "github.com/open-platform-model/core/elements/core"
)

componentTests: {
	//////////////////////////////////////////////////////////////////
	// Workload Type Derivation
	//////////////////////////////////////////////////////////////////

	// Test: Stateless workload type derivation
	"component/workload-type-stateless": opm.#Component & {
		#metadata: {
			#id:          "web"
			workloadType: "stateless"
		}
		#elements: {
			StatelessWorkload: core.#StatelessWorkloadElement
		}
		statelessWorkload: container: {
			name:  "web"
			image: "nginx:latest"
		}
	}

	// Test: Stateful workload type derivation
	"component/workload-type-stateful": opm.#Component & {
		#metadata: {
			#id:          "db"
			workloadType: "stateful"
		}
		#elements: {
			StatefulWorkload: core.#StatefulWorkloadElement
		}
		statefulWorkload: container: {
			name:  "db"
			image: "postgres:15"
		}
	}

	// Test: Daemon workload type derivation
	"component/workload-type-daemon": opm.#Component & {
		#metadata: {
			#id:          "logger"
			workloadType: "daemon"
		}
		#elements: {
			DaemonWorkload: core.#DaemonWorkloadElement
		}
		daemonWorkload: container: {
			name:  "logger"
			image: "fluentd:latest"
		}
	}

	// Test: Empty workload type for non-workload components
	"component/workload-type-empty": opm.#Component & {
		#metadata: {
			#id:          "config"
			workloadType: ""
		}
		#elements: {
			ConfigMap: core.#ConfigMapElement
		}
		configMap: data: {"app.conf": "key=value"}
	}

	//////////////////////////////////////////////////////////////////
	// Primitive Element Extraction
	//////////////////////////////////////////////////////////////////

	// Test: Single composite element primitive extraction
	"component/primitive-extraction-single": opm.#Component & {
		#metadata: #id: "web"
		#elements: {
			StatelessWorkload: core.#StatelessWorkloadElement
		}
		statelessWorkload: container: {
			name:  "web"
			image: "nginx:latest"
		}

		// Should extract all primitives from StatelessWorkload
		#primitiveElements: [
			"elements.opm.dev/core/v1alpha1.Container",
		]
	}

	// Test: Multiple elements primitive extraction
	"component/primitive-extraction-multiple": opm.#Component & {
		#metadata: #id: "web"
		#elements: {
			StatelessWorkload: core.#StatelessWorkloadElement
			Expose:            core.#ExposeElement
		}
		statelessWorkload: container: {
			name:  "web"
			image: "nginx:latest"
		}
		expose: type: "LoadBalancer"

		// Should extract primitives from StatelessWorkload + Expose
		#primitiveElements: [
			"elements.opm.dev/core/v1alpha1.Container",
			"elements.opm.dev/core/v1alpha1.Expose",
		]
	}

	// Test: Primitive element extraction
	"component/primitive-extraction-primitive": opm.#Component & {
		#metadata: #id: "nginx"
		#elements: {
			Container: core.#ContainerElement
		}
		container: {
			name:  "nginx"
			image: "nginx:latest"
		}

		// Should extract just the primitive
		#primitiveElements: [
			"elements.opm.dev/core/v1alpha1.Container",
		]
	}

	//////////////////////////////////////////////////////////////////
	// Component Usage Patterns
	//////////////////////////////////////////////////////////////////

	// Test: Using #StatelessWorkload composition pattern
	"component/usage-stateless-composition": core.#StatelessWorkload & {
		#metadata: {
			#id:          "web"
			name:         "web"
			workloadType: "stateless"
		}

		statelessWorkload: container: {
			name:  "nginx"
			image: "nginx:latest"
		}

		// Verify it's a valid component
		#kind: "Component"
		container: image: "nginx:latest"
	}

	// Test: Using #SimpleDatabase composition pattern
	"component/usage-simple-database-composition": core.#SimpleDatabase & {
		#metadata: {
			#id:          "db"
			name:         "database"
			workloadType: "stateful"
		}

		simpleDatabase: {
			engine:   "postgres"
			version:  "15"
			dbName:   "myapp"
			username: "app_user"
			password: "app_pass"
			persistence: {
				enabled: true
				size:    "50Gi"
			}
		}

		// Verify it's a valid component
		#kind: "Component"
		statefulWorkload: container: image: "postgres:latest"
		volume: dbData: name:               "db-data"
	}
}
