.PHONY: validate publish-local publish-remote tag clean help

# Configuration
MODULE := github.com/open-platform-model/core
VERSION ?= v0.1.0
LOCAL_REGISTRY ?= localhost:5000
REMOTE_REGISTRY ?= ghcr.io/open-platform-model

# OCI image references
LOCAL_IMAGE := $(LOCAL_REGISTRY)/$(MODULE)
REMOTE_IMAGE := $(REMOTE_REGISTRY)/core

# Validate CUE files
validate:
	@echo "Validating CUE module..."
	@cue vet ./*.cue || (echo "❌ Validation failed"; exit 1)
	@echo "✅ Validation passed"

# Publish to local OCI registry
publish-local: validate
	@echo "Publishing $(MODULE):$(VERSION) to local registry..."
	@CUE_REGISTRY=$(LOCAL_REGISTRY) cue mod publish $(VERSION) || (echo "❌ Publishing failed"; exit 1)
	@echo "✅ Published to $(LOCAL_IMAGE):$(VERSION)"
	@echo ""
	@echo "Verify with:"
	@echo "  curl http://$(LOCAL_REGISTRY)/v2/_catalog"
	@echo "  curl http://$(LOCAL_REGISTRY)/v2/$(MODULE)/tags/list"

# Publish to remote OCI registry (GitHub Container Registry)
publish-remote: validate
	@echo "Publishing $(MODULE):$(VERSION) to remote registry..."
	@CUE_REGISTRY=$(REMOTE_REGISTRY) cue mod publish $(VERSION) || (echo "❌ Publishing failed"; exit 1)
	@echo "✅ Published to $(REMOTE_IMAGE):$(VERSION)"

# Create git tag for version
tag:
	@echo "Creating git tag $(VERSION)..."
	@git tag -a $(VERSION) -m "Release $(VERSION)" || (echo "❌ Tag creation failed"; exit 1)
	@git push origin $(VERSION) || (echo "❌ Tag push failed"; exit 1)
	@echo "✅ Tag $(VERSION) created and pushed"

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	@rm -rf cue.mod/pkg
	@echo "✅ Cleaned"

# Show module info
info:
	@echo "=== Core Module Information ==="
	@echo "Module:          $(MODULE)"
	@echo "Version:         $(VERSION)"
	@echo "Local Registry:  $(LOCAL_IMAGE):$(VERSION)"
	@echo "Remote Registry: $(REMOTE_IMAGE):$(VERSION)"
	@echo ""
	@echo "Module file:"
	@cat cue.mod/module.cue

# Show help
help:
	@echo "Core Module Makefile - CUE Module Publishing"
	@echo ""
	@echo "Targets:"
	@echo "  validate        - Validate all CUE files"
	@echo "  publish-local   - Publish to local OCI registry (localhost:5000)"
	@echo "  publish-remote  - Publish to remote registry (ghcr.io)"
	@echo "  tag             - Create and push git version tag"
	@echo "  info            - Show module information"
	@echo "  clean           - Clean generated files (cue.mod/pkg)"
	@echo "  help            - Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  VERSION         - Module version (default: v0.1.0)"
	@echo "  LOCAL_REGISTRY  - Local registry address (default: localhost:5000)"
	@echo ""
	@echo "Examples:"
	@echo "  make validate"
	@echo "  make publish-local VERSION=v0.1.0"
	@echo "  make publish-remote VERSION=v0.1.0"
	@echo "  make tag VERSION=v0.1.0"
	@echo ""
	@echo "Local Development Workflow:"
	@echo "  1. Start local registry: make -f ../Makefile.registry start"
	@echo "  2. Validate module:      make validate"
	@echo "  3. Publish locally:      make publish-local"
	@echo "  4. Verify:               make -f ../Makefile.registry list"
