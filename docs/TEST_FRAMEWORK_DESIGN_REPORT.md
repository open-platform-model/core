# OPM Test Framework Design

## Overview

This document outlines four potential approaches for building a comprehensive test framework for the Open Platform Model (OPM). The goal is to enable fast, continuous testing during development with support for both unit and integration tests across all OPM components (elements, modules, registry, catalog, providers, transformers).

## Requirements

- **Fast execution**: Tests must run quickly for tight feedback loops
- **Continuous testing**: Watch mode for automatic test execution on file changes
- **Granular control**: Ability to run individual tests (unit) and combined tests (integration)
- **Comprehensive coverage**: All elements, modules, registry, catalog, provider, and transformer logic
- **Developer-friendly**: Easy to write and maintain tests

---

## Inspiration & Prior Art

This test framework design draws inspiration from several proven testing approaches and tools:

### CUE Language Testing

**CUE's Core Validation Philosophy** ([How CUE Enables Configuration](https://cuelang.org/docs/concept/how-cue-enables-configuration/))

- **Types are values**: Enables expressive typing and fine-grained constraints
- **Order-independent unification**: Constraints can be combined from multiple sources
- **Declarative validation**: Data validation rules specified as constraints, not procedures
- **Incremental validation**: Can validate existing configuration files progressively
- **Constraint modeling**: Supports required fields, value ranges, structural requirements, and interdependent validations

Key validation pattern:
```cue
#Spec: {
  // Required string. Must not contain "-".
  name!: string & !~"-"
  // Required. One of three options.
  kind!: "app" | "VM" | "service"
}
```

**CUE's Internal Testing** ([`cuelang.org/go/internal/cuetest`](https://pkg.go.dev/cuelang.org/go/internal/cuetest))

- CUE project uses testscript and txtar format for testing the language itself
- Provides utilities like `UpdateGoldenFiles` for golden file testing
- Demonstrates table-driven tests with CUE's type system

**Creating Test Reproducers** ([CUE Wiki Guide](https://github.com/cue-lang/cue/wiki/Creating-test-or-performance-reproducers))

- **Txtar archives**: Text-based hermetic test format using `txtar-c` and `txtar-x` tools
- **Testscript integration**: `cmd/testscript` for running and validating reproducers
- **Best practices**: Provide precise, minimal examples with version information
- **Archive structure**: Files delineated by `-- filename --` blocks with optional command instructions

Example txtar reproducer:
```
exec cue def

-- cue.mod/module.cue --
module: "mod.com"
-- x.cue --
package x

a: 41
a: 42
```

**Programmatic Validation with Go API** ([Validate JSON Using Go API](https://cuelang.org/docs/howto/validate-json-using-go-api))

- **CUE Context**: `cuecontext.New()` for creating validation environments
- **Schema compilation**: `ctx.CompileString()` for embedding schemas
- **Unification & validation**: `schema.Unify(data).Validate()` for type-safe checking
- **Error handling**: Detailed error messages with type mismatch information
- **Test integration**: Prepare "good" and "bad" test files for acceptance/rejection testing

Key validation workflow:
```go
ctx := cuecontext.New()
schema := ctx.CompileString(cueSource).LookupPath(cue.ParsePath("#Schema"))
dataAsCUE := ctx.BuildExpr(dataExpr)
unified := schema.Unify(dataAsCUE)
if err := unified.Validate(); err != nil {
    log.Fatal(err) // Detailed type error
}
```

**Community Testing Libraries**

- [`KurtRudolph/cuelang-testing`](https://github.com/KurtRudolph/cuelang-testing) - Community assertion package for CUE
- Demonstrates declarative assertion patterns in CUE

### Testscript & Txtar Format

**Testscript** ([`github.com/rogpeppe/go-internal/testscript`](https://pkg.go.dev/github.com/rogpeppe/go-internal/testscript))

- Originally created for testing the Go compiler
- Filesystem-based testing with declarative scripts
- Txtar archive format for test data and golden files
- Key articles:
  - [All about testscript – a powerful Go package for testing](https://encore.dev/blog/testscript-hidden-testing-gem)
  - [testscript: a DSL for testing CLI tools in Go](https://bitfieldconsulting.com/posts/cli-testing)
  - [The txtar format: input data and golden files for Go tests](https://bitfieldconsulting.com/posts/test-scripts-files)

**Txtar Format Benefits**:

- Trivial to create and edit by hand
- Stores trees of text files in a single archive
- Diffs nicely in git history and code reviews
- Perfect for test fixtures and golden files

### Dagger Testing Patterns

**Dagger Module Testing** ([Dagger Docs](https://docs.dagger.io/api/module-tests/))

- Best practice: Keep tests close to module code
- Test modules as Dagger modules themselves
- Functions serve as both verification and reference documentation
- Key resources:
  - [Testing with Dagger](https://dagger.dev/dev-guide/testing.html)
  - [Build a CI Workflow](https://docs.dagger.io/quickstart/ci/)
  - [Testing and Releasing Helm Charts with Dagger](https://labs.iximiuz.com/tutorials/testing-and-releasing-helm-charts-with-dagger-4dcb152e)

**Dagger Best Practices**:

- Test locally before pushing to CI/CD ("no more push and pray")
- Use separate test modules or combined example/test modules
- Leverage content-addressed caching for instant re-runs
- Functions as executable tests and documentation

### Go Testing Ecosystem

**Standard Library** ([`testing` package](https://pkg.go.dev/testing))

- Table-driven tests pattern
- Subtests and parallel execution
- Benchmarking and coverage analysis

**Third-Party Libraries**:

- [`testify/assert`](https://github.com/stretchr/testify) - Rich assertion library
- [`gotestsum`](https://github.com/gotestyourself/gotestsum) - Enhanced test output and watch mode
- [`ginkgo`](https://github.com/onsi/ginkgo) - BDD-style testing framework

### Configuration Testing Approaches

**Kubernetes Testing**:

- KRM (Kubernetes Resource Model) validation
- Policy enforcement with OPA/Gatekeeper
- Schema validation with OpenAPI

**Terraform Testing**:

- `terraform plan` as test validation
- Terratest for integration testing
- Sentinel for policy testing

**Helm Chart Testing**:

- [`helm test`](https://helm.sh/docs/helm/helm_test/) for chart validation
- [`chart-testing`](https://github.com/helm/chart-testing) for linting and testing
- Template rendering tests with golden files

### Hybrid Approaches

This design synthesizes these approaches into a hybrid system that:

1. Uses **CUE's type system** for declarative test definitions (inspired by CUE's own testing)
2. Leverages **Dagger's Go SDK** for orchestration and caching (following Dagger best practices)
3. Adopts **testscript/txtar patterns** for test data and golden files (proven in Go ecosystem)
4. Provides **rich reporting** like Go's testing ecosystem (testify, gotestsum)
5. Enables **continuous testing** like modern development tools (watch mode, fast feedback)

### Key Insights Applied

1. **Declarative over Imperative**: Tests defined as data (CUE) rather than procedures
2. **Tests as Documentation**: Executable examples that serve as reference material
3. **Fast Feedback Loops**: Content-addressed caching and incremental execution
4. **Reproducibility**: Container-based execution ensures consistency
5. **Developer Experience**: Watch mode, rich output, and familiar patterns

### Further Reading

- [CUE Language Documentation](https://cuelang.org/docs/)
- [Dagger Documentation](https://docs.dagger.io/)
- [Go Testing Guide](https://blog.jetbrains.com/go/2022/11/22/comprehensive-guide-to-testing-in-go/)
- [Intro to testscript usage in Go](https://datacharmer.github.io/testscript-intro/)
- [How Go Tests "go test"](https://atlasgo.io/blog/2024/09/09/how-go-tests-go-test)

---

## Option 1: Pure CUE cmd-based Test Framework ⭐

### Philosophy

Use only CUE's type system, constraints, and `cue cmd` for testing. Fast, native, no external dependencies.

### Architecture

```
tests/
├── unit/
│   ├── elements_test.cue          # Element schema validation
│   ├── components_test.cue        # Component composition tests
│   ├── transformers_test.cue      # Transformer logic tests
│   └── registry_test.cue          # Registry completeness tests
├── integration/
│   ├── module_build_test.cue      # Full module builds
│   └── provider_render_test.cue   # End-to-end provider rendering
├── fixtures/
│   └── test_data.cue              # Shared test data
└── test_tool.cue                  # Test runner using cue cmd
```

### Implementation

**Test Definition**: CUE files with `#Test` definitions containing `input`, `expected`, and `assertion` fields

```cue
package tests

#Test: {
    name!: string
    input: _
    expected: _
    // If input unifies with expected, test passes
    _result: input & expected
}

// Unit test example
testContainerElement: #Test & {
    name: "Container element validates correctly"
    input: {
        name: "Container"
        kind: "primitive"
        target: ["component"]
        schema: {image: string}
    }
    expected: core.#Element
}
```

**Test Runner**: `test_tool.cue` with commands for unit/integration/all tests

```cue
package tests

import (
    "tool/exec"
    "tool/cli"
    "tool/file"
)

command: test: {
    $short: "Run all tests"

    unit: exec.Run & {
        cmd: "cue export ./tests/unit/... --out json"
        stdout: string
    }

    integration: exec.Run & {
        $after: unit
        cmd: "cue export ./tests/integration/... --out json"
        stdout: string
    }

    report: cli.Print & {
        $after: integration
        text: "All tests passed"
    }
}

command: watch: {
    $short: "Watch and run tests on changes"

    // Use tool/file to monitor changes and trigger tests
    monitor: file.Watch & {
        pattern: "**/*.cue"
        onChange: exec.Run & {
            cmd: "cue cmd test"
        }
    }
}
```

**Assertions**: Use CUE unification to verify `input` matches `expected`

**Watch Mode**: `cue cmd watch` using `tool/file` to monitor changes

**Output**: Structured JSON/YAML reports, TAP format for CI integration

### Pros

- Zero dependencies, pure CUE
- Type-safe test definitions
- Fast parallel execution
- Native watch mode via `cue cmd`
- Same language for tests and implementation

### Cons

- Limited test reporting capabilities
- No mocking/stubbing built-in
- Steeper learning curve for non-CUE developers

### Performance

| Operation | Time |
|-----------|------|
| Unit tests | ~100-500ms |
| Integration tests | ~500ms-2s |
| Watch mode latency | <200ms |

---

## Option 2: Go + CUE API Test Framework

### Philosophy

Leverage CUE's Go API for programmatic testing with Go's native testing tools.

### Architecture

```
tests/
├── unit/
│   ├── element_test.go
│   ├── component_test.go
│   └── testdata/
│       └── *.cue
├── integration/
│   └── module_test.go
└── helpers/
    └── cue_helpers.go             # CUE API wrappers
```

### Implementation

**Test Framework**: Go's `testing` package + `testify/assert`

**CUE Integration**: `cuelang.org/go/cue` API for loading/validating ([See: Validate JSON Using Go API](https://cuelang.org/docs/howto/validate-json-using-go-api))

Core validation pattern:
- Create CUE context with `cuecontext.New()`
- Compile schemas using `ctx.CompileString()` or load from files
- Use `schema.Unify(data)` to combine schema and data
- Validate with `.Validate()` for detailed error messages

```go
// tests/unit/element_test.go
package tests

import (
    "testing"
    "cuelang.org/go/cue"
    "cuelang.org/go/cue/cuecontext"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestContainerElement(t *testing.T) {
    ctx := cuecontext.New()
    val := ctx.CompileString(`
        import core "github.com/open-platform-model/core"

        #ContainerElement: core.#Element & {
            name: "Container"
            kind: "primitive"
        }
    `)

    require.NoError(t, val.Err())

    kind, _ := val.LookupPath(cue.ParsePath("#ContainerElement.kind")).String()
    assert.Equal(t, "primitive", kind)
}

func TestElementRegistry(t *testing.T) {
    tests := []struct{
        name string
        element string
        expectedKind string
    }{
        {"Container", "Container", "primitive"},
        {"StatelessWorkload", "StatelessWorkload", "composite"},
        {"Replicas", "Replicas", "modifier"},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            ctx := cuecontext.New()
            // Load and validate element
            // ... CUE API calls
            assert.Equal(t, tt.expectedKind, kind)
        })
    }
}
```

**Test Data**: CUE files in `testdata/` loaded via `cue.Load()`

**Watch Mode**: `gotestsum --watch` or `ginkgo watch`

```bash
# Watch mode with gotestsum
gotestsum --watch --format testname

# Watch mode with ginkgo
ginkgo watch -r ./tests
```

**Coverage**: Go coverage tools + custom CUE schema coverage

```bash
go test ./tests/... -coverprofile=coverage.out
go tool cover -html=coverage.out
```

### Pros

- Mature testing ecosystem (table tests, benchmarks, coverage)
- Fast execution with `go test -parallel`
- Excellent IDE support
- Can test CUE API integration
- Great CI/CD support

### Cons

- Requires Go knowledge
- Additional language dependency
- More boilerplate than pure CUE

### Performance

| Operation | Time |
|-----------|------|
| Unit tests | ~200-800ms |
| Integration tests | ~1-3s |
| Parallel tests | ~100-500ms |
| Watch mode latency | ~200ms |

---

## Option 3: Custom Test DSL + CUE Validator

### Philosophy

Create a minimal test DSL in CUE, with a lightweight test runner (Python/Node) for execution and reporting.

### Architecture

```
tests/
├── schema/
│   └── test_schema.cue            # Test DSL definition
├── unit/
│   ├── elements.test.cue
│   ├── components.test.cue
│   └── transformers.test.cue
├── integration/
│   └── modules.test.cue
└── runner/
    ├── test_runner.py             # Test executor
    └── reporters/
        ├── console.py
        └── junit.py
```

### Implementation

**Test DSL**: CUE schema defining `#TestSuite`, `#Test`, `#Assertion`

```cue
// tests/schema/test_schema.cue
package testschema

#TestSuite: {
    name!: string
    tests: [...#Test]
}

#Test: {
    name!: string
    subject: _
    assertions: [...#Assertion]
}

#Assertion: {
    type!: "equals" | "validates" | "unifies" | "contains"
    path?: string
    value?: _
    schema?: _
}
```

**Test Example**:

```cue
package tests

import "github.com/open-platform-model/core/tests/schema"

testSuite: schema.#TestSuite & {
    name: "Element Tests"

    tests: [
        {
            name: "Container is primitive"
            subject: core.#ContainerElement
            assertions: [
                {type: "equals", path: "kind", value: "primitive"},
                {type: "validates", schema: core.#Element},
            ]
        },
        {
            name: "StatelessWorkload is composite"
            subject: core.#StatelessWorkloadElement
            assertions: [
                {type: "equals", path: "kind", value: "composite"},
                {type: "contains", path: "required", value: "Container"},
            ]
        },
    ]
}
```

**Test Discovery**: Runner scans `*.test.cue` files

**Execution**: Runner invokes `cue export` and evaluates assertions

```python
# tests/runner/test_runner.py
import subprocess
import json
from pathlib import Path

class TestRunner:
    def discover_tests(self, path: Path):
        """Find all *.test.cue files"""
        return list(path.glob("**/*.test.cue"))

    def run_test_file(self, file: Path):
        """Execute a test file using CUE"""
        result = subprocess.run(
            ["cue", "export", str(file), "--out", "json"],
            capture_output=True,
            text=True
        )
        return json.loads(result.stdout)

    def evaluate_assertions(self, test_data):
        """Evaluate test assertions"""
        for test in test_data.get("tests", []):
            for assertion in test.get("assertions", []):
                if assertion["type"] == "equals":
                    # Check equality
                    pass
                elif assertion["type"] == "validates":
                    # Run cue vet
                    pass
                # ... other assertion types
```

**Assertions**: `equals`, `validates`, `unifies`, `contains`, etc.

**Watch Mode**: Watchdog (Python) or Chokidar (Node)

```python
# Watch mode with Python watchdog
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class TestWatcher(FileSystemEventHandler):
    def on_modified(self, event):
        if event.src_path.endswith('.cue'):
            runner.run_all_tests()

observer = Observer()
observer.schedule(TestWatcher(), path="./tests", recursive=True)
observer.start()
```

**Reporting**: Console, JUnit XML, JSON, TAP

### Pros

- Declarative, readable tests
- Flexible reporting
- Language-agnostic runner
- Can extend DSL easily
- Good balance of CUE + tooling

### Cons

- Custom tooling maintenance
- Additional runtime dependency (Python/Node)
- Potential performance overhead

### Performance

| Operation | Time |
|-----------|------|
| Unit tests | ~500ms-1s |
| Integration tests | ~2-4s |
| Watch mode latency | ~300-500ms |

---

## Option 4: Pure CUE Tests + Dagger Go Orchestration ⭐⭐

### Philosophy

Define tests declaratively in pure CUE (leveraging type safety and constraints), orchestrate execution with Dagger's Go SDK (caching, parallelization, containers). Best of both worlds.

**Key Advantage**: Combines CUE's type safety with Dagger's production-grade orchestration, caching, and parallelization. Since Dagger's CUE SDK is end-of-life, this uses the actively maintained Go SDK.

### Architecture

```
tests/
├── definitions/                    # Pure CUE test definitions
│   ├── unit/
│   │   ├── elements_test.cue      # Element validation tests
│   │   ├── components_test.cue    # Component composition tests
│   │   ├── transformers_test.cue  # Transformer logic tests
│   │   └── registry_test.cue      # Registry completeness tests
│   ├── integration/
│   │   ├── module_build_test.cue  # Full module builds
│   │   └── provider_test.cue      # Provider rendering tests
│   └── schema/
│       └── test_schema.cue        # Test framework schema
├── dagger/                         # Dagger orchestration
│   ├── main.go                    # Dagger module entry point
│   ├── tests.go                   # Test execution functions
│   ├── watch.go                   # Watch mode implementation
│   └── reporters.go               # Test reporting
└── fixtures/
    └── test_data.cue              # Shared test fixtures
```

### Implementation Details

#### 1. Pure CUE Test Definitions

Tests are defined purely in CUE with a clean, declarative schema:

```cue
// tests/definitions/schema/test_schema.cue
package testschema

#Test: {
    name!: string
    description?: string

    // Test input - what we're testing
    subject: _

    // Assertions to verify
    assertions: [...#Assertion]

    // Optional setup/teardown
    setup?: _
    teardown?: _
}

#Assertion: {
    type!: "unifies" | "equals" | "validates" | "contains" | "exports"

    // For path-based assertions
    path?: string

    // Expected value or schema
    expected?: _

    // For validation assertions
    schema?: _
}

#TestSuite: {
    name!: string
    tests: [...#Test]

    // Suite-level setup/teardown
    setup?: _
    teardown?: _
}
```

**Example test definition**:

```cue
// tests/definitions/unit/elements_test.cue
package tests

import (
    core "github.com/open-platform-model/core"
    schema "github.com/open-platform-model/core/tests/schema"
)

elementTests: schema.#TestSuite & {
    name: "Core Element Tests"

    tests: [
        {
            name: "Container element is valid primitive"
            subject: core.#ContainerElement
            assertions: [
                {
                    type: "validates"
                    schema: core.#Element
                },
                {
                    type: "equals"
                    path: "kind"
                    expected: "primitive"
                },
                {
                    type: "equals"
                    path: "#apiVersion"
                    expected: "core.opm.dev/v1alpha1"
                },
            ]
        },
        {
            name: "StatelessWorkload unifies correctly"
            subject: {
                core.#StatelessWorkload
                stateless: container: {
                    image: "nginx:latest"
                    ports: http: targetPort: 80
                }
            }
            assertions: [
                {
                    type: "unifies"
                    expected: core.#Component
                },
                {
                    type: "exports"
                    expected: {
                        stateless: container: image: "nginx:latest"
                    }
                },
            ]
        },
    ]
}
```

**Transformer tests**:

```cue
// tests/definitions/unit/transformers_test.cue
package tests

import (
    core "github.com/open-platform-model/core"
    k8s "github.com/open-platform-model/core/providers/kubernetes"
    schema "github.com/open-platform-model/core/tests/schema"
)

transformerTests: schema.#TestSuite & {
    name: "Kubernetes Transformer Tests"

    tests: [
        {
            name: "StatelessWorkload transforms to Deployment"
            subject: {
                let component = {
                    core.#StatelessWorkload
                    stateless: container: {
                        image: "nginx:latest"
                        ports: http: targetPort: 80
                    }
                }

                k8s.#StatelessTransformer.transform & {
                    _component: component
                    name: "test-app"
                    namespace: "default"
                }
            }
            assertions: [
                {
                    type: "equals"
                    path: "kind"
                    expected: "Deployment"
                },
                {
                    type: "equals"
                    path: "spec.template.spec.containers[0].image"
                    expected: "nginx:latest"
                },
                {
                    type: "validates"
                    schema: k8s.#Deployment
                },
            ]
        },
    ]
}
```

**Registry tests**:

```cue
// tests/definitions/unit/registry_test.cue
package tests

import (
    elements "github.com/open-platform-model/core/elements"
    schema "github.com/open-platform-model/core/tests/schema"
)

registryTests: schema.#TestSuite & {
    name: "Element Registry Tests"

    tests: [
        {
            name: "All core elements are registered"
            subject: elements.#CoreElementRegistry
            assertions: [
                {
                    type: "contains"
                    path: "."
                    expected: "core.opm.dev/v1alpha1.Container"
                },
                {
                    type: "contains"
                    path: "."
                    expected: "core.opm.dev/v1alpha1.StatelessWorkload"
                },
                {
                    type: "contains"
                    path: "."
                    expected: "core.opm.dev/v1alpha1.Replicas"
                },
            ]
        },
        {
            name: "Registry has no duplicates"
            subject: elements.#CoreElementRegistry
            assertions: [
                {
                    type: "validates"
                    schema: {
                        // Ensure all keys are unique FQNs
                        [string]: kind: "primitive" | "composite" | "modifier" | "custom"
                    }
                },
            ]
        },
    ]
}
```

**Integration tests**:

```cue
// tests/definitions/integration/module_build_test.cue
package tests

import (
    core "github.com/open-platform-model/core"
    k8s "github.com/open-platform-model/core/providers/kubernetes"
    schema "github.com/open-platform-model/core/tests/schema"
)

moduleBuildTests: schema.#TestSuite & {
    name: "Module Build Integration Tests"

    tests: [
        {
            name: "Complete module builds and renders"
            subject: {
                // Define a complete module
                let myModule = core.#ModuleDefinition & {
                    #metadata: {
                        name: "test-app"
                        version: "1.0.0"
                    }
                    components: {
                        web: {
                            core.#StatelessWorkload
                            stateless: container: {
                                image: "nginx:latest"
                                ports: http: targetPort: 80
                            }
                        }
                        db: {
                            core.#StatefulWorkload
                            stateful: container: {
                                image: "postgres:15"
                                ports: db: targetPort: 5432
                            }
                        }
                    }
                }

                // Render with Kubernetes provider
                k8s.#Provider.render & {
                    module: myModule
                }
            }
            assertions: [
                {
                    type: "exports"
                    expected: {
                        // Should have Deployment for web
                        web: kind: "Deployment"
                        // Should have StatefulSet for db
                        db: kind: "StatefulSet"
                    }
                },
                {
                    type: "validates"
                    schema: {
                        [string]: {
                            kind: string
                            metadata: name: string
                        }
                    }
                },
            ]
        },
    ]
}
```

#### 2. Dagger Go Orchestration

Dagger module that discovers, loads, and executes CUE tests:

```go
// tests/dagger/main.go
package main

import (
    "context"
    "dagger/opm-tests/internal/dagger"
)

type OpmTests struct{}

// Run all tests
func (m *OpmTests) All(ctx context.Context) (string, error) {
    return dag.Container().
        From("cuelang/cue:latest").
        WithDirectory("/src", dag.Host().Directory(".", dagger.HostDirectoryOpts{
            Include: []string{"**/*.cue", "cue.mod/**"},
        })).
        WithWorkdir("/src").
        WithExec([]string{"cue", "vet", "./..."}).
        WithExec([]string{"cue", "export", "./tests/definitions/...", "--out", "json"}).
        Stdout(ctx)
}

// Run unit tests only
func (m *OpmTests) Unit(ctx context.Context) (string, error) {
    return m.runTestSuite(ctx, "unit")
}

// Run integration tests only
func (m *OpmTests) Integration(ctx context.Context) (string, error) {
    return m.runTestSuite(ctx, "integration")
}

// Run specific test file
func (m *OpmTests) File(ctx context.Context, path string) (string, error) {
    return dag.Container().
        From("cuelang/cue:latest").
        WithDirectory("/src", dag.Host().Directory(".")).
        WithWorkdir("/src").
        WithExec([]string{"cue", "export", path, "--out", "json"}).
        Stdout(ctx)
}

// Watch mode - continuous testing
func (m *OpmTests) Watch(ctx context.Context) error {
    // Use Dagger's watch capabilities
    watcher := dag.Host().Directory(".", dagger.HostDirectoryOpts{
        Include: []string{"**/*.cue"},
    })

    // Trigger tests on file changes
    return m.watchAndTest(ctx, watcher)
}

// Parallel execution of test suites
func (m *OpmTests) Parallel(ctx context.Context) ([]*dagger.Container, error) {
    suites := []string{"unit", "integration"}
    containers := make([]*dagger.Container, len(suites))

    for i, suite := range suites {
        containers[i] = dag.Container().
            From("cuelang/cue:latest").
            WithDirectory("/src", dag.Host().Directory(".")).
            WithWorkdir("/src").
            WithExec([]string{"cue", "export",
                "./tests/definitions/" + suite + "/...",
                "--out", "json"})
    }

    return containers, nil
}

// Test with coverage analysis
func (m *OpmTests) Coverage(ctx context.Context) (string, error) {
    // Export all tests and analyze coverage
    return dag.Container().
        From("cuelang/cue:latest").
        WithDirectory("/src", dag.Host().Directory(".")).
        WithWorkdir("/src").
        WithExec([]string{"sh", "-c", `
            # Export all test results
            cue export ./tests/definitions/... --out json > /tmp/tests.json

            # Count total assertions
            TOTAL=$(cat /tmp/tests.json | jq '[.. | .assertions? // empty] | add | length')

            # Count passed assertions (no _|_ bottoms)
            PASSED=$(cat /tmp/tests.json | jq '[.. | .assertions? // empty] | add | map(select(. != "_|_")) | length')

            echo "Test Coverage: $PASSED/$TOTAL assertions passed"
        `}).
        Stdout(ctx)
}
```

```go
// tests/dagger/tests.go
package main

import (
    "context"
    "encoding/json"
    "fmt"
    "strings"
)

type TestResult struct {
    Suite    string   `json:"suite"`
    Passed   int      `json:"passed"`
    Failed   int      `json:"failed"`
    Skipped  int      `json:"skipped"`
    Duration float64  `json:"duration"`
    Failures []string `json:"failures,omitempty"`
}

func (m *OpmTests) runTestSuite(ctx context.Context, suite string) (string, error) {
    // Execute CUE tests and parse results
    container := dag.Container().
        From("cuelang/cue:latest").
        WithDirectory("/src", dag.Host().Directory(".")).
        WithWorkdir("/src").
        WithExec([]string{"cue", "export",
            fmt.Sprintf("./tests/definitions/%s/...", suite),
            "--out", "json"})

    output, err := container.Stdout(ctx)
    if err != nil {
        return "", err
    }

    // Parse and validate test results
    result := m.parseTestResults(output, suite)
    return m.formatResults(result), nil
}

func (m *OpmTests) parseTestResults(output string, suite string) *TestResult {
    // Parse CUE test output JSON
    var tests map[string]interface{}
    json.Unmarshal([]byte(output), &tests)

    result := &TestResult{Suite: suite}

    // Evaluate assertions by checking if CUE unified successfully
    // Failed assertions will have _|_ (bottom) in the output
    for name, test := range tests {
        testStr := fmt.Sprintf("%v", test)
        if strings.Contains(testStr, "_|_") || strings.Contains(testStr, "error") {
            result.Failed++
            result.Failures = append(result.Failures, name)
        } else {
            result.Passed++
        }
    }

    return result
}

func (m *OpmTests) formatResults(r *TestResult) string {
    if r.Failed == 0 {
        return fmt.Sprintf("✓ %s: %d passed", r.Suite, r.Passed)
    }
    return fmt.Sprintf("✗ %s: %d passed, %d failed\nFailures:\n%v",
        r.Suite, r.Passed, r.Failed, strings.Join(r.Failures, "\n"))
}

// Generate JUnit XML report for CI integration
func (m *OpmTests) JunitReport(ctx context.Context) (string, error) {
    // Run all tests and format as JUnit XML
    result, err := m.All(ctx)
    if err != nil {
        return "", err
    }

    // Convert to JUnit XML format
    xml := fmt.Sprintf(`<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
    <testsuite name="OPM Tests">
        %s
    </testsuite>
</testsuites>`, result)

    return xml, nil
}
```

```go
// tests/dagger/watch.go
package main

import (
    "context"
    "fmt"
    "time"
    "dagger/opm-tests/internal/dagger"
)

func (m *OpmTests) watchAndTest(ctx context.Context, dir *dagger.Directory) error {
    ticker := time.NewTicker(500 * time.Millisecond)
    defer ticker.Stop()

    lastHash := ""

    for {
        select {
        case <-ctx.Done():
            return ctx.Err()
        case <-ticker.C:
            // Check for file changes using content-addressed hashing
            currentHash, err := dir.Directory(".").Digest(ctx)
            if err != nil {
                continue
            }

            if currentHash != lastHash {
                lastHash = currentHash

                fmt.Println("🔄 Change detected, running tests...")

                // Run tests on change
                result, err := m.All(ctx)
                if err != nil {
                    fmt.Printf("❌ Tests failed: %v\n", err)
                } else {
                    fmt.Printf("✅ Tests passed:\n%s\n", result)
                }
                fmt.Println("---")
            }
        }
    }
}

// Advanced watch with debouncing
func (m *OpmTests) WatchDebounced(ctx context.Context, debounceMs int) error {
    watcher := dag.Host().Directory(".", dagger.HostDirectoryOpts{
        Include: []string{"**/*.cue"},
    })

    ticker := time.NewTicker(time.Duration(debounceMs) * time.Millisecond)
    defer ticker.Stop()

    var pendingHash string
    lastRunHash := ""

    for {
        select {
        case <-ctx.Done():
            return ctx.Err()
        case <-ticker.C:
            currentHash, err := watcher.Directory(".").Digest(ctx)
            if err != nil {
                continue
            }

            // Update pending hash
            if currentHash != lastRunHash {
                pendingHash = currentHash
            }

            // Run tests if hash changed and stabilized
            if pendingHash != "" && pendingHash == currentHash && pendingHash != lastRunHash {
                lastRunHash = pendingHash
                pendingHash = ""

                fmt.Println("🔄 Running tests...")
                result, err := m.All(ctx)
                if err != nil {
                    fmt.Printf("❌ Failed: %v\n", err)
                } else {
                    fmt.Printf("✅ Passed:\n%s\n", result)
                }
            }
        }
    }
}
```

```go
// tests/dagger/reporters.go
package main

import (
    "context"
    "encoding/json"
    "fmt"
)

type Reporter interface {
    Report(results *TestResult) string
}

type ConsoleReporter struct{}

func (r *ConsoleReporter) Report(results *TestResult) string {
    if results.Failed == 0 {
        return fmt.Sprintf("✓ %d tests passed", results.Passed)
    }
    return fmt.Sprintf("✗ %d passed, %d failed", results.Passed, results.Failed)
}

type JSONReporter struct{}

func (r *JSONReporter) Report(results *TestResult) string {
    data, _ := json.MarshalIndent(results, "", "  ")
    return string(data)
}

type TAPReporter struct{}

func (r *TAPReporter) Report(results *TestResult) string {
    total := results.Passed + results.Failed
    output := fmt.Sprintf("1..%d\n", total)

    for i := 0; i < results.Passed; i++ {
        output += fmt.Sprintf("ok %d\n", i+1)
    }

    for i, failure := range results.Failures {
        output += fmt.Sprintf("not ok %d - %s\n", results.Passed+i+1, failure)
    }

    return output
}

// Generate reports in multiple formats
func (m *OpmTests) Report(ctx context.Context, format string) (string, error) {
    // Run all tests
    output, err := m.All(ctx)
    if err != nil {
        return "", err
    }

    result := m.parseTestResults(output, "all")

    var reporter Reporter
    switch format {
    case "json":
        reporter = &JSONReporter{}
    case "tap":
        reporter = &TAPReporter{}
    default:
        reporter = &ConsoleReporter{}
    }

    return reporter.Report(result), nil
}
```

#### 3. Usage Examples

```bash
# Initialize Dagger module (one-time setup)
cd tests/dagger
dagger init --sdk=go
dagger develop

# Run all tests
dagger call all

# Run unit tests only
dagger call unit

# Run integration tests only
dagger call integration

# Run specific test file
dagger call file --path=./tests/definitions/unit/elements_test.cue

# Watch mode (continuous testing)
dagger call watch

# Watch with debouncing (500ms)
dagger call watch-debounced --debounce-ms=500

# Parallel execution
dagger call parallel

# Generate test report (JSON)
dagger call report --format=json > test-results.json

# Generate JUnit XML for CI
dagger call junit-report > test-results.xml

# Test coverage analysis
dagger call coverage

# Run tests with specific CUE version
dagger call all --cue-version=v0.14.0
```

**CI Integration** (GitHub Actions):

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Dagger
        run: |
          cd /usr/local
          curl -L https://dl.dagger.io/dagger/install.sh | sh

      - name: Run tests
        run: |
          cd tests/dagger
          dagger call all

      - name: Generate report
        run: |
          cd tests/dagger
          dagger call junit-report > test-results.xml

      - name: Publish test results
        uses: EnricoMi/publish-unit-test-result-action@v2
        if: always()
        with:
          files: test-results.xml
```

**Local Development Workflow**:

```bash
# Terminal 1: Watch mode for continuous testing
cd tests/dagger
dagger call watch

# Terminal 2: Make changes to CUE files
vim core/elements/core/workload_primitive_container.cue
# Save - tests automatically run in Terminal 1

# Run specific test suite after focused changes
dagger call unit

# Check test coverage after adding new tests
dagger call coverage
```

### Key Benefits

#### From Pure CUE Tests

1. **Type Safety**: Tests are validated by CUE's type system
2. **Declarative**: Clean, readable test definitions
3. **No Dependencies**: Test definitions are pure CUE
4. **Same Language**: Tests use same language as implementation
5. **Schema Validation**: Built-in unification testing

#### From Dagger Go

1. **Content-Addressed Caching**: Instant re-runs if nothing changed
2. **Parallel Execution**: Automatic parallelization based on DAG
3. **Reproducibility**: Same results locally, CI, anywhere
4. **Container Isolation**: Each test suite in clean environment
5. **Rich Orchestration**: Complex test pipelines as Go code
6. **Watch Mode**: Built-in file watching and triggering
7. **Cloud-Native**: Ready for distributed execution

### Performance Characteristics

**Cold Run** (first time, no cache):

```
Unit tests:        ~2-3s  (download image + CUE execution)
Integration tests: ~5-8s  (more complex evaluation)
Full suite:        ~8-10s (parallel execution)
```

**Warm Run** (cached, no changes):

```
Unit tests:        ~100-200ms (content-addressed cache hit)
Integration tests: ~200-500ms (cache hit)
Full suite:        ~500ms-1s  (parallel + cached)
```

**Incremental Run** (small changes):

```
Changed suite:     ~500ms-1s  (only affected tests)
Unchanged suites:  ~100ms     (cache hit)
Total:             ~1-2s      (partial cache hit)
```

**Watch Mode**:

```
Change detection:  <100ms     (content-addressed hashing)
Test execution:    200ms-1s   (only changed suites)
Total latency:     <1.5s      (from save to results)
```

### Trade-offs

**Pros**:

- ⭐⭐⭐⭐⭐ Best caching (Dagger's content-addressed system)
- ⭐⭐⭐⭐⭐ Type-safe test definitions (pure CUE)
- ⭐⭐⭐⭐⭐ Parallel execution (automatic DAG-based)
- ⭐⭐⭐⭐⭐ Reproducibility (container-based)
- ⭐⭐⭐⭐ Watch mode (built-in Dagger support)
- ⭐⭐⭐⭐ Rich reporting (Go flexibility)
- ⭐⭐⭐⭐ CI/CD ready (designed for it)
- ⭐⭐⭐⭐ Incremental testing (only run what changed)

**Cons**:

- Requires Go knowledge for orchestration (not just CUE)
- Dagger Engine dependency (though widely adopted)
- Initial setup complexity (Dagger module initialization)
- Container overhead on first run (mitigated by caching)
- Two-language system (CUE for tests, Go for orchestration)

### Why This Hybrid Approach Works

1. **Separation of Concerns**:
   - CUE: What to test (declarations)
   - Go: How to execute tests (orchestration)

2. **Leverage Strengths**:
   - CUE's type system for test correctness
   - Dagger's caching for blazing-fast iterations
   - Go's ecosystem for reporting/tooling

3. **Developer Experience**:
   - Write tests in CUE (familiar for OPM developers)
   - Fast iterations via content-addressed caching
   - Rich output via Go reporters
   - Watch mode for continuous feedback

4. **Future-Proof**:
   - Dagger Go SDK is actively maintained (unlike CUE SDK)
   - Can extend orchestration without changing test definitions
   - Easy to add new reporters, integrations, custom logic
   - Ready for distributed/cloud execution

### Comparison to Pure Options

| Feature | Pure CUE (Option 1) | CUE + Dagger (Option 4) |
|---------|---------------------|-------------------------|
| Test definitions | CUE | CUE (identical) |
| Execution | `cue cmd` | Dagger Go |
| Caching | CUE's evaluation cache | Content-addressed (superior) |
| Parallelization | Manual via `$after` | Automatic DAG-based |
| Watch mode | Custom tool/file | Dagger built-in |
| Containers | No | Yes (isolation) |
| Reporting | Limited (JSON/YAML) | Rich (Go-based, multiple formats) |
| CI integration | Custom scripts | Native Dagger support |
| Incremental testing | Manual | Automatic (content-addressed) |
| Performance (cold) | ~1-2s | ~8-10s |
| Performance (warm) | ~500ms-1s | ~100-500ms |
| Performance (watch) | ~200ms | ~200ms-1s |

---

## Comparison Matrix

| Criterion | Option 1<br>(Pure CUE) | Option 2<br>(Go+CUE) | Option 3<br>(DSL) | Option 4<br>(CUE+Dagger Go) |
|-----------|------------------------|----------------------|-------------------|-----------------------------|
| **Speed (warm)** | ⭐⭐⭐⭐⭐<br>~500ms | ⭐⭐⭐⭐⭐<br>~200ms | ⭐⭐⭐⭐<br>~500ms-1s | ⭐⭐⭐⭐⭐<br>~100-500ms |
| **No dependencies** | ⭐⭐⭐⭐⭐<br>Pure CUE | ⭐⭐⭐<br>Requires Go | ⭐⭐⭐<br>Python/Node | ⭐⭐<br>Docker+Dagger+Go |
| **Watch mode** | ⭐⭐⭐⭐<br>Custom | ⭐⭐⭐⭐⭐<br>gotestsum | ⭐⭐⭐⭐⭐<br>Watchdog | ⭐⭐⭐⭐⭐<br>Built-in |
| **Reporting** | ⭐⭐⭐<br>Basic | ⭐⭐⭐⭐⭐<br>Excellent | ⭐⭐⭐⭐⭐<br>Excellent | ⭐⭐⭐⭐⭐<br>Excellent |
| **Learning curve** | ⭐⭐<br>CUE cmd | ⭐⭐⭐⭐<br>Go | ⭐⭐⭐<br>DSL+Runner | ⭐⭐⭐<br>CUE+Dagger+Go |
| **Type safety** | ⭐⭐⭐⭐⭐<br>Full CUE | ⭐⭐⭐⭐<br>Go+CUE | ⭐⭐⭐⭐<br>CUE | ⭐⭐⭐⭐⭐<br>Full CUE |
| **Caching** | ⭐⭐⭐<br>CUE cache | ⭐⭐⭐<br>Go cache | ⭐⭐⭐<br>Manual | ⭐⭐⭐⭐⭐<br>Content-addr |
| **Parallelization** | ⭐⭐⭐<br>Manual | ⭐⭐⭐⭐⭐<br>go test -p | ⭐⭐⭐<br>Manual | ⭐⭐⭐⭐⭐<br>Automatic |
| **CI Integration** | ⭐⭐⭐<br>Custom | ⭐⭐⭐⭐⭐<br>Native | ⭐⭐⭐⭐<br>Good | ⭐⭐⭐⭐⭐<br>Native |
| **Reproducibility** | ⭐⭐⭐⭐<br>Good | ⭐⭐⭐⭐<br>Good | ⭐⭐⭐<br>Runtime-dep | ⭐⭐⭐⭐⭐<br>Containers |

---

## Recommendations

### For Fast Continuous Development (Primary Goal)

**Recommended: Option 4 (Pure CUE + Dagger Go)** ⭐⭐

**Reasoning**:

- **Sub-second warm runs** via content-addressed caching
- **Automatic watch mode** with built-in change detection
- **Type-safe test definitions** in pure CUE
- **Automatic parallelization** without manual configuration
- **Production-ready** for both local development and CI/CD

**Incremental Adoption Path**:

1. **Phase 1**: Start with pure CUE test definitions (no Dagger)
   - Write tests in `tests/definitions/` using test schema
   - Run manually with `cue export` to validate approach
   - No additional dependencies at this stage

2. **Phase 2**: Add Dagger orchestration for advanced features
   - Create Dagger Go module in `tests/dagger/`
   - Enable watch mode, caching, parallel execution
   - No changes to test definitions required

3. **Phase 3**: Enhance with reporters and CI integration
   - Add custom reporters (JUnit, TAP, etc.)
   - Integrate with CI/CD pipelines
   - Add coverage analysis

### Alternative Recommendations by Use Case

**Most Go-friendly** (if team prefers Go):

- **Option 2 (Go + CUE API)**: Go testing with CUE integration
  - Pros: Excellent tooling, great IDE support, mature ecosystem
  - Cons: More boilerplate, additional language

**Minimal dependencies** (pure CUE only):

- **Option 1 (Pure CUE cmd)**: CUE-only test framework
  - Pros: No external deps, type-safe, fast
  - Cons: Limited reporting, manual watch mode setup

**Flexible custom approach**:

- **Option 3 (Custom DSL)**: Declarative test DSL with custom runner
  - Pros: Language-agnostic runner, flexible reporting
  - Cons: Custom tooling maintenance

---

## Implementation Roadmap

### Week 1: Foundation (Pure CUE Tests)

1. **Define test schema** (`tests/schema/test_schema.cue`)
   - `#Test`, `#Assertion`, `#TestSuite` definitions
   - Assertion types: unifies, equals, validates, contains, exports

2. **Write initial unit tests** (`tests/definitions/unit/`)
   - Element validation tests
   - Component composition tests
   - Registry completeness tests

3. **Validate approach**
   - Run tests manually: `cue export ./tests/definitions/unit/... --out json`
   - Verify test failures are caught correctly
   - Iterate on test schema if needed

### Week 2: Orchestration (Dagger Go)

1. **Setup Dagger module** (`tests/dagger/`)
   - Initialize: `dagger init --sdk=go`
   - Create `main.go` with basic test runners

2. **Implement core commands**
   - `all`, `unit`, `integration` functions
   - Test result parsing and validation

3. **Add watch mode**
   - Implement file watching with debouncing
   - Test locally for responsiveness

### Week 3: Enhancement

1. **Add reporters**
   - Console, JSON, JUnit XML, TAP formats
   - Test with CI/CD platforms

2. **Implement parallel execution**
   - Automatic DAG-based parallelization
   - Benchmark performance improvements

3. **Coverage analysis**
   - Count assertions and coverage metrics
   - Generate coverage reports

### Week 4: Integration

1. **Write integration tests** (`tests/definitions/integration/`)
   - Full module build tests
   - Provider rendering tests
   - End-to-end workflows

2. **CI/CD integration**
   - GitHub Actions workflow
   - GitLab CI pipeline (if needed)
   - Test result publishing

3. **Documentation**
   - Update `TESTING.md` with new framework
   - Write developer guide
   - Add examples and troubleshooting

---

## Future Enhancements

### Advanced Features

1. **Snapshot Testing**
   - Store expected outputs as fixtures
   - Compare against actual outputs
   - Update snapshots when intentional changes occur

2. **Property-Based Testing**
   - Generate random test inputs within CUE constraints
   - Verify properties hold for all valid inputs
   - Useful for transformer testing

3. **Mutation Testing**
   - Automatically introduce bugs
   - Verify tests catch the mutations
   - Measure test effectiveness

4. **Performance Benchmarking**
   - Track test execution times
   - Detect performance regressions
   - Optimize slow tests

5. **Visual Regression Testing**
   - Generate diagrams from modules
   - Compare before/after visualizations
   - Useful for module structure changes

### Tooling Improvements

1. **VSCode Extension**
   - Inline test results
   - Run tests from editor
   - Jump to failing assertions

2. **Test Dashboard**
   - Web UI showing test results
   - Historical trends
   - Flaky test detection

3. **Auto-generate Tests**
   - Scaffold tests from element definitions
   - Suggest assertions based on schemas
   - Reduce boilerplate

---

## Conclusion

**Option 4 (Pure CUE + Dagger Go)** offers the best balance of:

- Type-safe, declarative test definitions (CUE)
- Production-grade orchestration (Dagger)
- Sub-second iteration times (content-addressed caching)
- Automatic parallelization and watch mode
- Easy CI/CD integration

The incremental adoption path allows starting simple (pure CUE tests) and adding sophistication (Dagger orchestration) as needed, without rewriting tests.

**Next Steps**:

1. Review and approve this design
2. Create proof-of-concept implementation
3. Write initial test suite for core elements
4. Iterate and expand coverage

---

## Appendix: Example Test Outputs

### Console Output (Success)

```
🔄 Running tests...

✓ Element Tests: 15 passed
✓ Component Tests: 12 passed
✓ Transformer Tests: 8 passed
✓ Registry Tests: 5 passed

Total: 40 tests passed in 850ms
```

### Console Output (Failure)

```
🔄 Running tests...

✓ Element Tests: 15 passed
✗ Component Tests: 11 passed, 1 failed
  ❌ StatelessWorkload exports correctly
     Expected: stateless.container.image == "nginx:latest"
     Got: stateless.container.image == undefined

✓ Transformer Tests: 8 passed
✓ Registry Tests: 5 passed

Total: 39/40 tests passed (1 failure) in 920ms
```

### JSON Report

```json
{
  "suites": [
    {
      "name": "Element Tests",
      "passed": 15,
      "failed": 0,
      "duration": 245
    },
    {
      "name": "Component Tests",
      "passed": 11,
      "failed": 1,
      "duration": 312,
      "failures": [
        {
          "test": "StatelessWorkload exports correctly",
          "assertion": "exports",
          "expected": "stateless.container.image == \"nginx:latest\"",
          "got": "undefined"
        }
      ]
    }
  ],
  "summary": {
    "total": 40,
    "passed": 39,
    "failed": 1,
    "duration": 920
  }
}
```

### JUnit XML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="OPM Tests" tests="40" failures="1" time="0.920">
    <testsuite name="Element Tests" tests="15" failures="0" time="0.245">
      <testcase name="Container is valid primitive" time="0.015"/>
      <!-- ... more cases ... -->
    </testsuite>
    <testsuite name="Component Tests" tests="12" failures="1" time="0.312">
      <testcase name="StatelessWorkload exports correctly" time="0.024">
        <failure message="Export assertion failed">
          Expected: stateless.container.image == "nginx:latest"
          Got: undefined
        </failure>
      </testcase>
      <!-- ... more cases ... -->
    </testsuite>
  </testsuite>
</testsuites>
```
