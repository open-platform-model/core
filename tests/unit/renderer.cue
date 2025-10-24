// Renderer Tests
// Tests for renderer functionality
package unit

import (
	opm "github.com/open-platform-model/core"
)

rendererTests: {
	//////////////////////////////////////////////////////////////////
	// Kubernetes List Renderer Tests
	//////////////////////////////////////////////////////////////////

	// Test: KubernetesListRenderer with fixture data
	"renderer/kubernetes-list-basic": {
		_renderer: opm.#KubernetesListRenderer

		// Test data: simple list of Kubernetes resources
		_resources: [{
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      "test-app"
				namespace: "default"
			}
			spec: {
				replicas: 3
			}
		}, {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "test-service"
				namespace: "default"
			}
			spec: {
				ports: [{
					port:       80
					targetPort: 8080
				}]
			}
		}]

		// Apply renderer
		_rendered: (_renderer.render & {
			resources: _resources
		}).output

		// Validate output structure
		_manifestExists: _rendered.manifest != _|_
		_manifestExists: true

		// Validate manifest is a Kubernetes List
		_rendered: manifest: {
			apiVersion: "v1"
			kind:       "List"
			items:      _resources
		}

		// Validate metadata
		_rendered: metadata: format: "yaml"
	}

	// Test: Empty resources list
	"renderer/kubernetes-list-empty": {
		_renderer: opm.#KubernetesListRenderer

		_rendered: (_renderer.render & {
			resources: []
		}).output

		// Should produce empty list
		_rendered: manifest: {
			apiVersion: "v1"
			kind:       "List"
			items: []
		}
	}

	// Test: Single resource
	"renderer/kubernetes-list-single": {
		_renderer: opm.#KubernetesListRenderer

		_resource: {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name: "test-config"
			}
			data: {
				key: "value"
			}
		}

		_rendered: (_renderer.render & {
			resources: [_resource]
		}).output

		// Validate single item in list
		_rendered: manifest: {
			apiVersion: "v1"
			kind:       "List"
			items: [_resource]
		}
	}
}
