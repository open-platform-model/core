## Context

Design of the store and the citation rule: the enhancements swarm design (part two, sections 6 and 9). This change is core's side of it.

## Decisions

### Rewrite with the tool, then by hand

**Decision**: run `enh cite-rewrite --write` once over the tree, commit its result in separate commits by place (code, live specs, archived changes, docs), then clear the worklist by hand.

**Rationale**: the tool applies one rule everywhere and lists what it cannot rewrite safely. A human cannot apply the same rule to about 650 sites without drift. The commits stay reviewable because each place is one commit.

### Lone `// WHY name:` labels

**Decision**: a label that holds only an id gets its reason in words, merged into the paragraph below it or written new. Never `// WHY name: enhancement NNNN` alone.

**Rationale**: the comment rule forbids a lone id, and a label that restates an id is the same problem with a longer name. The reader needs the reason.

### Breadcrumbs in `SPEC.md`

**Decision**: lines such as "Renamed from `#Old`" keep that phrase and lose only the decision number.

**Rationale**: `.tasks/spec-check.sh` filters lines on "Renamed from". Keeping the phrase leaves the script unchanged.

### `references:` form

**Decision**: `- id: opm-enhancements` with `remote: https://github.com/open-platform-model/enhancements.git`.

**Rationale**: the repository is public, and OpenSpec renders the remote into the clone command it prints when the store is not registered. HTTPS needs no key.

### Skill patches

**Decision**: the two `REPO-LOCAL PATCH` blocks stay in `.claude/skills/` until the owner runs `openspec update`.

**Rationale**: agents do not write under `.claude/`. The rules the blocks carried move to `config.yaml` here, so the blocks are redundant from this change on.

## Risks

- A tool edit that reads wrongly. Mitigation: the author reads a sample before committing, and a reviewer reads a stratified sample.
- A doc comment over six lines after the rewrite. Mitigation: `task docs:check` is part of `task check`.
- `src/INDEX.md` out of date. Mitigation: `task generate:index` runs and `task check` verifies it.
