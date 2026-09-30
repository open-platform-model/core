## Context

See proposal.md for why. Current state on `origin/main` 748dfc7:

- `release-please-config.json` package `.`: `versioning: "prerelease"`, `prerelease: true`, `prerelease-type: "alpha"`. `.release-please-manifest.json` holds `2.0.0-alpha.13`, the newest tag. Every commit since is hidden-type (`docs(site)` x2, `chore(openspec)`), so no release PR is open.
- The alpha rule is stated in: `openspec/config.yaml` Principle IV (~56-63), the commit conventions (~131) and the proposal rules (~164); `AGENTS.md` branch table (~104), the prerelease rule (~119) and the commit table (~189); `README.md` (~7, ~31, ~40); `docs/publishing.md` (~5, ~7, ~66, ~72, ~79, ~106, ~124); `docs/site/concepts/versions.md` (the planning comments at ~13, ~29, ~93); and comments in `Taskfile.yml` (~110), `src/cue.mod/module.cue` (~5), `.tasks/branch-tag.sh` (~78-80, ~98) and `.github/workflows/release.yml` (~88).
- No logic reads the prerelease label: `release.yml` publishes whatever `version` release-please outputs, and `.tasks/branch-tag.sh` strips the prerelease before sorting tag bases.
- `task check` cannot pass in a worktree: `generate:index:check` compares `src/INDEX.md` line 1 (`# core — Definition Index`) with a title built from the directory name. Measured on the untouched worktree: that is the only failure.

## Goals / Non-Goals

**Goals:**

- One PR whose squash commit is the core beta carrier: it flips the config and forces `2.0.0-beta.1`.
- Every normative and user-facing statement of the release line says beta, in the canonical promise wording, with nothing left claiming alpha is current.

**Non-Goals:**

- Any `src/*.cue` schema change. `src/cue.mod/module.cue` changes one comment line only.
- Historical text: `CHANGELOG.md`, `openspec/changes/archive/**`, the partial-tag requirement in `schema-release`, struck-through or "retired in `v2.0.0-alpha.N`" passages, and version facts that name a past alpha (for example `docs/site/concepts/platforms-and-catalogs.md` "Before core v2.0.0-alpha.13").
- `v1alpha1`/`v1beta1` contract levels (`#APIVersionType`), which are a different ladder.
- Enhancement 0021's verbatim copies of the rule text; the supervisor re-copies them after merge.

## Decisions

### D1. Force the first beta with a footer in the squash message, not config

The version crosses only through `Release-As: 2.0.0-beta.1` in the final footer block of the squash commit on `main`. The supervisor writes that message at merge time; this change's last branch commit carries the identical message so the PR's mention-guard scans it first. No `release-as` config key (it stays in force for every later release; cli ed9774e and catalog_opm bc778ca show the damage), no manifest edit.

Alternatives: flip the config only (release-please keeps the `alpha` label; with only hidden commits it opens no PR at all); a releasable `fix:` or `feat:` carrier (misclassifies a byte-identical schema, Principle I rule of thumb). A hidden-type `chore(release)` carrier with the footer opens the release PR: supervisor dry-run against release-please 17.3.0 and 17.6.0, and the `d8db7fe` precedent (`chore: release 1.1.0` with `Release-As: 1.1.0`).

### D2. The carrier commit is the last commit, and it also archives

Sections 1 to 3 are hidden-type text commits. Section 4 flips `prerelease-type`, verifies, archives the change (which syncs the delta into `openspec/specs/schema-release/spec.md`) and lands all of it as one commit whose message is the carrier message. The flip therefore lands in the commit whose message names it. The archive belongs in this PR because the spec it syncs describes the rule the carrier executes; archiving afterwards would leave `main` with an active change for a release already cut.

### D3. Type-agnostic spec, canonical promise everywhere else

The `schema-release` delta writes the type as `<type>` and names `beta` once as the current value, so the next type change (or GA) edits config and prose, not requirements. Every other file states the canonical promise, adapted to its grammar but keeping its meaning:

> From its first beta, the line is on the path to GA. A breaking change is still allowed during beta, but only as a `feat!` commit whose `BREAKING CHANGE:` footer is the migration note the CHANGELOG shows. It advances the `-beta.N` counter and never moves the module path to a new major. Stable lines (`opmodel.dev/catalogs/opm@v4` and the module fleets) keep the normal SemVer rule: a break is a new major. A core beta break that would force a `catalogs/opm` major needs owner sign-off. GA drops the suffix: `prerelease: false` plus a visible carrier commit.

The existing requirement "A pre-stable break defaults to advancing the prerelease, and crossing a major is a separate decision" keeps its name and all four scenario headings. Its "MUST bump the module major" clause becomes the case for a separately decided crossing, because the promise says a beta break never moves the path by itself. Two scenarios are added for the promise's new edges (no path move without a decision; the `catalogs/opm` sign-off) and one for the rejecting direction (a break without a migration note).

### D4. Say what the prerelease line does to `feat:` and `fix:`

On a prerelease line, `feat:` and `fix:` advance `-beta.N` like `feat!:` (release-please `prerelease` versioning). The AGENTS.md and config.yaml commit tables say "minor" and "patch", which holds only after GA. The rewritten prerelease rule (AGENTS.md ~119, config.yaml ~131) says so in one sentence instead of rewriting the tables.

### D5. The edits

`<wt>` is the worktree root. Find each edit by its text; line numbers are approximate.

| File | Edit |
| --- | --- |
| `openspec/config.yaml` Principle IV, bullet "`@v2` currently ships `v2.0.0-alpha.N` prereleases..." | Replace with: `@v2` ships `v2.0.0-beta.N` prereleases, followed by the D3 promise, then "Say so explicitly in the proposal when a change relies on the beta break licence." |
| same, bullet "Crossing a major is a deliberate..." | "an alpha break" becomes "a beta break"; `Release-As: X.0.0-alpha.1` becomes `Release-As: X.0.0-beta.1`, "footer in the final message of the SAME commit". |
| same, new bullet after it | "Changing the prerelease type, or going GA, is forced the same way: a `Release-As:` footer (`X.0.0-<type>.1`, or `X.0.0` for GA with `prerelease: false`) in the final commit message on `main`. Flipping `prerelease-type` alone cuts nothing; never add a `release-as` key to `release-please-config.json` and never hand-edit `.release-please-manifest.json`." |
| same, Commit Conventions `feat!:` bullet | "(advances `-alpha.N` on `@v2`)" becomes "(advances `-beta.N` on `@v2`; its `BREAKING CHANGE:` footer is the migration note)"; add a bullet: "While `@v2` is a prerelease, `feat:` and `fix:` also advance `-beta.N`; minor and patch apply from GA." |
| same, `rules.proposal` "whether it relies on `@v2` still being in prerelease (Principle IV)" | "whether it relies on the `@v2` beta break licence (Principle IV), and, for a break, whether it would force a `catalogs/opm` major (owner sign-off)." |
| `AGENTS.md` branch table, `main` row | "v2.0.0-alpha.N prereleases → stable v2" becomes "v2.0.0-beta.N prereleases → stable v2". |
| `AGENTS.md` Repository Rules bullet "The CUE module is on major `@v2`, currently shipping `v2.0.0-alpha.N`..." | Rewrite: `v2.0.0-beta.N`; `prerelease-type: "beta"`; the D3 promise; the D4 sentence; crossing a major uses `Release-As: X.0.0-beta.1` in the same commit; the type-change/GA forcing rule from the config.yaml bullet above; drop "A future stable cut drops the `-alpha` suffix" (the GA clause replaces it). |
| `AGENTS.md` commit table `feat!:` row | "prerelease (advances `-alpha.N` on `@v2`)" becomes "prerelease (advances `-beta.N` on `@v2`)"; "Use for" gains "; the `BREAKING CHANGE:` footer is the migration note". |
| `README.md` ~7 | `v2.0.0-beta.N` prereleases plus a one-sentence promise ("on the path to GA; a break lands only as a `feat!` whose `BREAKING CHANGE:` footer is the migration note, and never moves the module path"). "The `@v1` line is retired at `v1.1.0-alpha.1`" becomes "The `@v1` line lives on, stable at `v1.1.0`, on the protected `v1` maintenance branch" (tag `v1.1.0` exists; AGENTS.md already says this). |
| `README.md` ~31 | `v2.0.0-alpha.N` becomes `v2.0.0-beta.N`. |
| `README.md` ~40 | `task publish VERSION=v1.0.0-alpha.1` becomes `task publish VERSION=v2.0.0-beta.1`. |
| `docs/publishing.md` ~5 note | `v2.0.0-beta.N` (beta since `v2.0.0-beta.1`, alpha before); `@v1` "lives on, stable at `v1.1.0`"; "`-alpha` release tags" becomes "prerelease tags"; fix the dead anchor `#pre-stable-why-branch-builds-carry-a-leading-0` to `#why-branch-builds-carry-a-leading-0`. |
| `docs/publishing.md` ~7 | "the alpha line exists to absorb breaks that do not need one" becomes "the prerelease line exists to absorb breaks that do not need one". |
| `docs/publishing.md` ~66 point 1 | Re-state on the live line: "`@v2` ships only `v2.0.0-beta.N` prereleases today, so there is nothing for `@v2` to prefer... `v2.0.0-dev.*` would beat every `v2.0.0-beta.N`, because prerelease identifiers compare lexically and `beta` < `dev`. ... `v2.1.0-dev.*` beats `v2.0.0-beta.3` on the base version alone". |
| `docs/publishing.md` ~72 | `v2.0.0-0.dev.1785961206.g6b10e87  <  v2.0.0-alpha.1  <  v2.0.0-beta.1  <  v2.0.0`. |
| `docs/publishing.md` ~79 | "`@v1.0` resolves to the newest alpha" becomes "`@v2.0` resolves to the newest prerelease", and "`@v1`" becomes "`@v2`" in the same paragraph. |
| `docs/publishing.md` ~106 | Replace the claim with: prereleases are excluded from `@latest` and major-only queries only when that major has a stable release; a major with none (`@v2` today) resolves to its highest prerelease. Evidence: a scratch module on cue v0.17.1 resolved `opmodel.dev/core@v2` to `v2.0.0-alpha.13` while `@latest` picked `v1.1.0` (2026-09-30). Leave the CUE 0.16.1 table, which shows the stable case. |
| `docs/publishing.md` ~124 | `v: "v2.0.0-alpha.1"` becomes `v: "v2.0.0-beta.1"`. Leave ~67, ~77 and ~118 (historical). |
| `docs/site/concepts/versions.md` ~13 comment | `opmodel.dev/core@v2` at `v2.0.0-alpha.10` becomes `v2.0.0-beta.1`. |
| same, "The core schema major" comment | "The `@v2` line ships `v2.0.0-alpha.N` prereleases and has taken breaking changes inside that line (alpha.7 removed `#Subscription`), so it promises nothing yet." becomes: the line ships `v2.0.0-beta.N`; it took breaking changes during alpha (alpha.7 removed `#Subscription`); from its first beta it is on the path to GA, and a break is a `feat!` whose `BREAKING CHANGE:` footer is the migration note in the CHANGELOG, advancing `-beta.N` without moving the module path; GA drops the suffix. |
| same, "convention:" comment | "Core moving its major on a breaking change is its maintainers' policy, and the `@v2` alpha line has taken breaking changes without one." becomes: core moving its major is its maintainers' policy; on the `@v2` beta line a break advances `-beta.N` and carries a migration note in the CHANGELOG instead, and the alpha line took breaking changes without one. Front matter and page structure unchanged (workspace `STYLE.md` Site Pages). |
| `Taskfile.yml` `publish` desc | `VERSION=v1.0.0-alpha.1` becomes `VERSION=v2.0.0-beta.1`. |
| `src/cue.mod/module.cue` comment | "ships on the v2.0.0-alpha.N prerelease line" becomes "ships on the v2.0.0-beta.N prerelease line, alpha until v2.0.0-alpha.13". |
| `.tasks/branch-tag.sh` ~78-80 | "(a long `-alpha.N` line, which is where this module lives)" becomes "(a long prerelease line such as `-beta.N`, which is where this module lives)"; the example `1.0.0-alpha.3` becomes `1.0.0-beta.3`. ~98: add `  <  v1.0.0-beta.1` between the alpha and stable terms. Leave ~83 (historical). |
| `.github/workflows/release.yml` ~88 | "X.Y.Z or X.Y.Z-alpha.N" becomes "X.Y.Z or X.Y.Z-<type>.N, e.g. 2.0.0-beta.1". |
| `release-please-config.json` | `"prerelease-type": "alpha"` becomes `"prerelease-type": "beta"`. Nothing else. |

## Research & Decisions

### Does a `prerelease-type` flip cut the beta on its own?

**Context**: The whole cutover depends on core `v2.0.0-beta.1` appearing (G1).
**Explored**: Supervisor research (`strategy.md` fact 1, `review.md` release-please dry-runs on 17.3.0 and 17.6.0): `bumpPrerelease` keeps the existing label when the type changes (upstream issue 2447); a hidden-type-only history opens no release PR; a hidden-type commit whose final footer is `Release-As:` does open one. Core's own precedent `d8db7fe` (`chore: release 1.1.0`, `Release-As: 1.1.0`).
**Decision**: D1: a `chore(release)` squash carrier with `Release-As: 2.0.0-beta.1`.
**Rationale**: The only path that is both verified and leaves the config free of a sticky override.

### Does `@latest` exclude prereleases?

**Context**: `docs/publishing.md` ~106 says prereleases are excluded from `@latest` and major-only queries.
**Explored**: Scratch module, cue v0.17.1, live GHCR, 2026-09-30: `cue mod get opmodel.dev/core@v2` pinned `v2.0.0-alpha.13`; `cue mod get opmodel.dev/core@latest` pinned `v1.1.0`.
**Decision**: Correct the sentence: exclusion holds only when the queried major has a stable release.
**Rationale**: `@v2` has no stable, so every `@v2` query today selects the highest prerelease, which after this change is beta.

### Is the move monotonic for consumers?

**Context**: Consumers resolving `@v2` unpinned must not go backwards.
**Explored**: SemVer 2.0 §11.4.3 compares `alpha` < `beta` lexically on the same base; `.tasks/branch-tag.sh` strips prereleases before sorting bases, so branch builds stay `v2.0.0-0.dev.*`, below every named channel.
**Decision**: No tooling change beyond comments.
**Rationale**: `2.0.0-alpha.13` < `2.0.0-beta.1`; explicit alpha pins keep resolving because tags are immutable.

## Risks / Trade-offs

- [The squash loses the footer: a GitHub multi-commit default message, or a body line starting with `word(`, which makes release-please drop the commit] → The last branch commit carries the exact carrier message (section 4); the supervisor squashes with that message, parses it with release-please's parser before merge, and after merge expects `chore(main): release 2.0.0-beta.1` within one run. Fallback: `BEGIN_COMMIT_OVERRIDE` in the merged PR body and a re-run.
- [CI co-update gate fails the PR because `src/cue.mod/module.cue` changes without `SPEC.md`] → The PR body carries `Spec-Impact: none` with the reason (comment-only edit); the commit uses `SPEC_IMPACT=none`.
- [A releasable commit lands on core `main` before this merges] → The footer still forces `2.0.0-beta.1`, and that commit ships inside beta.1. The supervisor holds other core merges until G1 so beta.1 equals alpha.13 content.
- [The failed publish after tagging burns `2.0.0-beta.1`] → No hand tagging or publishing; the target moves to `2.0.0-beta.2` and downstream follows (canon default).
- [Promise text drifts from enhancement 0021's verbatim copies] → The supervisor re-copies them after merge (C0b').

## Migration Plan

Merge the PR with the carrier message; merge the release PR `chore(main): release 2.0.0-beta.1` once its title names that version; `publish-cue` pushes `v2.0.0-beta.1`; G1 is confirmed by resolving it from a scratch module and evaluating a minimal `#Module` (`schema-release` "The published artifact is verified to resolve"). Rollback: none needed for consumers (alpha pins keep resolving); a wrong release PR is closed unmerged and the footer re-issued through `BEGIN_COMMIT_OVERRIDE`.

## Open Questions

- The promise says a beta break "never moves the module path to a new major", while `schema-release` has always allowed a separately decided major crossing. The delta keeps crossing as an owner decision rather than forbidding it. If the owner means "no `@v3` before GA", the delta's "An unabsorbable break bumps the module major" scenario body needs one more sentence; the tasks do not change.
