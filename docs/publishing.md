# CUE module publishing — stable and branch tags

This document describes how `opmodel.dev/core` is published to its OCI registry: the stable release flow (already in place) and the branch-build flow (to be implemented). The focus is the *strategy* — tag format, determinism guarantees, and how consumers resolve them. Implementation (Taskfile, CI) follows once this is agreed.

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
  v<MAJOR>.<NEXT_MINOR>.0-dev.<commit_ct>.g<short_sha>
  e.g. v0.4.0-dev.1779820079.g3def91f
```

Where:

| Field | Source | Notes |
| --- | --- | --- |
| `MAJOR` | `cue.mod/module.cue` module suffix (`@v0`) | matches the published module identity |
| `NEXT_MINOR` | bump-minor of latest stable tag (read from `.release-please-manifest.json`) | every branch publish is "the next minor that hasn't happened yet" |
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

`NEXT_MINOR` is the one piece sourced outside the commit. It comes from `.release-please-manifest.json`, which is checked into the repo and thus stable at any commit. Worst case: a branch outlives a minor release, and re-publishes from that branch keep targeting an outdated `NEXT_MINOR`. The publisher should `git pull --rebase` periodically; CI naturally sees the latest manifest because it checks out fresh.

## Consumer resolution

CUE's resolver (`cue mod get`, `cue mod tidy`) follows Go-module semantics: pre-release tags are excluded from `@latest` and major-only queries, but **included** when a query specifies the same `MAJOR.MINOR`.

Verified against CUE 0.16.1:

| Query | Resolves to |
| --- | --- |
| `cue mod get opmodel.dev/core@latest` | latest stable (e.g. `v0.3.0`) |
| `cue mod get opmodel.dev/core@v0` | latest stable |
| `cue mod tidy` (no pin) | latest stable |
| `cue mod get opmodel.dev/core@v0.4` | **latest pre-release of v0.4**, until `v0.4.0` stable lands; then `v0.4.0` |
| `cue mod get opmodel.dev/core@v0.4.0-dev.<ts>.g<sha>` | exact pin |

So two pin styles are blessed by this strategy:

```cue
// Track stable
deps: "opmodel.dev/core@v0": v: "v0.3.0"

// Track latest dev — auto-transitions to v0.4.0 stable once cut
deps: "opmodel.dev/core@v0": v: "v0.4.0-dev.<latest-ts>.g<latest-sha>"
```

For the "track latest dev" pattern, downstream automation runs `cue mod get opmodel.dev/core@v0.4` and accepts whatever the registry has at that moment.

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

## Out of scope (next steps)

- `task publish:branch` Taskfile target that runs the same computation locally.
- GitHub Actions workflow that fires on `push` to non-`main` branches.
- Idempotency guard: skip publish if the computed tag already exists.
- Consumer helper (`task core:latest-tag MINOR=v0.4`) for automation that needs the resolved tag string outside CUE.
