package core

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Secret Schema
/////////////////////////////////////////////////////////////////

// Secret specification
#SecretSpec: {
	type?: string | *"Opaque"
	data: [string]: string // Base64-encoded values
}

/////////////////////////////////////////////////////////////////
//// Secret Element
/////////////////////////////////////////////////////////////////

// Secrets as Resources
#SecretElement: opm.#Primitive & {
	name:        "Secret"
	#apiVersion: "elements.opm.dev/core/v0"
	description: "Sensitive data such as passwords, tokens, or keys"
	target: ["component"]
	labels: {"core.opm.dev/category": "data"}
	schema: #SecretSpec
}

#Secret: close(opm.#Component & {
	#elements: (#SecretElement.#fullyQualifiedName): #SecretElement

	secrets: [string]: #SecretSpec
})
