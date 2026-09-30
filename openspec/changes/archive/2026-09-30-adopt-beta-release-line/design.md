## Context

See proposal.md for why. Current state on `origin/main` 748dfc7:

- `release-please-config.json` package `.`: `versioning: "prerelease"`, `prerelease: true`, `prerelease-type: "alpha"`. `.release-please-manifest.json` holds `2.0.0-alpha.13`, the newest tag. Every commit since is hidden-type (`docs(site)` x2, `chore(openspec)`), so no release PR is open.
- The alpha rule is stated in: `openspec/config.yaml` Principle IV (~54-63), the commit conventions (~131) and the proposal rules (~164); `AGENTS.md` branch table (~104), the prerelease rule (~119), the module-root paragraph (~146) and the commit table (~189); `README.md` (~7, ~13, ~31, ~40); `docs/publishing.md` (~5, ~7, ~53, ~66, ~72, ~79, ~106, ~124); `docs/site/concepts/versions.md` (the planning comments at ~13, ~29, ~93); and comments in `Taskfile.yml` (~110), `.tasks/branch-tag.sh` (~78-80, ~98) and `.github/workflows/release.yml` (~88).
- Three of those sites state the pre-beta major rule without the word `alpha`, so an alpha-only grep misses them: `openspec/config.yaml` ~54-55 and `AGENTS.md` ~146 ("A breaking schema revision bumps the module major"), `README.md` ~13 (the same sentence), and the first sentence of the `versions.md` "The core schema major" comment ("a breaking schema revision moves the major"). Each would contradict the beta promise if left.
- No logic reads the prerelease label: `release.yml` publishes whatever `version` release-please outputs, and `.tasks/branch-tag.sh` strips the prerelease before sorting tag bases.
- Core's `task publish` runs `cue mod publish {{.VERSION}}` with no registry mapping of its own, so it publishes wherever the caller's `CUE_REGISTRY` points; with the workspace's canonical mapping that is GHCR. Its documented example (`VERSION=v1.0.0-alpha.1`) is inert today only because its major disagrees with `@v2`.
- `task check` cannot pass in a worktree: `generate:index:check` compares `src/INDEX.md` line 1 (`# core — Definition Index`) with a title built from the directory name. Measured on the untouched worktree: that is the only failure.

## Goals / Non-Goals

**Goals:**

- One PR whose squash commit is the core beta carrier: it flips the config and forces `2.0.0-beta.1`.
- Every normative and user-facing statement of the release line says beta, in the canonical promise wording, with nothing left claiming alpha is current and nothing left sanctioning a major crossing during beta.

**Non-Goals:**

- Any `src/` edit. No `src/*.cue` file changes, `src/cue.mod/module.cue` included: its "Was: ... ships on the v2.0.0-alpha.N prerelease line" note records how the `@v1` to `@v2` bump happened, which is history, and the constitution forbids growing `Was:` comments. The published module is therefore byte-identical to `v2.0.0-alpha.13`, and no `SPEC.md` co-update or `Spec-Impact: none` escape applies.
- Historical text: `CHANGELOG.md`, `openspec/changes/archive/**`, the partial-tag requirement in `schema-release`, struck-through or "retired in `v2.0.0-alpha.N`" passages, and version facts that name a past alpha (for example `docs/site/concepts/platforms-and-catalogs.md` "Before core v2.0.0-alpha.13").
- `v1alpha1`/`v1beta1` contract levels (`#APIVersionType`), which are a different ladder.
- Enhancement 0021's verbatim copies of the rule text; the supervisor re-copies them after merge.
- Making core's `task publish` force a local-registry mapping. It is a real gap (root `AGENTS.md` says every publish task does this), but a tooling change, not a release-line change; this change only keeps the documented example inert.

## Decisions

### D1. Force the first beta with a footer in the squash message, not config

The version crosses only through `Release-As: 2.0.0-beta.1` in the final footer block of the squash commit on `main`. The supervisor writes that message at merge time: the subject is the 4.6 subject plus ` (#N)`, and the body is 4.6 from its third line on. This change's last branch commit carries the 4.6 message so the PR's mention-guard scans it first. No `release-as` config key (it stays in force for every later release; cli ed9774e and catalog_opm bc778ca show the damage), no manifest edit.

Alternatives: flip the config only (release-please keeps the `alpha` label; with only hidden commits it opens no PR at all); a releasable `fix:` or `feat:` carrier (misclassifies a byte-identical schema, Principle I rule of thumb). A hidden-type `chore(release)` carrier with the footer opens the release PR: supervisor dry-run against release-please 17.3.0 and 17.6.0, and the `d8db7fe` precedent (`chore: release 1.1.0` with `Release-As: 1.1.0`). The reviewer's parse of the 4.6 message, with and without ` (#N)`, gives type `chore`, `Release-As` `2.0.0-beta.1`, not breaking.

### D2. The carrier commit is the last commit, and it also archives

Sections 1 to 3 are hidden-type text commits. Section 4 flips `prerelease-type`, sweeps, verifies, archives the change (which syncs the delta into `openspec/specs/schema-release/spec.md`) and lands all of it as one commit whose message is the carrier message. The flip therefore lands in the commit whose message names it. The archive belongs in this PR because the spec it syncs describes the rule the carrier executes; archiving afterwards would leave `main` with an active change for a release already cut. A residual fix found by the 4.2 sweep or the 4.4 verify rides the carrier commit too (4.7 stages it and lists it), so nothing lands after the carrier.

### D3. Type-agnostic spec, canonical promise everywhere else, no major crossing before GA

The `schema-release` delta writes the type as `<type>` and names `beta` once as the current value, so the next type change (or GA) edits config and prose, not requirements. Every other file states the canonical promise, adapted to its grammar but keeping its meaning:

> From its first beta, the line is on the path to GA. A breaking change is still allowed during beta, but only as a `feat!` commit whose `BREAKING CHANGE:` footer is the migration note the CHANGELOG shows. It advances the `-beta.N` counter and never moves the module path to a new major. Stable lines (`opmodel.dev/catalogs/opm@v4` and the module fleets) keep the normal SemVer rule: a break is a new major. A core beta break that would force a `catalogs/opm` major needs owner sign-off. GA drops the suffix: `prerelease: false` plus a visible carrier commit.

"Never moves the module path" is absolute (beta canon, owner decision 2): no `opmodel.dev/core@v3` before GA, whatever the break. The existing requirement "A pre-stable break defaults to advancing the prerelease, and crossing a major is a separate decision" is therefore renamed (a `RENAMED` delta) to "A break on a prerelease line advances the prerelease, and only a stable line crosses a major", because "defaults" would imply an exception. Its body forbids a `module:` line change or a new-major `Release-As:` during beta and scopes the crossing mechanics (same-commit `module:` line plus `Release-As:`) to a stable line after GA. All four live scenario headings are kept verbatim; "An unabsorbable break bumps the module major" is re-scoped by its WHEN clause to a stable line after GA. Added scenarios: a break during beta does not move the module path; a `module:` line change during beta is refused; a break without a migration note is refused; the `catalogs/opm` sign-off. The spec's Purpose line (which the archive does not touch) is updated by hand in 4.5 to match.

GA is worded one way everywhere (the canon's): `prerelease: false` plus a visible carrier commit, which is either a releasable type or a `Release-As: X.0.0` footer. It is not "forced": with `prerelease: false`, release-please proposes `X.0.0` from any releasable commit (reviewer, `prerelease.ts`). Only a prerelease type change needs the force.

### D4. Say what the prerelease line does to `feat:` and `fix:`

On a prerelease line, `feat:` and `fix:` advance `-beta.N` like `feat!:` (release-please `prerelease` versioning). The AGENTS.md and config.yaml commit tables say "minor" and "patch", which holds only after GA. The rewritten prerelease rule (AGENTS.md ~119, config.yaml ~131) says so in one sentence instead of rewriting the tables.

### D5. The edits

`<wt>` is the worktree root. Find each edit by its text; line numbers are approximate. Nothing under `src/` is edited.

| File | Edit |
| --- | --- |
| `openspec/config.yaml` Principle IV, bullet "A breaking schema revision bumps the module major..." | "A new major (`@v2` → `@v3`) is the only way the module path changes, and it never adds a sibling package or a versioned subdirectory. A major is crossed only after GA; during beta a break advances `-beta.N` instead (below)." |
| same, bullet "`@v2` currently ships `v2.0.0-alpha.N` prereleases..." | Replace with: `@v2` ships `v2.0.0-beta.N` prereleases, followed by the D3 promise, then "Say so explicitly in the proposal when a change relies on the beta break licence." |
| same, bullet "Crossing a major is a deliberate..." | "Crossing a major is a stable-line act, taken only after GA and never implied by a break; during beta the `module:` line does not change. After GA it edits `src/cue.mod/module.cue`'s `module:` line and forces the new major's first version with a `Release-As:` footer in the final message of the SAME commit — `cue mod publish` rejects..." (rest of the bullet kept: the rejection reason and the import-rewrite cost). No `X.0.0-beta.1` example. |
| same, new bullet after it | "Changing the prerelease type is forced by a `Release-As: X.0.0-<type>.1` footer in the final commit message on `main`; flipping `prerelease-type` alone cuts nothing. GA drops the suffix: `prerelease: false` plus a visible carrier commit (a releasable type, or a `Release-As: X.0.0` footer). Never add a `release-as` key to `release-please-config.json`, and never hand-edit `.release-please-manifest.json`." |
| same, Commit Conventions `feat!:` bullet | "(advances `-alpha.N` on `@v2`)" becomes "(advances `-beta.N` on `@v2`; its `BREAKING CHANGE:` footer is the migration note)"; add a bullet: "While `@v2` is a prerelease, `feat:` and `fix:` also advance `-beta.N`; minor and patch apply from GA." |
| same, `rules.proposal` "whether it relies on `@v2` still being in prerelease (Principle IV)" | "whether it relies on the `@v2` beta break licence (Principle IV), and, for a break, whether it would force a `catalogs/opm` major (owner sign-off)." |
| `AGENTS.md` branch table, `main` row | "v2.0.0-alpha.N prereleases → stable v2" becomes "v2.0.0-beta.N prereleases → stable v2". |
| `AGENTS.md` Repository Rules bullet "The CUE module is on major `@v2`, currently shipping `v2.0.0-alpha.N`..." | Rewrite: `v2.0.0-beta.N`; `prerelease-type: "beta"`; the D3 promise; the D4 sentence; "during beta the line never crosses a major; after GA, crossing a major edits the `module:` line and forces the version with a `Release-As:` footer in the same commit"; the type-change and GA rule from the config.yaml bullet above; drop "A future stable cut drops the `-alpha` suffix" (the GA clause replaces it). |
| `AGENTS.md` ~146 module-root paragraph, "A breaking schema revision bumps the module major (e.g. `@v2` → `@v3`); it does not add a sibling package." | "A new major (e.g. `@v2` → `@v3`) is the only way the module path changes, and it never adds a sibling package; it is taken only after GA, and during beta a break advances `-beta.N` instead." |
| `AGENTS.md` commit table `feat!:` row | "prerelease (advances `-alpha.N` on `@v2`)" becomes "prerelease (advances `-beta.N` on `@v2`)"; "Use for" gains "; the `BREAKING CHANGE:` footer is the migration note". |
| `README.md` ~7 | `v2.0.0-beta.N` prereleases plus a one-sentence promise ("on the path to GA; a break lands only as a `feat!` whose `BREAKING CHANGE:` footer is the migration note, and never moves the module path"). "The `@v1` line is retired at `v1.1.0-alpha.1`" becomes "The `@v1` line lives on, stable at `v1.1.0`, on the protected `v1` maintenance branch" (tag `v1.1.0` exists; AGENTS.md already says this). |
| `README.md` ~13, "A breaking schema revision bumps the module major (e.g. `@v2` → `@v3`) rather than adding a sibling package." | "A new major (e.g. `@v2` → `@v3`), taken only after GA, is the only way the module path changes; it never adds a sibling package." |
| `README.md` ~31 | `v2.0.0-alpha.N` becomes `v2.0.0-beta.N`. |
| `README.md` ~40 | `task publish VERSION=v1.0.0-alpha.1   # publish the CUE module (CI does this on tag)` becomes `task publish VERSION=vX.Y.Z   # CI publishes releases; locally, only against a local registry`. Never a real upcoming version (`task publish` publishes wherever `CUE_REGISTRY` points). |
| `docs/publishing.md` ~5 note | `v2.0.0-beta.N` (beta since `v2.0.0-beta.1`, alpha before); `@v1` "lives on, stable at `v1.1.0`"; "`-alpha` release tags" becomes "prerelease tags"; fix the dead anchor `#pre-stable-why-branch-builds-carry-a-leading-0` to `#why-branch-builds-carry-a-leading-0`. |
| `docs/publishing.md` ~7 | "and it is why the alpha line exists to absorb breaks that do not need one" becomes "and it is why the prerelease line absorbs breaks instead: from its first beta a break advances `-beta.N` and never moves the module path, and a major is crossed only after GA". |
| `docs/publishing.md` ~53 table, `dev` row | "from any future `rc`/`beta` pre-release schemes" becomes "from the alpha, beta or rc release channels". |
| `docs/publishing.md` ~66 point 1 | Re-state on the live line: "`@v2` has only prereleases today (alpha and beta), so there is nothing for `@v2` to prefer and it must take the highest prerelease. `v2.0.0-dev.*` would beat every `v2.0.0-beta.N`, because prerelease identifiers compare lexically and `beta` < `dev`. ... `v2.1.0-dev.*` beats `v2.0.0-beta.3` on the base version alone". |
| `docs/publishing.md` ~72 | `v2.0.0-0.dev.1785961206.g6b10e87  <  v2.0.0-alpha.1  <  v2.0.0-beta.1  <  v2.0.0`. |
| `docs/publishing.md` ~79 | "`@v1.0` resolves to the newest alpha" becomes "`@v2.0` resolves to the newest prerelease", and "`@v1`" becomes "`@v2`" in the same paragraph. |
| `docs/publishing.md` ~106 | Replace the claim with: prereleases are excluded from `@latest` and major-only queries only when that major has a stable release; a major with none (`@v2` today) resolves to its highest prerelease. Evidence: a scratch module on cue v0.17.1 resolved `opmodel.dev/core@v2` to `v2.0.0-alpha.13` while `@latest` picked `v1.1.0` (2026-09-30). Leave the CUE 0.16.1 table, which shows the stable case. |
| `docs/publishing.md` ~124 | `v: "v2.0.0-alpha.1"` becomes `v: "v2.0.0-beta.1"`. Leave ~67, ~77 and ~118 (historical). |
| `docs/site/concepts/versions.md` ~13 comment | `opmodel.dev/core@v2` at `v2.0.0-alpha.10` becomes `v2.0.0-beta.1`. |
| same, "The core schema major" comment | First sentence: "Core versions like any CUE module: a breaking schema revision moves the major (it has gone from `@v0` to `@v1` to `@v2`)..." becomes "Core has moved its major between lines (`@v0` to `@v1` to `@v2`), and consumers moved by rewriting the import; from its first beta a break advances `-beta.N` instead, and a major is crossed only after GA." Then "The `@v2` line ships `v2.0.0-alpha.N` prereleases and has taken breaking changes inside that line (alpha.7 removed `#Subscription`), so it promises nothing yet." becomes: the line ships `v2.0.0-beta.N`; it took breaking changes during alpha (alpha.7 removed `#Subscription`); from its first beta it is on the path to GA, and a break is a `feat!` whose `BREAKING CHANGE:` footer is the migration note in the CHANGELOG, advancing `-beta.N` without moving the module path; GA drops the suffix. |
| same, "convention:" comment | "Core moving its major on a breaking change is its maintainers' policy, and the `@v2` alpha line has taken breaking changes without one." becomes: core moving its major is its maintainers' policy, taken only after GA; on the `@v2` beta line a break advances `-beta.N` and carries a migration note in the CHANGELOG instead, and the alpha line took breaking changes without one. Front matter and page structure unchanged (workspace `STYLE.md` Site Pages). |
| `Taskfile.yml` `publish` desc | `(e.g. task publish VERSION=v1.0.0-alpha.1)` becomes `(e.g. task publish VERSION=vX.Y.Z; CI publishes releases, run locally only against a local registry)`. No `: ` inside the plain scalar. |
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

### May the beta line cross a major?

**Context**: `schema-release` has always allowed a separately decided major crossing on a pre-stable line; the beta promise says a beta break never moves the module path. Enhancement 0013 (`#Secret`, a real break) is due during beta.
**Explored**: Beta canon, owner decision 2 (2026-09-30, final): a beta break "advances the `-beta.N` counter and never moves the module path to a new major". Stable lines keep "a break is a new major".
**Decision**: No major crossing before GA (D3). The crossing mechanics stay in the spec, scoped to a stable line after GA.
**Rationale**: The promise is what downstream betas copy; a sanctioned exception would let a proposal cite the spec to justify `opmodel.dev/core@v3` during beta.

## Risks / Trade-offs

- [The squash loses the footer: a GitHub multi-commit default message, or a body line starting with `word(`, which makes release-please drop the commit] → The last branch commit carries the carrier message (section 4); the supervisor squashes with that message (subject plus ` (#N)`), parses it with release-please's parser before merge, and after merge expects `chore(main): release 2.0.0-beta.1` within one run. Fallback: `BEGIN_COMMIT_OVERRIDE` in the merged PR body and a re-run.
- [A releasable commit lands on core `main` before this merges] → The footer still forces `2.0.0-beta.1`, and that commit ships inside beta.1. The supervisor holds other core merges until G1 so beta.1 equals alpha.13 content.
- [The failed publish after tagging burns `2.0.0-beta.1`] → No hand tagging or publishing; the target moves to `2.0.0-beta.2` and downstream follows (canon default).
- [Someone runs the documented `task publish` with the canonical GHCR mapping] → The example names no real version (`vX.Y.Z`), so a copy-paste fails instead of publishing the release before CI. The task itself still does not force a local registry (Non-Goals; recorded as a follow-up).
- [Promise text drifts from enhancement 0021's verbatim copies] → The supervisor re-copies them after merge (C0b').

## Migration Plan

Merge the PR with the carrier message; merge the release PR `chore(main): release 2.0.0-beta.1` once its title names that version; `publish-cue` pushes `v2.0.0-beta.1`; G1 is confirmed by resolving it from a scratch module and evaluating a minimal `#Module` (`schema-release` "The published artifact is verified to resolve"). Rollback: none needed for consumers (alpha pins keep resolving); a wrong release PR is closed unmerged and the footer re-issued through `BEGIN_COMMIT_OVERRIDE`.

## Open Questions

- None blocking. Follow-up outside this change: core's `task publish` should force a local-registry mapping in-script, as root `AGENTS.md` says every publish task does.
