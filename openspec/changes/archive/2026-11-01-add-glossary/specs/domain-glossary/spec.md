## ADDED Requirements

### Requirement: The repo keeps a root glossary of its domain terms

The repo MUST hold a `GLOSSARY.md` at its root with a context heading and a `## Language` section. Each term MUST be bold, have a definition of one or two sentences, and carry an `_Avoid_` line where loose synonyms exist. Each term MUST be specific to the core schema and MUST be backed by `SPEC.md` or by a file under `src/`.

#### Scenario: A reader looks up a schema term

- **WHEN** a reader opens `GLOSSARY.md` and looks for `#ModuleInstance`
- **THEN** the file defines the term in one or two sentences and lists the loose words to avoid

### Requirement: The agent entry points route to the glossary

`AGENTS.md` and `CONTEXT.md` MUST each point to `GLOSSARY.md` exactly once.

#### Scenario: An agent reads the entry points

- **WHEN** an agent reads `AGENTS.md` and `CONTEXT.md`
- **THEN** each file names `GLOSSARY.md` once as the home of the repo's domain terms
