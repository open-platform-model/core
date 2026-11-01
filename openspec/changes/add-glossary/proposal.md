## Why

Agents and the owner use loose words for the schema concepts of this repo: "release" for a `#ModuleInstance`, "FQN" for two different keys, "plugin" for a `#ComponentTransformer`. A root `GLOSSARY.md` fixes one word per concept, and the architecture and domain-model skills read it.

## What Changes

- Add `GLOSSARY.md` at the repo root with the domain terms of the core schema.
- Route to it once from `AGENTS.md` and once from `CONTEXT.md`.

## Capabilities

### New Capabilities

- `domain-glossary`: the repo keeps a root glossary of its domain terms, and the agent entry points route to it.

### Modified Capabilities

None.

## Impact

Documentation only. No `*.cue` file changes, so `SPEC.md` does not change and the module publishes nothing new.
