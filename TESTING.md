# Testing Guide

This document describes how to run tests and validations for the OPM Core framework.

## Quick Test

Run the simple test script:

```bash
./run-tests.sh
```

This will validate:

- CUE formatting
- CUE validation
- Example module exports
- Annotation system implementation
- Documentation completeness
- Element statistics

## Comprehensive Test

Run the full test suite:

```bash
./test.sh
```

This provides more detailed output with test categories and colored results.

## Manual Testing

### Format CUE Files

```bash
cue fmt ./...
```

### Validate All Definitions

```bash
cue vet ./...
```

Note: Some "incomplete" warnings are expected for abstract type definitions.

### Export Example Module

```bash
# Export to JSON
cue export ./examples/example_modules.cue -e myAppDefinition --out json

# Export to YAML
cue export ./examples/example_modules.cue -e myAppDefinition --out yaml
```

### Check Element Registry

```bash
# Count elements
cue export ./elements/elements.cue -e '#CoreElementRegistry' --out json | jq 'keys | length'

# List all elements
cue export ./elements/elements.cue -e '#CoreElementRegistry' --out json | jq 'keys'
```

### Validate Specific Definitions

```bash
# Element definition
cue export ./element.cue -e '#Element' --out cue

# Component definition
cue export ./component.cue -e '#Component' --out cue

# Module definition
cue export ./module.cue -e '#ModuleDefinition' --out cue

# Provider definition
cue export ./provider.cue -e '#Provider' --out cue
```

## Annotation System Tests

### Verify Annotation Constant

```bash
grep '#AnnotationWorkloadType' ./element.cue
```

Expected output:

```
#AnnotationWorkloadType: "core.opm.dev/workload-type"
```

### Verify Component Derivation

```bash
grep 'annotations\[#AnnotationWorkloadType\]' ./component.cue
```

Should show the workloadType derivation logic.

### Count Annotated Elements

```bash
grep -r '"core.opm.dev/workload-type"' ./elements/
```

### Verify No Old workloadType Fields

```bash
# Should return nothing (or only comments/constants)
grep -r 'workloadType:' ./elements/core/*.cue ./elements/kubernetes/*.cue | grep -v '//' | grep -v '#'
```

## Element Statistics

### Count by Kind

```bash
# Primitives
grep -r 'kind: "primitive"' ./elements/ | wc -l

# Composites
grep -r 'kind: "composite"' ./elements/ | wc -l

# Modifiers
grep -r 'kind: "modifier"' ./elements/ | wc -l
```

### Count by Category

```bash
# Workload elements
grep -r '"core.opm.dev/category": "workload"' ./elements/ | wc -l

# Data elements
grep -r '"core.opm.dev/category": "data"' ./elements/ | wc -l

# Connectivity elements
grep -r '"core.opm.dev/category": "connectivity"' ./elements/ | wc -l
```

## Continuous Integration

For CI/CD pipelines, use:

```bash
#!/bin/bash
set -e

# Format check
cue fmt ./...

# Validation
cue vet ./... 2>&1 | grep -q "incomplete" || cue vet ./...

# Example export
cue export ./examples/example_modules.cue -e myAppDefinition --out json > /dev/null

echo "All tests passed!"
```

## Troubleshooting

### "incomplete value" errors

These are expected for abstract type definitions. They indicate that schemas have required fields that aren't filled in - this is normal for type definitions.

### Import cycle errors

Make sure you don't have test files in the same package as the core definitions. Test files should be in separate directories or packages.

### Element not found errors

Ensure all new elements are registered in `elements/elements.cue` in the `#CoreElementRegistry`.

## Test Coverage

Current test coverage includes:

- ✅ CUE formatting and validation
- ✅ Core type definitions (Element, Component, Module, Provider)
- ✅ Element registry
- ✅ Example module exports
- ✅ Annotation system implementation
- ✅ Component workloadType derivation
- ✅ Element categorization
- ✅ Documentation completeness

## Recent Changes (2025-10-02)

- Replaced `workloadType` field with `annotations` map
- Added workload-type annotation: `"core.opm.dev/workload-type"`
- Updated component derivation to use annotations
- Added validation for single workload-type per component
- Updated all elements to use annotations system
