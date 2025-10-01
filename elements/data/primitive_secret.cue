package data

import (
	core "github.com/open-platform-model/core"
	schema "github.com/open-platform-model/core/schema"
)

// Secrets as Resources
#SecretElement: core.#Primitive & {
	name:        "Secret"
	#apiVersion: "elements.opm.dev/core/v1alpha1"
	description: "Sensitive data such as passwords, tokens, or keys"
	target: ["component"]
	labels: {"core.opm.dev/category": "data"}
	schema: #SecretSpec
}

#Secret: close(core.#ElementBase & {
	#elements: (#SecretElement.#fullyQualifiedName): #SecretElement

	secrets: [string]: #SecretSpec
})

// Re-export schema types for convenience
#SecretSpec: schema.#SecretSpec
