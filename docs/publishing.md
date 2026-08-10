# CUE module publishing — stable and branch tags

This document describes how `opmodel.dev/core` is published to its OCI registry: the stable release flow (already in place) and the branch-build flow (to be implemented). The focus is the *strategy* — tag format, determinism guarantees, and how consumers resolve them. Implementation (Taskfile, CI) follows once this is agreed.

> **Note (enhancement 0010).** The module advanced to `opmodel.dev/core@v2` and now ships its main channel as `v2.0.0-alpha.N` prereleases (release-please `prerelease` mode). The `@v1` line is retired at `v1.1.0-alpha.1`, and the earlier `@v0.x` import paths and the stable-`vX.Y.Z`-vs-branch-`-dev` framing in the worked examples below **predate both cutovers** — they are retained to illustrate the resolution *mechanics*; the concrete version strings are stale. How branch `-dev` tags coexist with `-alpha` release tags once `MAJOR ≥ 1` is resolved in [Pre-stable: why branch builds carry a leading `0`](#pre-stable-why-branch-builds-carry-a-leading-0).
>
> **A major bump is an import rewrite, not a dep bump.** `@v1` and `@v2` are distinct modules to CUE and to the registry: they resolve independently, both remain resolvable forever, and a consumer moves by editing its `import` statements as well as its `deps`. That asymmetry is the whole cost of crossing a major, and it is why the alpha line exists to absorb breaks that do not need one.

## Goal

Every commit that lands on a feature branch, plus every released commit on `main`, produces a versioned, immutable CUE module artifact in the registry. The same Git commit produces the **same tag** whether published from a developer laptop or from CI — no rebuilds, no clock-dependent state.

Consumers (downstream repos, Taskfile automation, ad-hoc `cue mod get`) need a way to pin either:

- the latest **stable** release, or
- the latest **branch publish** (newest commit across any active branch).

Without rebuilding the consumer to learn a specific tag string each time.

## Tag format

Two formats, one per channel.

```text
Stable (main, cut by release-please):
  v<MAJOR>.<MINOR>.<PATCH>
  e.g. v0.4.0

Branch (every commit on a non-main branch):
  v<MAJOR>.<MINOR>.<PATCH>-0.dev.<commit_ct>.g<short_sha>
  e.g. v1.0.0-0.dev.1785961206.g6b10e87
```

The branch build shares the base version of the highest existing release and is
ranked below it by the leading `0.` — see [Why branch builds carry a leading
`0`](#why-branch-builds-carry-a-leading-0).

Where:

| Field | Source | Notes |
| --- | --- | --- |
| `MAJOR` | `cue.mod/module.cue` module suffix (`@v1`) | matches the published module identity |
| `MINOR`/`PATCH` | base version of the highest release tag for this major, stable or prerelease | the branch build shares the release channel's base so it can be ranked *below* it; falls back to `MAJOR.0.0` when the major has no release yet |
| `commit_ct` | `git show -s --format=%ct <SHA>` | committer Unix seconds, baked into the SHA — see Determinism |
| `short_sha` | `git rev-parse --short=7 <SHA>` | seven hex chars, prefixed with `g` |

The `g` prefix on the SHA mirrors `git describe`. It exists for one reason: a 7-char hex SHA can happen to be all digits (roughly 4% of commits). Without the prefix that segment would parse as numeric in SemVer 2.0, and numeric identifiers rank below alphanumeric ones at the same position — flipping sort order based on SHA character class. The `g` makes every SHA segment uniformly alphanumeric, so they always compare lexically.

## Per-segment rationale

| Segment | Could we drop it? | Consequence |
| --- | --- | --- |
| `dev` | no | label distinguishes branch builds from any future `rc`/`beta` pre-release schemes |
| `<commit_ct>` | no | sole source of order; without it `@v<MAJOR>.<NEXT_MINOR>` would resolve to an arbitrary tag |
| `g<short_sha>` | no | guarantees one tag per commit. Two commits can share `%ct` (same-second on different branches, or after `git commit --amend`) — without the SHA the second publish would clash with the first |
| branch slug | **dropped** | would only enable registry-side filtering by branch (`crane ls \| grep …`). Same information is available from Git for any commit identified by SHA, and the tag should be artifact identity, not branch metadata |

If branch-by-branch tag listing becomes necessary later, the right answer is OCI annotations on the manifest (`org.opencontainers.image.source.ref`, etc.), not a longer SemVer string.

## Why branch builds carry a leading `0`

The invariant: **a branch build must never be the version a query selects**, under `@vN`, `@vN.M`, or an explicit range that admits prereleases. Resolving any of those to an unreleased branch commit silently ships in-flight work to every consumer.

It is tempting to lean on Go/CUE's rule that `@vN` ignores prereleases when a stable version exists, and let branch builds preview the next minor. Two things defeat that:

1. **A major can live for a long time with no stable release.** `@v1` ships only `v1.0.0-alpha.N` today, so there is nothing for `@v1` to prefer and it must take the highest prerelease. `v1.0.0-dev.*` beats every `v1.0.0-alpha.N`, because prerelease identifiers compare lexically and `alpha` < `dev`. Moving the branch build to the next minor is *strictly worse*: `v1.1.0-dev.*` beats `v1.0.0-alpha.3` on the base version alone, before prerelease identifiers are consulted at all.
2. ~~**Range subscriptions deliberately admit prereleases.**~~ **Retired in `v2.0.0-alpha.3`** — a `#Platform` subscription now names one build as a scalar `version` and resolves nothing, so no query of that kind can select a branch build by accident. It is kept here struck through rather than deleted because it was a load-bearing half of the original argument: while platform filters were ranges that admitted prereleases, a next-minor branch build won any range whose top minor had no release of its own. The conclusion below stands on point 1 alone, and stands unchanged.

So the branch build shares the base version of the highest existing release and is ranked below it there. SemVer 2.0 §11.4.3 is the lever: *a numeric identifier always has lower precedence than an alphanumeric one at the same position*. Leading the prerelease with `0` puts every branch build under every named channel on that base:

```text
v1.0.0-0.dev.1785961206.g6b10e87  <  v1.0.0-alpha.1  <  v1.0.0
```

One rule, every phase, every query kind. `0` is a valid numeric identifier — the SemVer prohibition is on *leading* zeroes (`01`), which the registry rejects outright (see the validation table).

A branch build may still outrank an *older* release on a lower base — `v1.1.0-0.dev.*` is above `v1.0.0`. That is expected and harmless: resolution selects the maximum, and the maximum is always the newest release (`v1.1.0-alpha`), never the branch build.

The cost is that "track latest dev" has no range-based form: `@v1.0` resolves to the newest alpha, since branch builds now sort below it. Pinning an exact `-0.dev.` tag is the only way to follow a branch. That is the intended trade — an unreleased build should be opted into explicitly, never inherited by someone who wrote `@v1`.

## Determinism: local publish == CI publish

The branch tag is a function of the commit object alone:

```text
tag = f(NEXT_MINOR, commit_ct(SHA), short_sha(SHA))
```

Both inputs derived from `SHA` are fields *inside* the commit object, hashed into the SHA itself. Changing either produces a different SHA — so for a given SHA they are byte-identical everywhere.

What this rules out:

- Wall-clock time at build (`date +%s`, GitHub Actions `${{ github.event.repository.pushed_at }}`, etc.) is **never** read.
- Build counters, CI run IDs, sequence numbers — none used.
- Local registry cache state — irrelevant to tag computation.

What this means in practice:

- A developer publishing locally before pushing produces the same tag CI will produce on the matching push. The second publish is a no-op (OCI registry refuses to overwrite immutable tags, or returns the same digest).
- Reproducible builds: anyone with the commit can re-derive the exact tag, fetch the artifact, and verify the digest.

The base version is the one piece sourced outside the commit — it is read from the repo's git tags. Worst case: a branch outlives a release, and re-publishes from that branch keep targeting an outdated base. The publisher should `git fetch --tags` periodically; CI naturally sees the latest tags because it checks out fresh with `fetch-depth: 0`. A stale base is not a correctness problem for the invariant — an older base ranks *lower*, so the branch build still loses to every newer release.

## Consumer resolution

CUE's resolver (`cue mod get`, `cue mod tidy`) follows Go-module semantics: pre-release tags are excluded from `@latest` and major-only queries, but **included** when a query specifies the same `MAJOR.MINOR`.

Verified against CUE 0.16.1:

| Query | Resolves to |
| --- | --- |
| `cue mod get opmodel.dev/core@latest` | latest stable (e.g. `v0.3.0`) |
| `cue mod get opmodel.dev/core@v0` | latest stable |
| `cue mod tidy` (no pin) | latest stable |
| `cue mod get opmodel.dev/core@v0.4` | **highest release on v0.4** — branch builds sort below every named channel on that base, so they are never selected here |
| `cue mod get opmodel.dev/core@v0.4.0-0.dev.<ts>.g<sha>` | exact pin |

Platform subscriptions no longer resolve anything: since `v2.0.0-alpha.3` a `#Platform` names the catalog build it materializes as a scalar (`version: "1.0.0-alpha.7"`), so a branch build reaches a platform only by being written into it. The table above is therefore the whole of the selection surface — it governs `cue.mod` dependency resolution, and nothing else queries a range.

So two pin styles are blessed by this strategy:

```cue
// Track the release channel
deps: "opmodel.dev/core@v2": v: "v2.0.0-alpha.1"

// Follow a specific branch build — exact pin only, by design
deps: "opmodel.dev/core@v2": v: "v2.0.0-0.dev.1785961206.g6b10e87"
```

There is deliberately no range-based "track latest dev" pin. Consuming an unreleased build is an explicit act: query the OCI tag list, pick the tag, write it down. See [Why branch builds carry a leading `0`](#why-branch-builds-carry-a-leading-0).

## What this strategy does not provide

- **Per-branch "latest" tag.** CUE rejects partial pre-release prefixes (`@v0.4.0-dev` → "module not found"). To find the newest tag for branch `foo`, query the OCI tag list (`crane ls`, `gh api`, or `(*modregistry.Client).ModuleVersions`) and filter client-side. Out of scope for this document.
- **Branch metadata in the tag string.** Use OCI manifest annotations if/when needed.
- **Mutable "channel" pointers** (e.g. an always-updated `dev` tag). CUE refuses non-SemVer tags from the resolver, and the OCI immutability model in GHCR makes mutable tags a footgun anyway.
- **Cross-branch ordering by recency.** `@v0.<NEXT_MINOR>` returns the genuinely-newest commit globally because `commit_ct` leads the sort — but two branches active in the same window will see each other's commits as "latest dev" depending on who committed last. This is the intended semantics; if a consumer wants to pin to one branch's lineage specifically, it should pin the exact tag.

## Validation summary

Behavior was verified against CUE 0.16.1's in-memory registry. Key results:

| Test | Outcome |
| --- | --- |
| Publish `v0.2.0-dev.<ts>.g<sha>` | accepted |
| Publish `v0.2.0+build.meta` (build metadata) | rejected — CUE's `IsCanonical` strips `+xxx` |
| Publish `v0.2.0-dev.01.gabc` (leading-zero numeric) | rejected — SemVer 2.0 |
| `cue mod get @v0` against {stable, three pre-releases} | picked stable |
| `cue mod get @v0.<next-minor>` same set | picked highest pre-release |
| Sort: older-ts + lex-MAX SHA vs newer-ts + lex-MIN SHA | newer-ts won (timestamp leads) |
| Sort: same-ts, different counts (in earlier format) | higher count won — confirms left-to-right segment comparison |

Full transcript of the resolver tests is in the design conversation; not duplicated here.

## Implementation

- `.tasks/branch-tag.sh` — pure shell function that prints the tag for HEAD. Reads the major from `src/cue.mod/module.cue` and `NEXT_MINOR` from the highest stable `vMAJOR.*.*` git tag (falls back to `0` if no stable release exists yet for the current major). Refuses to run on `main` or against a dirty worktree.
- `task branch-tag` — prints the tag without side effects.
- `task publish:branch` — runs `task check` then `cue mod publish $TAG` from `src/`. Honours `CUE_REGISTRY`, so the same command publishes to the workspace local registry (`localhost:5000+insecure`) or GHCR depending on the environment. In CI this is the sanctioned `-dev.*` pre-release path; a laptop publish is a gated exception (Registry Policy rule 2, workspace root `CLAUDE.md`).
- `.github/workflows/branch-publish.yml` — fires on `push` to any branch except `main`. Skipped on forks (no `packages: write`). Calls `task publish:branch` after logging into GHCR with `GITHUB_TOKEN`.

## Follow-ups (not yet implemented)

- Idempotency probe: HEAD the OCI manifest before publish and skip if the tag already exists. Current behavior is to re-publish the same content under the same tag — registries dedupe by digest, so this is a no-op in storage but produces noisy logs.
- Cleanup workflow: prune branch tags whose SHA is no longer reachable from any current ref (avoids accumulating orphaned tags after force-pushes / rebases).
- Consumer helper (e.g. `task core:latest-tag MINOR=v0.4`) for automation that needs the resolved tag string outside of CUE — wraps an OCI tag-list query and SemVer sort.
