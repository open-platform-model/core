package kubernetes

import (
	opm "github.com/open-platform-model/core"
)

// Batch API Group - k8s.io/api/batch/v1

#JobElement: opm.#Primitive & {
	name:        "Job"
	#apiVersion: "k8s.io/api/batch/v1"
	target: ["component"]
	schema:       #JobSpec
	workloadType: "task"
	description:  "Kubernetes Job - run-to-completion workload"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "batch"
	}
}

#CronJobElement: opm.#Primitive & {
	name:        "CronJob"
	#apiVersion: "k8s.io/api/batch/v1"
	target: ["component"]
	schema:       #CronJobSpec
	workloadType: "scheduled-task"
	description:  "Kubernetes CronJob - scheduled recurring workload"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "batch"
	}
}
