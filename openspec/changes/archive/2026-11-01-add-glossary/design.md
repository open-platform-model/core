## Context

The workspace docs-form rule allows `GLOSSARY.md` as a stable root name that `AGENTS.md` and `CONTEXT.md` may point to. The glossary form is: a context heading, a short description, and a `## Language` section with a bold term, a short definition and an `_Avoid_` line.

## Decisions

- Terms come from `SPEC.md` and `src/`. A term that neither file backs is left out.
- Terms are grouped under Primitives, Constructs, Adapters and gates, and Naming and layering, following the category split of `SPEC.md` section 1.
- `AGENTS.md` names the file in its Layout block, and `CONTEXT.md` gets one routing row. No other line changes.

## Risks

A term can drift from the schema. `SPEC.md` stays the normative text; when the glossary and `SPEC.md` disagree, `SPEC.md` wins.
