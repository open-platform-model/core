// OPM Examples Runner
// CUE CMD tool for working with examples
package examples

import (
	"tool/exec"
	"tool/cli"
)

command: list: {
	$short: "List all available examples"
	$usage: "cue cmd list"

	examples: cli.Print & {
		text: """
			Available examples:

			Module Definitions (templates - incomplete by design):
			  - myAppDefinition
			  - ecommerceAppDefinition
			  - monitoringStackDefinition

			Module Instances (can export values/metadata):
			  - myApp
			  - ecommerceApp
			  - monitoringStack

			Provider Examples:
			  - #KubernetesProvider

			Usage:
			  cue cmd show -t name=myApp          # Show structure (with incomplete values)
			  cue cmd values -t name=myApp        # Export concrete values
			  cue cmd metadata -t name=myApp      # Export metadata

			Note: Full module export not possible due to embedded incomplete
			      ModuleDefinition (definitions are templates).
			"""
	}
}

command: show: {
	$short: "Show an example structure (includes incomplete values)"
	$usage: "cue cmd show -t name=myApp"

	name: string @tag(name)

	eval: exec.Run & {
		cmd:    "cue eval . -e \(name)"
		stdout: string
	}

	print: cli.Print & {
		$after: eval
		text:   eval.stdout
	}
}

command: validate: {
	$short: "Validate all examples"
	$usage: "cue cmd validate"

	run: exec.Run & {
		cmd:    "cue vet -c=false ."
		stdout: string
		stderr: string
	}

	report: cli.Print & {
		$after: run
		text:   "✓ All examples are valid"
	}
}

command: values: {
	$short: "Export values from a module"
	$usage: "cue cmd values -t name=myApp"

	name: string @tag(name)

	run: exec.Run & {
		cmd:    "cue export . -e \(name).values --out yaml"
		stdout: string
	}

	print: cli.Print & {
		$after: run
		text:   run.stdout
	}
}

command: metadata: {
	$short: "Export metadata from a module"
	$usage: "cue cmd metadata -t name=myApp"

	name: string @tag(name)

	run: exec.Run & {
		cmd:    "cue export . -e \(name).#metadata --out yaml"
		stdout: string
	}

	print: cli.Print & {
		$after: run
		text:   run.stdout
	}
}

command: status: {
	$short: "Show module status information"
	$usage: "cue cmd status -t name=myApp"

	name: string @tag(name)

	run: exec.Run & {
		cmd:    "cue export . -e \(name).#status --out yaml"
		stdout: string
	}

	print: cli.Print & {
		$after: run
		text:   run.stdout
	}
}

command: "show:all": {
	$short: "Show summary of all modules"
	$usage: "cue cmd show:all"

	myAppValues: exec.Run & {
		cmd:    "cue export . -e myApp.values --out yaml"
		stdout: string
	}

	ecommerceValues: exec.Run & {
		cmd:    "cue export . -e ecommerceApp.values --out yaml"
		stdout: string
	}

	monitoringValues: exec.Run & {
		cmd:    "cue export . -e monitoringStack.values --out yaml"
		stdout: string
	}

	print: cli.Print & {
		$after: monitoringValues
		text:   """
			=== myApp values ===
			\(myAppValues.stdout)

			=== ecommerceApp values ===
			\(ecommerceValues.stdout)

			=== monitoringStack values ===
			\(monitoringValues.stdout)
			"""
	}
}
