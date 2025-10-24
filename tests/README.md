# OPM Test Framework

## Overview

This directory contains the CUE-native test framework for Open Platform Model (OPM). The test framework leverages CUE's type system and validation engine to test OPM's core logic without requiring external test dependencies.

**Current Status**: ~50 test cases covering core OPM logic across ~3,100 lines of test code.

**Philosophy**: Tests are declarative CUE definitions that validate through unification. If a test file validates successfully with `cue vet`, all tests pass.

---

## Quick Start

```bash
# Run all tests
cue cmd test

# Run unit tests only
cue cmd test:unit

# Run integration tests only
cue cmd test:integration

# Test specific file
cue cmd test:file -t path=unit/component.cue

# Export test results as JSON
cue cmd test:export
```

---

## What This Framework Can Test

### ✅ **Structural Validation**

Tests that data structures conform to schemas:

- Field presence/absence (using `_|_` for unset fields)
- Type correctness and constraint satisfaction
- Default value application
- Schema unification results

**Example:**

```cue
test: {
    subject: #Component & {
        container: image: "nginx:latest"
    }
    // Validate structure
    subject.container.image: "nginx:latest"
    // Test optional field is absent
    subject.replicas: _|_
}
```

### ✅ **Computed Values & Derivations**

Tests deterministic computations performed by CUE:

- Element `#fullyQualifiedName` generation
- Element `#nameCamel` conversion (e.g., "StatelessWorkload" → "statelessWorkload")
- Component workload type derivation from annotations
- Module status computation (component counts, etc.)

**Example:**

```cue
test: {
    subject: #Element & {
        #apiVersion: "v0"
        name: "Container"
    }
    // Test computed FQN
    subject.#fullyQualifiedName: "core.opm.dev/v0.Container"
}
```

### ✅ **Field Templating & Mapping**

Tests OPM's composite element field flattening:

- `statelessWorkload.container` → `container`
- `simpleDatabase.persistence` → conditional `volume`
- Optional field handling
- Nested structure templating

**Example:**

```cue
test: {
    subject: #StatelessWorkload & {
        statelessWorkload: {
            container: image: "nginx"
            replicas: count: 3
        }
    }
    // Verify fields are flattened
    subject.container.image: "nginx"
    subject.replicas.count: 3
}
```

### ✅ **List Operations & Aggregations**

Tests collection and aggregation logic:

- Composite element `#primitiveElements` extraction (recursive)
- Component `#primitiveElements` collection
- Module `#allPrimitiveElements` aggregation
- Component/scope merging across module layers

**Example:**

```cue
test: {
    subject: #Module & {
        moduleDefinition: {
            components: web: #StatelessWorkload
        }
        components: monitoring: #DaemonWorkload
    }
    // Test aggregation
    subject.components: {web: _, monitoring: _}
    subject.#status.totalComponentCount: 2
}
```

### ✅ **Value Flow & Inheritance**

Tests value constraint refinement through module layers:

- `ModuleDefinition` → `Module` → `ModuleRelease`
- Platform default application
- User value overrides
- Constraint refinement via CUE unification

**Example:**

```cue
test: {
    definition: #ModuleDefinition & {
        values: replicas: uint  // Constraint only
    }
    module: #Module & {
        moduleDefinition: definition
        values: replicas: uint | *3  // Add default
    }
    release: #ModuleRelease & {
        module: module
        values: replicas: 5  // User override
    }
    // Validate final value
    release.values.replicas: 5
}
```

### ✅ **Static Transformations**

Tests pure data transformations:

- Component → Kubernetes Deployment/Service/etc.
- Label/annotation merging
- Provider context construction
- Configuration rendering

**Example:**

```cue
test: {
    component: #StatelessWorkload & {
        statelessWorkload: container: image: "nginx"
    }
    deployment: #K8sDeploymentTransformer & {
        #context: _component: component
    }
    // Validate transformation
    deployment.kind: "Deployment"
    deployment.spec.template.spec.containers[0].image: "nginx"
}
```

### ✅ **Cross-Field Validation**

Tests business logic invariants:

- Component can only have one workload type
- Element compatibility rules
- Required field relationships
- Conditional field constraints

---

## What This Framework **Cannot** Test

### ❌ **I/O Operations**

- Reading files from filesystem at runtime
- Writing generated manifests to disk
- Network requests (registry pulls, API calls)
- Database operations
- Environment variable resolution (beyond static injection)

**Why**: CUE operates on closed, immutable data structures.

### ❌ **Time-Dependent Behavior**

- Timestamp generation
- Expiration logic
- Scheduling and cron expressions
- Retry/backoff strategies
- Race conditions

**Why**: CUE evaluation is deterministic and hermetic.

### ❌ **Stateful Operations**

- Mutations over time
- Cache behavior
- Session management
- Transaction semantics
- State machine transitions

**Why**: CUE is purely functional; all values are immutable.

### ❌ **External System Integration**

- Actual Kubernetes deployment (`kubectl apply`)
- Container image validation (checking if image exists)
- Service readiness checks
- DNS resolution
- Certificate verification

**Why**: Tests run in isolation without external dependencies.

### ❌ **Error Recovery & Handling**

- Exception handling paths
- Graceful degradation strategies
- Fallback logic with side effects
- Partial failure scenarios
- Rollback operations

**Why**: CUE fails fast on constraint violations; no try/catch.

### ❌ **Performance Testing**

- Memory consumption
- CPU usage
- Validation time benchmarks
- Concurrency behavior
- Load testing

**Why**: CUE validation has its own performance profile.

### ❌ **Dynamic/Runtime Behavior**

- Plugin loading
- Dynamic code generation
- Reflection-based operations
- Conditional compilation
- Feature flags evaluated at runtime

**Why**: CUE is evaluated statically at definition time.

### ❌ **Non-Deterministic Operations**

- Random value generation
- Probabilistic logic
- Sampling and fuzzing
- UUID generation
- Hash collisions

**Why**: CUE is deterministic by design.

### ❌ **Complex Control Flow**

- Imperative loops with early exit
- Complex branching with side effects
- Event-driven workflows
- Asynchronous operations
- Callback chains

**Why**: CUE is constraint-based, not imperative.

---

## Test Coverage Summary

### Current Coverage (Implemented)

**Unit Tests** (~4 files, ~30 test cases):

- ✅ Element logic (`#fullyQualifiedName`, `#nameCamel`, primitive extraction)
- ✅ Component logic (workload type, element extraction, schema injection)
- ✅ Module logic (merging, aggregation, status computation)
- ✅ Composite templating (field flattening, optional fields, conditionals)
- ❌ **Provider/Transformer selection** (MISSING - see gaps below)

**Integration Tests** (~5 files, ~20 test cases):

- ✅ Component → Kubernetes resource rendering
- ✅ Value flow through module layers
- ✅ Real-world application scenarios (three-tier apps, databases)
- ✅ Module composition and platform additions
- ✅ Conditional templating with user overrides

**Total**: ~50 meaningful tests covering OPM core logic

### Test Coverage Gaps

#### 1. **Provider/Transformer Selection** (Unit Tests)

**Missing**: `unit/provider.cue` (~2-4 tests needed)

Tests needed:

- Transformer selection based on component element composition
- Provider capability matching
- `#SelectTransformer` logic validation
- Provider context construction

**Why Important**: This is critical logic for matching components to the correct platform transformers. Currently untested.

**Effort**: ~2-4 hours to implement

#### 2. **Negative Test Cases** (All Areas)

**Partial Coverage**: Some negative cases exist, but not comprehensive

Tests needed:

- Invalid component configurations (multiple workload types)
- Conflicting element combinations
- Required field violations (should fail validation)
- Invalid value overrides (breaking constraints)

**Why Important**: Ensures OPM fails gracefully with clear errors.

**Effort**: ~4-8 hours to add comprehensive negative tests

#### 3. **Edge Cases** (All Areas)

**Limited Coverage**: Happy path mostly covered, edge cases sparse

Tests needed:

- Empty components/modules
- Deeply nested value references
- Large-scale modules (50+ components)
- Unicode in names/labels
- Boundary values (max port numbers, etc.)

**Why Important**: Prevents production issues from unusual but valid inputs.

**Effort**: ~4-8 hours for thorough edge case coverage

---

## Limitations & Trade-offs

### Current Limitations

1. **No Test Isolation**: All tests in a package share the same namespace. Name collisions require unique test names.

2. **Limited Error Messages**: When a test fails, CUE shows unification errors which can be cryptic. Requires understanding CUE error format.

3. **No Test Discovery**: Test runner uses explicit paths (`./unit/...`, `./integration/...`). Adding new test directories requires updating `test_tool.cue`.

4. **No Test Fixtures Reuse**: While `fixtures/data.cue` exists, there's no standard pattern for complex fixture setup/teardown.

5. **No Mocking**: Cannot mock external dependencies or stub out functions. Tests must use real OPM definitions.

6. **No Assertions Library**: No rich assertion helpers like `assertEquals`, `assertContains`, etc. All assertions are via CUE unification.

7. **No Test Output Formatting**: Test results are pass/fail only. No detailed reports, coverage metrics, or pretty printing.

8. **No Parallel Execution**: Tests run sequentially via `cue vet`. No parallelization within test suites.

### Design Trade-offs

**Simplicity vs. Features**: This framework prioritizes simplicity and zero dependencies over rich testing features. This is intentional.

**Declarative vs. Imperative**: Tests are constraints, not procedures. This makes them readable but limits expressiveness.

**Type Safety vs. Flexibility**: CUE's type system catches errors at definition time, but makes some test patterns impossible.

---

## When to Use Go Testing Instead

If you need to test any of the following, implement a **Go test suite** alongside CUE tests:

### Go Testing Required For

1. **CLI Tool Implementation**
   - `opm generate` command execution
   - `opm validate` command behavior
   - Flag parsing and argument handling
   - Exit codes and error messages

2. **File I/O Operations**
   - Loading modules from filesystem
   - Writing generated manifests
   - Template file processing
   - Configuration file reading

3. **External System Integration**
   - Kubernetes cluster deployment
   - Image registry interactions
   - Git repository operations
   - HTTP API calls

4. **Runtime Behavior**
   - Plugin system (loading providers dynamically)
   - Caching mechanisms
   - Performance benchmarks
   - Resource usage monitoring

5. **Error Handling Flows**
   - Graceful failure scenarios
   - Retry logic and backoff
   - Recovery from partial failures
   - User-facing error messages

### Hybrid Approach (Recommended)

**Use CUE for**: Core OPM logic (90% of framework)

- Element system
- Component composition
- Module inheritance
- Transformers
- Value templating

**Use Go for**: Tooling and integrations (10% of needs)

- CLI commands
- File loading
- Actual deployments
- Performance testing

**Example Go Test**:

```go
func TestCLIGenerate(t *testing.T) {
    // Use CUE to define module
    module := cue.Export("fixtures/my-app.cue")

    // Use Go to test CLI
    cmd := exec.Command("opm", "generate", "-")
    cmd.Stdin = strings.NewReader(module)
    output, err := cmd.CombinedOutput()

    assert.NoError(t, err)
    assert.Contains(t, string(output), "kind: Deployment")
}
```

---

## Future Enhancements

### Phase 1: Complete Current Framework

1. **Add Provider/Transformer Tests** (`unit/provider.cue`)
   - Implement transformer selection tests
   - Test provider context construction
   - Validate `#SelectTransformer` logic

2. **Expand Negative Tests**
   - Add invalid configuration tests
   - Test constraint violation handling
   - Ensure proper failure modes

3. **Add Edge Case Coverage**
   - Empty/minimal configurations
   - Boundary values
   - Large-scale scenarios

4. **Improve Test Documentation**
   - Add inline comments to complex tests
   - Document test patterns and conventions
   - Create troubleshooting guide

### Phase 2: Enhanced CUE Framework

1. **Test Helpers & Utilities**
   - Create reusable assertion patterns
   - Build fixture management system
   - Develop test data generators

2. **Better Error Reporting**
   - Parse CUE errors for readable output
   - Add test name tracking
   - Generate HTML/markdown reports

3. **Test Organization**
   - Implement test tags/categories
   - Support selective test execution
   - Add test dependency management

4. **Performance & Metrics**
   - Track test execution time
   - Monitor test suite growth
   - Identify slow tests

### Phase 3: Go Test Suite

1. **CLI Testing Framework**
   - Command execution helpers
   - Fixture management
   - Output validation

2. **Integration Test Harness**
   - Kubernetes test cluster setup
   - Mock external services
   - End-to-end workflow testing

3. **Performance Testing**
   - Benchmark CUE evaluation
   - Load testing transformers
   - Memory profiling

4. **CI/CD Integration**
   - GitHub Actions workflows
   - Test result publishing
   - Coverage reporting

---

## Contributing Tests

### Adding New Tests

1. **Determine Test Type**
   - Unit test: Tests single function/computation
   - Integration test: Tests multi-component interaction

2. **Choose Test File**
   - Add to existing file if related
   - Create new file for new test category

3. **Follow Naming Convention**

   ```cue
   testSuiteName: {
       "category/test-name": {
           // Test implementation
       }
   }
   ```

4. **Test Both Success and Failure**

   ```cue
   "feature/valid-case": {
       subject: #Definition & {...}
       subject.field: expectedValue
   }

   "feature/invalid-case": {
       subject: #Definition & {...}
       // Test field is unset/error
       subject.invalidField: _|_
   }
   ```

5. **Add Test to Suite**
   - Unit test: Runs via `cue vet ./unit/...`
   - Integration test: Runs via `cue vet ./integration/...`
   - No registration needed (auto-discovered)

### Test Writing Guidelines

1. **Keep Tests Focused**: One test per behavior/scenario
2. **Use Descriptive Names**: `"component/workload-type-derivation"` not `"test1"`
3. **Add Comments**: Explain complex assertions or non-obvious logic
4. **Test Edge Cases**: Not just happy paths
5. **Verify Failures**: Use `_|_` to test absence/errors
6. **Use Fixtures**: Import from `fixtures/data.cue` for reusable data

### Running Tests During Development

```bash
# Watch mode (requires watchexec)
cue cmd test:watch

# Test specific file while developing
cue cmd test:file -t path=unit/mynewtest.cue

# Verbose mode to see all errors
cue cmd test:verbose

# Format before committing
cue fmt ./...
```

---

## Troubleshooting

### Test Fails with "Conflicting Values"

**Cause**: Field has multiple conflicting constraints

**Solution**: Check that test assertions don't conflict with schema

```cue
// Bad: schema says string, test says int
subject.field: "string" // from schema
subject.field: 123      // from test - CONFLICT!

// Good: match schema type
subject.field: "expected-value"
```

### Test Passes But Shouldn't

**Cause**: Test assertions are too loose or missing

**Solution**: Be more specific with assertions

```cue
// Bad: allows any value
subject.field: _

// Good: exact value
subject.field: "expected-value"
```

### Can't Test Field Absence

**Cause**: Field is optional and has default value

**Solution**: Use `_|_` to test field is bottom (unset)

```cue
// Test field is absent/unset
subject.optionalField: _|_
```

### Import Errors

**Cause**: Incorrect import path or missing package

**Solution**: Use full module path

```cue
import (
    opm "github.com/open-platform-model/core"
    core "github.com/open-platform-model/core/elements/core"
)
```

### Test Runner Can't Find Tests

**Cause**: Wrong package name or directory structure

**Solution**: Ensure package matches directory

```cue
// In unit/mytest.cue
package unit  // Must be "unit"

// In integration/mytest.cue
package integration  // Must be "integration"
```

---

## Resources

- **[CUE Documentation](https://cuelang.org/docs/)**: Official CUE language docs
- **[CUE Testing Patterns](https://cuelang.org/docs/usecases/validation/)**: Validation use cases
- **[test_tool.cue](test_tool.cue)**: Test runner implementation reference

---

## Summary

### Current Capabilities ✅

- **~50 tests** covering OPM core logic
- **Structural validation** (schemas, types, constraints)
- **Computed values** (derivations, aggregations)
- **Field templating** (composite element flattening)
- **Value flow** (inheritance through module layers)
- **Static transformations** (component → K8s resources)

### Current Gaps ❌

- **Provider/transformer selection tests** (unit tests needed)
- **Comprehensive negative tests** (error cases)
- **Edge case coverage** (boundary conditions)
- **Runtime behavior testing** (requires Go)
- **External integration testing** (requires Go)

### Recommendation

**For 90% of OPM development**: The current CUE test framework is sufficient and appropriate.

**For CLI tools and runtime behavior**: Complement with Go tests as needed.

The framework is **production-ready for testing OPM's declarative core**, with clear boundaries on what belongs in CUE vs. Go testing.
