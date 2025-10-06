package kubernetes

import (
	opm "github.com/open-platform-model/core"
)

// RBAC API Group - elements.opm.dev/k8s/rbac/v1

#RoleElement: opm.#Primitive & {
	name:        "Role"
	#apiVersion: "elements.opm.dev/k8s/rbac/v1"
	target: ["scope"]
	schema:      #RoleSpec
	description: "Kubernetes Role - namespace-scoped permissions"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "rbac"
	}
}

#Role: close(opm.#Component & {
	#elements: (#RoleElement.#fullyQualifiedName): #RoleElement

	roles: [string]: #RoleSpec
})

#RoleBindingElement: opm.#Primitive & {
	name:        "RoleBinding"
	#apiVersion: "elements.opm.dev/k8s/rbac/v1"
	target: ["scope"]
	schema:      #RoleBindingSpec
	description: "Kubernetes RoleBinding - binds role to subjects"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "rbac"
	}
}

#RoleBinding: close(opm.#Component & {
	#elements: (#RoleBindingElement.#fullyQualifiedName): #RoleBindingElement

	roleBindings: [string]: #RoleBindingSpec
})

#ClusterRoleElement: opm.#Primitive & {
	name:        "ClusterRole"
	#apiVersion: "elements.opm.dev/k8s/rbac/v1"
	target: ["scope"]
	schema:      #ClusterRoleSpec
	description: "Kubernetes ClusterRole - cluster-scoped permissions"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "rbac"
	}
}

#ClusterRole: close(opm.#Component & {
	#elements: (#ClusterRoleElement.#fullyQualifiedName): #ClusterRoleElement

	clusterRoles: [string]: #ClusterRoleSpec
})

#ClusterRoleBindingElement: opm.#Primitive & {
	name:        "ClusterRoleBinding"
	#apiVersion: "elements.opm.dev/k8s/rbac/v1"
	target: ["scope"]
	schema:      #ClusterRoleBindingSpec
	description: "Kubernetes ClusterRoleBinding - binds cluster role to subjects"
	labels: {
		"core.opm.dev/category": "kubernetes"
		"k8s.io/api-group":      "rbac"
	}
}

#ClusterRoleBinding: close(opm.#Component & {
	#elements: (#ClusterRoleBindingElement.#fullyQualifiedName): #ClusterRoleBindingElement

	clusterRoleBindings: [string]: #ClusterRoleBindingSpec
})
