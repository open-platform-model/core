## Context

See proposal.md for why. Current state:

- `.github/workflows/release.yml` runs on `push` to `main` only. The `release-please` job (action v4.4.1, release-please 17.3.0, acting as the release App) exposes `release_created`, `tag_name` and `version`, and dispatches `ci.yml` onto `release-please--branches--main--components--core`. The `publish-cue` job checks out `tag_name`, logs into GHCR with `GITHUB_TOKEN`, runs `cue vet ./...` and `cue mod publish "v${version}"` from `src/`. Nothing checks the registry first.
- `Taskfile.yml` `publish`: `cue fmt`, a clean-diff check, `cue vet`, `cue mod publish {{.VERSION}}`, all under the caller's `CUE_REGISTRY`.
- `publish:branch` and `.github/workflows/branch-publish.yml` publish `-0.dev.*` tags to GHCR on every non-main push. Those tags are mutable by the workspace rule and stay untouched.
- The `v1` branch is core's existing maintenance line and the precedent for this design: its `release.yml` runs on `push` to `v1`, passes `target-branch: v1`, dispatches CI onto `release-please--branches--v1--components--core`, and its `release-please-config.json` sets `versioning: always-bump-patch`. It has released `v1.1.x` patches that way.

Platform controls this design relies on, owner-applied in the browser and not repo content: org ruleset `tags-immutable` (no tag update or deletion, empty bypass), `tags-create-app-only` (tag creation only by the opm-release-please App), `release-branches` (`refs/heads/release/*`: no deletion, no force push, PR required, squash only, empty bypass), and GitHub immutable releases for core.

Nothing under `src/` changes, so no `src/*.cue` file, no construct in `.tasks/spec-tracked.txt` and no `SPEC.md` section moves. No construct is newly tracked. Every commit in this change is spec-neutral and lands with `SPEC_IMPACT=none` (reason: CI and tooling only).

## Goals / Non-Goals

**Goals:**

- A release run never overwrites a version GHCR already holds.
- A released minor can receive patch releases from a `release/vX.Y` branch, cut by one automated action, without any change to `main`'s release flow.
- `task publish` cannot reach GHCR from a laptop.
- Every refusal fails the run loudly; nothing degrades to a warning or a skip.

**Non-Goals:**

- Cutting a release branch now. Core is in beta; fixes go forward on `main` (`-beta.N+1`). The first `release/v2.0` is cut at GA or when `main` starts work `v2.0` must not get.
- Asserting the tag's commit in the workflow. `tags-create-app-only` and `tags-immutable` mean a tag can only be created by the App release-please runs as, and never moved; the assertion the earlier draft planned is dropped.
- Branch builds. `-0.dev.*` tags stay mutable, `publish:branch` keeps honouring `CUE_REGISTRY`, and `branch-publish.yml` keeps firing on every non-main push, `release/**` included (a dev build of a release branch is harmless and ranks below its releases).
- The `v1` maintenance branch's own `release.yml` (follow-up, task 4.1).
- Making a red release run green again once the version exists. The recovery is the next version.

## Decisions

### D1. Probe GHCR anonymously over the OCI distribution API, fail closed

`.tasks/publish-probe.sh VERSION` derives the module path from `src/cue.mod/module.cue` (`opmodel.dev/core@v2` to `opmodel.dev/core`), fetches an anonymous pull token, and sends `HEAD /v2/<repo>/manifests/<VERSION>`:

```bash
set -euo pipefail
base="${PROBE_BASE_URL:-https://ghcr.io}"
ns="${PROBE_NAMESPACE-open-platform-model}"        # unset: GHCR org; empty: a registry with no namespace
repo="${ns:+${ns}/}${module%@*}"                    # open-platform-model/opmodel.dev/core
token=$(curl -fsS "${base}/token?scope=repository:${repo}:pull" | jq -r '.token // empty') || token=""
code=$(curl -sS -o /dev/null -w '%{http_code}' -I \
  ${token:+-H "Authorization: Bearer ${token}"} \
  -H 'Accept: application/vnd.oci.image.manifest.v1+json' \
  -H 'Accept: application/vnd.oci.image.index.v1+json' \
  "${base}/v2/${repo}/manifests/${VERSION}") || code=000   # unreachable: curl exits non-zero, keep fail-closed
case "$code" in
  404) echo "${VERSION} is not on the registry; publishing"; exit 0 ;;
  200) echo "::error::opmodel.dev/core ${VERSION} is already published; a published version is never overwritten. Release the next version." >&2; exit 1 ;;
  *)   echo "::error::registry answered ${code} for ${VERSION}; cannot prove the version is absent, refusing to publish. Nothing was pushed: re-run the job once the registry answers." >&2; exit 2 ;;
esac
```

The two `|| ...` fallbacks matter under `set -e`: without them an unreachable registry exits with curl's own code (7) before the `case`, which still fails closed but skips the message that tells the operator a re-run is safe.

Exit codes map to the recovery rule (D4): 1 means roll forward, 2 means re-run.

Measured 2026-10-01 against GHCR: `v2.0.0-beta.1` returns 200, `v2.0.0-beta.99` returns 404. A repository that does not exist does **not** return 404: the token endpoint answers 403 (`curl -f` fails, the token is empty), the anonymous `HEAD` then answers 401, and the probe exits 2. That is the safe direction for core, whose repository exists (CUE drops the `@vN` major from the repository path). A first publish to a brand-new repository would need a different absence proof; this script is not meant to be copied to one unchanged.

Alternatives:

- **Rely on `cue mod publish`.** Rejected: at cue v0.17.1 `putCheckedModule` calls `PushManifest` under the version tag with no existence check, so it overwrites.
- **`crane` / `oras` / `docker manifest inspect`.** Rejected: a new tool install for one HEAD request, and `docker manifest inspect` is not guaranteed to accept a CUE module artifact's media types. `curl` and `jq` are on every runner and laptop.
- **Treat "present" as success (idempotent re-run).** Rejected: proving the present bytes equal the tag's tree needs a rebuild and digest comparison CUE does not expose, and the published `v2.0.0-beta.1` manifest carries no `org.cuelang.vcs-commit` annotation (`source: kind: "self"`), so there is no cheap provenance check either.
- **Authenticate with `GITHUB_TOKEN`.** Not needed: the package is public. If it ever turns private the anonymous probe gets 401 and refuses (fail closed), which is the safe direction.

### D2. Release from `release/**` with the same workflow, branch-targeted

The `push` trigger gains `release/**`. release-please gets `target-branch: ${{ github.ref_name }}`, which is `main` on `main` (the action's default, so `main`'s behaviour is unchanged) and `release/vX.Y` on a release branch. The CI dispatch step derives its ref the same way, passing the branch through `env:` rather than interpolating it into the script:

```yaml
on:
  push:
    branches:
      - main
      - 'release/**'
...
      - name: Run release-please
        id: release
        uses: googleapis/release-please-action@5c625bfb5d1ff62eadeeb3772007f7f66fdcf071 # v4.4.1
        with:
          token: ${{ steps.app-token.outputs.token }}
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json
          target-branch: ${{ github.ref_name }}

      - name: Trigger required CI on the release PR
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          TARGET: ${{ github.ref_name }}
        run: |
          gh workflow run ci.yml \
            --repo "${{ github.repository }}" \
            --ref "release-please--branches--${TARGET}--components--core" \
            || echo "no open release branch - nothing to trigger"
```

The branch-local release-please settings live in the branch's own `release-please-config.json` (`versioning: always-bump-patch`, `prerelease: false`), set by the PR the cut action opens, exactly as `v1` does. `publish-cue` is unchanged apart from the D1 probe: it checks out `tag_name` and publishes, so a backport patch `v2.0.1` gets the same guard as a `main` release. The `@v2` module path still refuses any tag outside major 2.

`ci.yml` needs no change: its `pull_request` trigger has no branch filter, so a backport PR into `release/v2.0` and the release PR on it both get the required check.

Alternatives:

- **A separate `release-branch.yml`.** Rejected: two copies of the publish job drift, and the probe would have to be added twice.
- **Hard-code the target per branch, as `v1` does.** Rejected: one workflow serves every future `release/vX.Y` with no edit at cut time.

### D3. A thin `cut-release-branch` caller over the shared reusable workflow

```yaml
name: Cut release branch

on:
  workflow_dispatch:
    inputs:
      minor:
        description: 'Released minor to maintain, as X.Y (for example 2.0); creates release/vX.Y from the highest vX.Y.* tag'
        required: true
        type: string

permissions:
  contents: read

jobs:
  cut:
    uses: open-platform-model/.github/.github/workflows/cut-release-branch.yml@<commit-sha> # pinned once it merges
    with:
      tag_prefix: v
      minor: ${{ inputs.minor }}
      package: '.'
    secrets: inherit
```

The reusable workflow (owned by `open-platform-model/.github`, written in parallel) creates `release/v<minor>` from the highest `v<minor>.*` tag and opens a PR into it that sets `versioning: always-bump-patch` and `prerelease: false` for package `.` in `release-please-config.json` and confirms `release.yml`'s trigger covers the branch (D2 already does). Core keeps no logic of its own: the caller passes core's constants. The input names, the pinned SHA, the `secrets:` form and the caller's `permissions:` follow the reusable workflow's merged interface; if it mints the release App token itself, the caller needs no write permission. Creating the branch through the App is what lets it pass `release-branches` without a bypass.

During beta the highest `v2.0.*` tag is a prerelease (`v2.0.0-beta.N`); the action must not be run until GA (Non-Goals). That is an operator rule, recorded in the spec requirement, not enforced by the caller.

### D4. One recovery rule: re-run while nothing is published, roll forward once it is

- The probe exits 2 (inconclusive) or the job fails before `cue mod publish` pushes its manifest: nothing was published. The job is re-run in CI. This is what the existing schema-release requirement already prescribes ("a failed publish is debugged and re-run in CI").
- The probe exits 1 (version present), whether on a first run or a re-run: the version is never published again. If it is broken, the next release supersedes it (`-beta.N+1`, or the next patch from `release/vX.Y` after GA). The tag is never moved, and the run stays red.

`putCheckedModule` pushes the manifest last, after every blob, so a job that dies before that leaves the version absent and a re-run is safe; a job that pushed the manifest and then reported failure is caught by the probe on re-run, and the existing "published artifact is verified to resolve" check tells the operator whether the published version is usable. The spec's MODIFIED requirement states this once so the existing re-run sentence and the new refusal cannot be read against each other.

### D5. Force `task publish` to a local registry in-script

```yaml
publish:
  desc: Publish the CUE module at VERSION to the local registry only (task publish VERSION=vX.Y.Z; CI publishes releases)
  requires:
    vars: [VERSION]
  cmds:
    - |
      set -euo pipefail
      # Forced here, not in env:, because an exported CUE_REGISTRY beats a task-level env: (task 3.52).
      export CUE_REGISTRY="opmodel.dev=localhost:5000+insecure,registry.cue.works"
      (cd src && cue fmt ./...)
      git diff --exit-code -- 'src/*.cue'
      (cd src && cue vet ./...)
      (cd src && cue mod publish "{{.VERSION}}")
```

Measured 2026-10-01 with task 3.52.0: a task-level `env: {CUE_REGISTRY: local}` prints the ambient `ghcr` value when the shell exports one, so an `env:` block would not force anything. Unlike library's publish tasks, there is no `OPM_PUBLISH_REGISTRY` override: a core release publish has exactly one sanctioned path, CI, and an override is the leak this decision closes.

**How it is tested: never against GHCR, and never against the workspace registry.** The workspace `opm-registry` container listens on `localhost:5000` on this machine, so a plain run of the task would write into shared local state, and a broken forcing would reach GHCR through the ghcr.io credential in `~/.docker/config.json`. The check therefore runs in containers on an `--internal` Docker network, which has no route off the host:

1. `docker network create --internal core-publish-test`; `docker run -d --rm --name core-publish-reg --network core-publish-test registry:2`.
2. A test container joins the registry's network namespace (`--network container:core-publish-reg`), so inside it `localhost:5000` is the throwaway registry. It is a glibc image with `git` and `bash` (for example `golang:1.25`), with the host's `cue` and `task` binaries and the worktree mounted read-only into a scratch copy.
3. Inside it, with the sentinel environment `CUE_REGISTRY='opmodel.dev=127.0.0.1:1,registry.cue.works'` and `DOCKER_CONFIG` pointing at an empty directory, run `task publish VERSION=v2.0.0-0.probe.1`. Pass: it succeeds, and `PROBE_BASE_URL=http://localhost:5000 PROBE_NAMESPACE= bash .tasks/publish-probe.sh v2.0.0-0.probe.1` then exits 1 (present) while `v2.0.0-0.probe.2` exits 0.
4. Negative: the same test container with `--network none` and the same sentinel. Pass: the error names `localhost:5000`. An error naming `127.0.0.1:1` means the forcing is broken.
5. `docker rm -f core-publish-reg; docker network rm core-publish-test`.

Even if the forcing were broken, the sentinel points at a closed port, the credential store is empty, and the network has no route out, so no outcome of the test can write to GHCR or to the workspace registry. The throwaway publish of `opmodel.dev/core` is run only with the user's go-ahead in the apply prompt (Registry Policy rule 2 gates `opmodel.dev/*` local publishes).

## Research & Decisions

### Does `cue mod publish` refuse an existing version?
**Context**: D1 is only needed if CUE itself does not guard the tag.
**Explored**: `cuelang.org/go@v0.17.1/mod/modregistry/client.go`, `putCheckedModule`.
**Decision**: Add a probe.
**Rationale**: the manifest is pushed under the version tag with no prior lookup, and GHCR offers no tag immutability (workspace research `tagres/critic.md` C7).

### Is a tag-to-commit assertion still needed?
**Context**: the earlier draft asserted the tag's peeled commit against release-please's `sha` output, and review found that `sha` is GitHub's echo of `target_commitish`, unverified for a pre-existing tag.
**Explored**: the owner's 2026-10-01 revision of the canon.
**Decision**: Drop the assertion and its spike.
**Rationale**: `tags-create-app-only` restricts tag creation to the App release-please runs as, and `tags-immutable` forbids moving or re-creating one, so a stale or hand-made tag at the release version cannot exist. This also removes the review finding that an assertion in the `release-please` job turned a transient failure into a green run that published nothing.

### Does release-please handle a target branch containing `/`?
**Context**: D2 targets `release/v2.0`, so release-please names its PR branch `release-please--branches--release/v2.0--components--core`.
**Explored**: release-please v17.3.0 `src/util/branch-name.ts`.
**Decision**: Use `github.ref_name` unchanged.
**Rationale**: the name is built as `release-please--branches--${targetBranch}--components--${component}` and parsed with `^release-please--branches--(?<branch>.+)--components--(?<component>.+)$`, whose `.+` admits `/`. The legacy v12 patterns that use `[^/]+` start with `release-please/branches/` and cannot match the new form.

### Can Taskfile `env:` force the registry?
**Context**: D5.
**Explored**: a scratch Taskfile under task 3.52.0 with `CUE_REGISTRY=ghcr` exported.
**Decision**: Export in the command script.
**Rationale**: the ambient value won over the task-level `env:`.

## Risks / Trade-offs

- [A publish that pushed its manifest but reported failure leaves a permanently red run] → the next release supersedes it; the resolve-after-publish check tells the operator whether the version is usable. Accepted over an idempotent re-run that cannot verify bytes.
- [GHCR outage or rate limit blocks a release] → fail closed by design; re-run the job once the registry answers (D4). Safe because nothing was published.
- [A refused release leaves a GitHub Release and tag with no published module] → expected; the CHANGELOG entry stands, and the next release publishes. Never delete the release or the tag (rulesets refuse it anyway).
- [A backport patch released after a newer minor becomes GitHub's "Latest" release] → release-please 17.3.0 calls `createRelease` with no `make_latest`, and GitHub defaults it to true, so `v2.0.1` cut after `v2.1.0` takes the badge. Cosmetic: CUE resolution, the docs site and consumers ignore it. Not fixed here; revisit if a release-please version exposes the flag.
- [The cut action is run during beta, branching from a `-beta.N` tag] → the spec forbids it; the branch would be undeletable under `release-branches`. Accepted as an operator rule because the action runs once per minor, by hand.
- [The reusable workflow's final interface differs from D3's assumed input names] → the caller is a few lines and is finished against the merged interface (task 2.2); nothing runs it before GA.
- [The probe hard-codes the GHCR layout (`ghcr.io/<namespace>/<module path>`)] → that layout is the one `CUE_REGISTRY` in `release.yml` already encodes; a registry move edits both in one place each.
- [`task publish` loses the ability to target GHCR] → intended; that was never a sanctioned use.

## Migration Plan

Merge as one PR of hidden-type commits; its title, which becomes the squash commit, MUST also be a hidden type (`ci(release): ...`), or the merge would cut `v2.0.0-beta.2`. The probe takes effect on the next release PR merge; the release-branch trigger stays idle until a `release/v2.0` exists. Rollback is a revert of the workflow and Taskfile edits; nothing published changes either way.

## Open Questions

- None blocking. The `v1` branch follow-up is tracked as task 4.1.
