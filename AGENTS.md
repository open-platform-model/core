# Core repository guide

The OPM core schema, pure CUE, published as `opmodel.dev/core@v2`. Every OPM artifact is typed against
these definitions. Downstream repos (`library`, `cli`, `opm-operator`, `modules`, `catalog_opm`)
consume `core` as a published dependency, never by file path. The repo holds definitions and the
tooling to validate and publish them, and no Go code. The definitions reference on opmodel.dev is
generated from `src/` when the docs bundle is built; nothing generated is committed.

## Branch model

| Branch | Module line | Purpose |
| --- | --- | --- |
| `main` | `opmodel.dev/core@v2` | The living line, `v2.0.0-beta.N` prereleases on the path to stable v2. All new schema work. |
| `v1` | `opmodel.dev/core@v1` | Protected, patch-only maintenance line (`v1.1.x`). The `@v1` path refuses any tag outside major 1 at publish. |

Fixes for consumers that still pin `core@v1` go on `v1`. Never merge `main` into `v1`: the identity
reshape must not leak into the v1 contract. The `v1` branch carries its own copy of this file.

## Repository rules

- This file, `openspec/config.yaml` and `Taskfile.yml` are the authority. There is no
  `CONSTITUTION.md`. If they disagree, `Taskfile.yml` wins on how commands run.
- Cut work into mergeable steps: each ends green under `task check` and closes with its own commit
  (`openspec/config.yaml`). A request that does not cut that way is split first.
- Prefer additive schema changes. The schema is a published contract, so a break in the `core` package
  breaks every consumer.
- A break is allowed in beta only as `feat!` with a `BREAKING CHANGE:` footer, and it advances
  `-beta.N` and never the module path.
- Never run `cue mod publish` against a live registry by hand. CI publishes, so a hand publish makes a
  version the pipeline cannot own.
- Never add a `release-as` key to `release-please-config.json` and never hand-edit
  `.release-please-manifest.json`. Both bypass the release PR.
- Every change to a `*.cue` file co-commits a `SPEC.md` update, because SPEC.md is the published
  specification. Three layers enforce it: the pre-commit hook (`task hooks:install`; bypass with
  `SPEC_IMPACT=none` for formatting-only edits), `task spec:check` inside `task check`, and the CI
  gate (bypass with `Spec-Impact: none` in the PR body). A commit that changes only `docs-kit.cue`
  also takes `SPEC_IMPACT=none`.
- A pin never goes in package `core`. A top-level hidden field there would be evaluated by every
  main-instance build of core, so pins live in `src/pins/`. `task spec:check` refuses one.
- Keep `src/INDEX.md` in sync when a definition or the tree under `src/` changes. `task generate:index`
  regenerates the generated part; the Project Structure tree is hand-maintained. Review the output.
- A new exported definition is placed on a docs page or excluded, with a reason, in `docs-kit.cue`.
  `task docs:bundle:check` fails when it is missing.
- Do not hard-wrap prose in `.md` files.
- Pin `language: version: "v0.17.0"` in `cue.mod/module.cue`. It is the consumer floor, the minimum that
  enables `cue.mod/local-module.cue`. A higher value locks out `v0.17.0` tools for no gain. The
  toolchain is pinned separately (CI `CUE_VERSION`, and `cuelang.org/go` in the consuming Go repos).
- A subagent dispatched here does not load this file. Tell it to read the schema-edit skill.

## Layout

```text
src/            the CUE module root: package core and cue.mod (import path opmodel.dev/core@v2)
src/pins/       test-only package pins; imports core, nothing imports it; task vet builds it
src/INDEX.md    generated definition index (ships inside the CUE module)
docs/           schema design notes
docs/site/      site pages opmodel.dev builds
docs-kit.cue    the core docs bundle: generated reference plus docs/site/
SPEC.md         normative schema specification (definitions, constraints, rationale)
openspec/       OpenSpec specs, active changes and archive
.tasks/         Taskfile script fragments and git hooks
.claude/skills/ repo-local skills (core-schema-edit, openspec-*)
```

All raw `cue` invocations run from `src/`; the Taskfile does this with `dir: src`. A new major would
change the module path, never add a sibling package, and is possible only after GA. The Go schema
fixture harness lives in `library`, not here.

## Commands

| Command                       | Purpose                                                       |
| ---                           | ---                                                           |
| `task fmt` / `task fmt:check` | Format CUE files / verify formatting                          |
| `task vet`                    | Validate the core schema package                              |
| `task generate:index`         | Regenerate `src/INDEX.md`                                     |
| `task generate:index:check`   | Verify `src/INDEX.md` is up to date                           |
| `task spec:check`             | Verify `SPEC.md` inventory matches CUE construct definitions  |
| `task docs:check`             | Fail on doc comments over 6 lines in `src/`                    |
| `task hooks:install`          | Install the pre-commit hook (SPEC.md co-update gate)          |
| `task docs:bundle`            | Build the core docs bundle of the work tree into `out/core/` (a local preview of edge) |
| `task docs:bundle:check`      | Check the docs-kit pins agree, then build and lint the docs bundle without writing `out/` |
| `task docs:pins:check`        | Refuse a docs-kit `publish.yml` ref that names another release than `.opm-docs-version` (offline) |
| `task cascade:wiring:check`   | Run the canonical release-cascade wiring check offline (notify shape, `.github` SHA pin, release key, caches) |
| `task cite-lint`              | Fail on a decision number or a lone enhancement id in a CUE comment (`enh cite-lint` at the commit CI uses; needs Go; not part of `task check`) |
| `task tools:opm-docs`         | Install or reuse `.bin/opm-docs`, the checksum-verified docs-kit release `.opm-docs-version` names |
| `task openspec:install`       | Install the `openspec` CLI at the version `OPENSPEC_VERSION` in `Taskfile.yml` pins (needs npm; install scripts do not run) |
| `task openspec:check`         | Run `openspec validate --all --strict` with the pinned CLI; strict mode fails on the long-requirement warning |
| `task check`                  | fmt check + vet + INDEX freshness + SPEC inventory + doc-comment limit + docs bundle check + cascade wiring check + openspec check |
| `task check:base`             | `task check` without the openspec check; `task publish:branch` runs this one, so the publish job runs no npm code |

For raw `cue` outside `task`, export `CUE_REGISTRY` and `OPM_REGISTRY` as the workspace registry
reference says. `task publish` writes only to the local registry, whatever `CUE_REGISTRY` the shell
exports; it cannot reach GHCR. Run `task check` before you finish.

## Style

- Follow the CUE style used across the workspace catalogs.
- A doc comment is at most 6 lines. A rationale goes in a `// WHY` block above it, separated by one
  blank line. `task docs:check` fails on an over-long doc comment.
- A comment never cites an enhancement as a decision number or a lone id: write the reason, then
  `(enhancement 0011)`.

@CONTEXT.md
