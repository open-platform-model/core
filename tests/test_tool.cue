// OPM Test Runner
// CUE CMD tool for running tests
package tests

import (
	"tool/exec"
	"tool/cli"
)

command: test: {
	$short: "Run all tests (unit + integration)"
	$usage: "cue cmd test"

	unit: exec.Run & {
		cmd:    "cue vet ./unit/..."
		stdout: string
		stderr: string
	}

	integration: exec.Run & {
		$after: unit
		cmd:    "cue vet ./integration/..."
		stdout: string
		stderr: string
	}

	report: cli.Print & {
		$after: integration
		text: """
			✓ Unit tests passed
			✓ Integration tests passed

			All tests completed successfully
			"""
	}
}

command: "test:unit": {
	$short: "Run unit tests only"

	run: exec.Run & {
		cmd:    "cue vet -c ./unit/..."
		stdout: string
	}

	report: cli.Print & {
		$after: run
		text:   "✓ Unit tests passed"
	}
}

command: "test:integration": {
	$short: "Run integration tests only"

	run: exec.Run & {
		cmd:    "cue vet -c ./integration/..."
		stdout: string
	}

	report: cli.Print & {
		$after: run
		text:   "✓ Integration tests passed"
	}
}

command: "test:file": {
	$short: "Test specific file"
	$usage: "cue cmd test:file -t path=tests/unit/component.cue"

	path: string @tag(path)

	run: exec.Run & {
		cmd:    "cue vet \(path)"
		stdout: string
	}

	report: cli.Print & {
		$after: run
		text:   "✓ \(path) passed"
	}
}

command: "test:export": {
	$short: "Export test results as JSON"

	export: exec.Run & {
		cmd:    "cue export ./... --out json"
		stdout: string
	}

	print: cli.Print & {
		$after: export
		text:   export.stdout
	}
}
