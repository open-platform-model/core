# Open Platform Model (OPM) Core

A CUE-based application modeling framework for defining platform-agnostic, composable infrastructure components.

## Overview

OPM provides a declarative model for describing cloud-native applications through reusable components, traits, and resources. It enables platform teams to define standardized abstractions while giving developers flexibility in how they compose and configure applications.

## Core Concepts

- **Components**: Basic building blocks representing workloads (stateless, stateful, daemonSet, task, scheduled-task) or resources
- **Elements**: Reusable capabilities that can be primitive, composite, modifier, or custom types
  - **Traits**: Behavioral aspects like containers, sidecars, or network scopes
  - **Resources**: Infrastructure dependencies like volumes, configmaps, and secrets
- **Scopes**: Logical groupings that apply shared configuration across multiple components
- **Modules**: Complete application definitions combining components, scopes, and configurable values

## Structure

The framework uses CUE's type system to provide strong validation and composition capabilities while maintaining extensibility for platform-specific implementations.

## Documentation

For comprehensive documentation, visit the [Open Platform Model documentation repository](https://github.com/open-platform-model/opm).
