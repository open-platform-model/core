package kubernetes

import (
	opm "github.com/open-platform-model/core"
)

// Batch API Group - elements.opm.dev/k8s/batch/v1

#JobElement: opm.#Primitive & {
	name:        "Job"
	#apiVersion: "elements.opm.dev/k8s/batch/v1"
	target: ["component"]
	schema: #JobSpec
	annotations: {
		"core.opm.dev/workload-type": "task"
	}
	description: "Kubernetes Job - run-to-completion workload"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "batch"
	}
}

#Job: close(opm.#Component & {
	#elements: (#JobElement.#fullyQualifiedName): #JobElement

	jobs: [string]: #JobSpec
})

#CronJobElement: opm.#Primitive & {
	name:        "CronJob"
	#apiVersion: "elements.opm.dev/k8s/batch/v1"
	target: ["component"]
	schema: #CronJobSpec
	annotations: {
		"core.opm.dev/workload-type": "scheduled-task"
	}
	description: "Kubernetes CronJob - scheduled recurring workload"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "batch"
	}
}

#CronJob: close(opm.#Component & {
	#elements: (#CronJobElement.#fullyQualifiedName): #CronJobElement

	cronJobs: [string]: #CronJobSpec
})
