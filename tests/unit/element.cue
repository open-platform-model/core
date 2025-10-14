// Element Logic Tests
// Tests for element-level computed values and logic
package unit

import (
	core "github.com/open-platform-model/core/elements/core"
)

elementTests: {
	//////////////////////////////////////////////////////////////////
	// Element Name Computation Tests
	//////////////////////////////////////////////////////////////////

	// Test: Container element fullyQualifiedName
	"element/container-fqn": {
		result: core.#ContainerElement.#fullyQualifiedName
		result: "elements.opm.dev/core/v1alpha1.Container"
	}

	// Test: StatelessWorkload element fullyQualifiedName
	"element/stateless-fqn": {
		result: core.#StatelessWorkloadElement.#fullyQualifiedName
		result: "elements.opm.dev/core/v1alpha1.StatelessWorkload"
	}

	// Test: StatefulWorkload element fullyQualifiedName
	"element/stateful-fqn": {
		result: core.#StatefulWorkloadElement.#fullyQualifiedName
		result: "elements.opm.dev/core/v1alpha1.StatefulWorkload"
	}

	// Test: SimpleDatabase element fullyQualifiedName
	"element/simple-database-fqn": {
		result: core.#SimpleDatabaseElement.#fullyQualifiedName
		result: "elements.opm.dev/core/v1alpha1.SimpleDatabase"
	}

	// Test: Container element camelCase name
	"element/container-camel": {
		result: core.#ContainerElement.#nameCamel
		result: "container"
	}

	// Test: StatelessWorkload element camelCase name
	"element/stateless-camel": {
		result: core.#StatelessWorkloadElement.#nameCamel
		result: "statelessWorkload"
	}

	// Test: StatefulWorkload element camelCase name
	"element/stateful-camel": {
		result: core.#StatefulWorkloadElement.#nameCamel
		result: "statefulWorkload"
	}

	// Test: SimpleDatabase element camelCase name
	"element/simple-database-camel": {
		result: core.#SimpleDatabaseElement.#nameCamel
		result: "simpleDatabase"
	}

	//////////////////////////////////////////////////////////////////
	// Composite Element Primitive Extraction
	//////////////////////////////////////////////////////////////////

	// Test: StatelessWorkload composite primitive extraction
	"composite/stateless-primitives": {
		result: core.#StatelessWorkloadElement.#primitiveElements
		result: [
			"elements.opm.dev/core/v1alpha1.Container",
		]
	}

	// Test: StatefulWorkload composite primitive extraction
	"composite/stateful-primitives": {
		result: core.#StatefulWorkloadElement.#primitiveElements
		result: [
			"elements.opm.dev/core/v1alpha1.Container",
		]
	}

	// Test: SimpleDatabase composite primitive extraction
	"composite/simple-database-primitives": {
		result: core.#SimpleDatabaseElement.#primitiveElements
		result: [
			"elements.opm.dev/core/v1alpha1.Container",
			"elements.opm.dev/core/v1alpha1.Volume",
		]
	}

	// Test: DaemonWorkload composite primitive extraction
	"composite/daemon-primitives": {
		result: core.#DaemonWorkloadElement.#primitiveElements
		result: [
			"elements.opm.dev/core/v1alpha1.Container",
		]
	}

	// Test: TaskWorkload composite primitive extraction
	"composite/task-primitives": {
		result: core.#TaskWorkloadElement.#primitiveElements
		result: [
			"elements.opm.dev/core/v1alpha1.Container",
		]
	}

	// Test: ScheduledTaskWorkload composite primitive extraction
	"composite/scheduled-task-primitives": {
		result: core.#ScheduledTaskWorkloadElement.#primitiveElements
		result: [
			"elements.opm.dev/core/v1alpha1.Container",
		]
	}

	//////////////////////////////////////////////////////////////////
	// Element Kinds
	//////////////////////////////////////////////////////////////////

	// Test: Container element kind
	"element/container-kind": {
		result: core.#ContainerElement.kind
		result: "primitive"
	}

	// Test: Volume element kind
	"element/volume-kind": {
		result: core.#VolumeElement.kind
		result: "primitive"
	}

	// Test: StatelessWorkload element kind
	"element/stateless-kind": {
		result: core.#StatelessWorkloadElement.kind
		result: "composite"
	}

	// Test: StatefulWorkload element kind
	"element/stateful-kind": {
		result: core.#StatefulWorkloadElement.kind
		result: "composite"
	}

	// Test: Replicas element kind
	"element/replicas-kind": {
		result: core.#ReplicasElement.kind
		result: "modifier"
	}

	// Test: HealthCheck element kind
	"element/healthcheck-kind": {
		result: core.#HealthCheckElement.kind
		result: "modifier"
	}

	//////////////////////////////////////////////////////////////////
	// Element Annotations
	//////////////////////////////////////////////////////////////////

	// Test: StatelessWorkload workload type annotation
	"element/stateless-annotation": {
		result: core.#StatelessWorkloadElement.annotations["core.opm.dev/workload-type"]
		result: "stateless"
	}

	// Test: StatefulWorkload workload type annotation
	"element/stateful-annotation": {
		result: core.#StatefulWorkloadElement.annotations["core.opm.dev/workload-type"]
		result: "stateful"
	}

	// Test: DaemonWorkload workload type annotation
	"element/daemon-annotation": {
		result: core.#DaemonWorkloadElement.annotations["core.opm.dev/workload-type"]
		result: "daemon"
	}

	// Test: TaskWorkload workload type annotation
	"element/task-annotation": {
		result: core.#TaskWorkloadElement.annotations["core.opm.dev/workload-type"]
		result: "task"
	}

	// Test: ScheduledTaskWorkload workload type annotation
	"element/scheduled-task-annotation": {
		result: core.#ScheduledTaskWorkloadElement.annotations["core.opm.dev/workload-type"]
		result: "scheduled-task"
	}
}
