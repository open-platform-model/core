// Developer Flow Tool
// CUE CMD tool for developers to test ModuleDefinitions locally
package developer

import (
	"encoding/yaml"
	"tool/cli"
)

// Available example modules
_exampleModules: {
	"blog-app": blogAppLocal
	"supabase": supabaseLocal
}

// Command: cue cmd list
command: list: {
	print: cli.Print & {
		text: """
			Developer Flow - Local Testing Modules:

			Available modules:
			  - blog-app: Simple blog application with frontend and database
			  - supabase: Complete Supabase stack with database, API gateway, auth, storage, and functions

			Usage:
			  cue cmd test -t module=<name>     # Test module definition and show output
			  cue cmd validate -t module=<name> # Validate module structure
			  cue cmd render -t module=<name>   # Render module output
			  cue cmd show -t module=<name>     # Show rendered output
			"""
	}
}

// Command: cue cmd test -t module=blog-app
command: test: {
	module: string @tag(module)

	_module: _exampleModules[module]
	_output: _module.output

	print: cli.Print & {
		text: """
			🧪 Testing module: \(module)

			Module: \(_module.#metadata.name)
			Namespace: \(_module.#metadata.namespace)
			Components: \(len(_module.moduleDefinition.components))

			Output Structure:
			\(yaml.Marshal(_output))

			✅ Module structure is valid!

			Note: To deploy this module to a platform, the platform team would:
			1. Review the ModuleDefinition
			2. Add it to their catalog with appropriate transformers
			3. End-users would then deploy via the catalog
			"""
	}
}

// Command: cue cmd validate -t module=blog-app
command: validate: {
	module: string @tag(module)

	_module: _exampleModules[module]
	_def:    _module.#moduleDefinition

	print: cli.Print & {
		text: """
			✅ Validating module definition: \(module)

			Definition Details:
			  Name: \(_def.#metadata.name)
			  Version: \(_def.#metadata.version)
			  Components: \(len(_def.components))

			Components:
			\(yaml.Marshal({
			for id, comp in _def.components {
				"\(id)": {
					workloadType: comp.#metadata.labels["core.opm.dev/workload-type"]
					primitives:   comp.#primitiveElements
				}
			}
		}))

			✅ Module definition is valid!
			"""
	}
}

// Command: cue cmd render -t module=blog-app -t outdir=./output
command: render: {
	// Input parameters
	module:  string @tag(module)
	outdir:  string @tag(outdir,outdir="./output")
	verbose: bool   @tag(verbose,verbose=false)

	// Get the module
	_module: _exampleModules[module]
	_output: _module.output

	// Start message
	start: cli.Print & {
		text: "🚀 Rendering module '\(module)'..."
	}

	// Final summary
	summary: cli.Print & {
		$after: start
		text: """

			✅ Rendering complete!
			Module: \(module)

			Use 'cue cmd show -t module=\(module)' to view the output.
			"""
	}
}

// Command: cue cmd show -t module=blog-app
command: show: {
	module: string @tag(module)

	_module: _exampleModules[module]
	_output: _module.output

	print: cli.Print & {
		text: yaml.Marshal(_output)
	}
}
