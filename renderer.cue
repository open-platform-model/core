package core

/////////////////////////////////////////////////////////////////
//// Renderer Definition
/////////////////////////////////////////////////////////////////

// Renderer output structure
#RendererOutput: {
	// For simple single-file outputs (like Kubernetes List)
	// Can be a structured object or marshaled string
	manifest?: _

	// For multi-file outputs (like Kustomize, Helm)
	// Map of filename to content (can be struct or string)
	files?: [string]: _

	// Metadata about the rendering
	metadata?: {
		format:      string // "yaml", "json", "toml", etc.
		entrypoint?: string // main file for multi-file outputs
	}
}

#Renderer: {
	#kind:       "Renderer"
	#apiVersion: "core.opm.dev/v0"
	#metadata: {
		name:        string
		description: string
		version:     string

		// Labels for renderer categorization and compatibility
		// Example: {"core.opm.dev/input-format": "kubernetes"}
		labels?: #LabelsAnnotationsType
	}

	targetPlatform: string

	// Render function - takes resources as input and produces output
	// Function-style pattern similar to #Transformer
	render: {
		// Input: list of transformed resources from transformers
		resources: _

		// Output: rendered manifest(s)
		output: #RendererOutput
	}
}

#RendererMap: [string]: #Renderer

/////////////////////////////////////////////////////////////////
//// Generic Renderers
/////////////////////////////////////////////////////////////////

// Kubernetes List Renderer
#KubernetesListRenderer: #Renderer & {
	#metadata: {
		name:        "kubernetes-list"
		description: "Renders to Kubernetes List format"
		version:     "1.0.0"
		labels: {
			"core.opm.dev/input-format": "kubernetes"
		}
	}
	targetPlatform: "kubernetes"

	// Render function - resources will be provided by Module
	render: {
		// Input: list of Kubernetes resources
		resources: _

		// Output: single manifest in Kubernetes List format
		output: {
			// For now, return raw structure - will add YAML marshaling later
			manifest: {
				apiVersion: "v1"
				kind:       "List"
				items:      resources
			}
			metadata: {
				format: "yaml"
			}
		}
	}
}

// // Kubernetes Kustomize Renderer
// #KubernetesKustomizeRenderer: #Renderer & {
// 	#metadata: {
// 		name:        "kubernetes-kustomize"
// 		description: "Renders to Kustomize-compatible YAML files"
// 		version:     "1.0.0"
// 	}
// 	targetPlatform: "kubernetes"

// 	// Render template - resources will be provided by Module
// 	render: {
// 		resources?: [...] | *[]

// 		_deployments: [
// 			if resources != _|_ for r in resources if r.kind == "Deployment" {r},
// 		]
// 		_services: [
// 			if resources != _|_ for r in resources if r.kind == "Service" {r},
// 		]
// 		_configmaps: [
// 			if resources != _|_ for r in resources if r.kind == "ConfigMap" {r},
// 		]
// 		_pvcs: [
// 			if resources != _|_ for r in resources if r.kind == "PersistentVolumeClaim" {r},
// 		]

// 		_resourceFiles: [
// 			if len(_deployments) > 0 {"deployments.yaml"},
// 			if len(_services) > 0 {"services.yaml"},
// 			if len(_configmaps) > 0 {"configmaps.yaml"},
// 			if len(_pvcs) > 0 {"pvcs.yaml"},
// 		]

// 		output: {
// 			files: {
// 				"kustomization.yaml": {
// 					data: {
// 						apiVersion: "kustomize.config.k8s.io/v1beta1"
// 						kind:       "Kustomization"
// 						resources:  _resourceFiles
// 					}
// 					format: "yaml"
// 				}

// 				if len(_deployments) > 0 {
// 					"deployments.yaml": {
// 						data:   _deployments
// 						format: "yaml"
// 					}
// 				}

// 				if len(_services) > 0 {
// 					"services.yaml": {
// 						data:   _services
// 						format: "yaml"
// 					}
// 				}

// 				if len(_configmaps) > 0 {
// 					"configmaps.yaml": {
// 						data:   _configmaps
// 						format: "yaml"
// 					}
// 				}

// 				if len(_pvcs) > 0 {
// 					"pvcs.yaml": {
// 						data:   _pvcs
// 						format: "yaml"
// 					}
// 				}
// 			}
// 		}
// 	}
// }

// // Docker Compose Renderer
// #DockerComposeRenderer: #Renderer & {
// 	#metadata: {
// 		name:        "docker-compose"
// 		description: "Renders to Docker Compose format"
// 		version:     "1.0.0"
// 	}
// 	targetPlatform: "docker-compose"

// 	// Render template - resources will be provided by Module
// 	render: {
// 		resources?: [...] | *[]
// 		output: {
// 			raw: {
// 				version: "3.8"
// 				services: {
// 					for r in resources if r.kind == "Container" {
// 						(r.metadata.name): {
// 							image: r.spec.image
// 							if r.spec.ports != _|_ {
// 								ports: [for p in r.spec.ports {"\(p.containerPort):\(p.hostPort)"}]
// 							}
// 						}
// 					}
// 				}
// 			}
// 		}
// 	}
// }
