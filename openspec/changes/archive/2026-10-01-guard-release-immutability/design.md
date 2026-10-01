## Context

See proposal.md for why. Current state:

- `.github/workflows/release.yml` runs on `push` to `main` only. The `release-please` job (action v4.4.1, release-please 17.3.0, acting as the release App) exposes `release_created`, `tag_name` and `version`, and dispatches `ci.yml` onto `release-please--branches--main--components--core`. The `publish-cue` job checks out `tag_name`, logs into GHCR with `GITHUB_TOKEN`, runs `cue vet ./...` and `cue mod publish "v${version}"` from `src/`. Nothing checks the registry first.
- `Taskfile.yml` `publish`: `cue fmt`, a clean-diff check, `cue vet`, `cue mod publish {{.VERSION}}`, all under the caller's `CUE_REGISTRY`.
- `publish:branch` and `.github/workflows/branch-publish.yml` publish `-0.dev.*` tags to GHCR on every non-main push. Those tags are outside the release rule and this change leaves them untouched.
- The `v1` branch is core's existing maintenance line: its own `release.yml` runs on `push` to `v1`, passes `target-branch: v1`, runs release-please with `GITHUB_TOKEN` (not the release App) and publishes with no probe. This change does not touch it (Migration Plan, precondition 1).

Platform controls this design relies on, owner-applied in the browser and not repo content: org ruleset `tags-immutable` (no tag update or deletion, empty bypass), `tags-create-app-only` (tag creation only by the opm-release-please App), and GitHub immutable releases for core. On 2026-10-01 `tags-immutable` and immutable releases are on for core and `tags-create-app-only` is not; the Migration Plan lists each as a precondition with the read-only command that checks it. The probe and the local-only `task publish` depend on none of them.

This is Phase 1 of the owner's two-phase plan (canon Revision 2, 2026-10-01). Phase 1 adds no release-branch support: every core release in this change is cut from `main`. Release branches and their automation are Phase 2 (before GA); the inputs collected for it are under "Phase 2 notes".

Nothing under `src/` changes, so no `src/*.cue` file, no construct in `.tasks/spec-tracked.txt` and no `SPEC.md` section moves. No construct is newly tracked. Every commit in this change is spec-neutral and lands with `SPEC_IMPACT=none` (reason: CI and tooling only).

## Goals / Non-Goals

**Goals:**

- A release run never overwrites a version GHCR already holds.
- `task publish` cannot reach GHCR from a laptop.
- Every refusal fails the run loudly; nothing degrades to a warning or a skip.

**Non-Goals:**

- Release branches. No `release/**` trigger, no target-branch change, no cut action, no branch-model row. That is Phase 2; until then every fix goes forward on `main` (`-beta.N+1` during beta).
- Asserting the tag's commit in the workflow. `tags-create-app-only` and `tags-immutable` mean a tag can only be created by the App release-please runs as, and never moved; the assertion the earlier draft planned is dropped.
- Branch builds. `-0.dev.*` tags are outside this change's requirement, `publish:branch` keeps honouring `CUE_REGISTRY` (an open question below), and `branch-publish.yml` keeps firing on every non-main push.
- The `v1` maintenance branch's own `release.yml` (follow-up, Migration Plan precondition 1).
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

Exit codes map to the recovery rule (D2): 1 means roll forward, 2 means re-run.

Measured 2026-10-01 against GHCR: `v2.0.0-beta.1` returns 200, `v2.0.0-beta.99` returns 404. A repository that does not exist does **not** return 404: the token endpoint answers 403 (`curl -f` fails, the token is empty), the anonymous `HEAD` then answers 401, and the probe exits 2. That is the safe direction for core, whose repository exists (CUE drops the `@vN` major from the repository path). A first publish to a brand-new repository would need a different absence proof; this script is not meant to be copied to one unchanged.

Alternatives:

- **Rely on `cue mod publish`.** Rejected: at cue v0.17.1 `putCheckedModule` calls `PushManifest` under the version tag with no existence check, so it overwrites.
- **`crane` / `oras` / `docker manifest inspect`.** Rejected: a new tool install for one HEAD request, and `docker manifest inspect` is not guaranteed to accept a CUE module artifact's media types. `curl` and `jq` are on every runner and laptop.
- **Treat "present" as success (idempotent re-run).** Rejected: proving the present bytes equal the tag's tree needs a rebuild and digest comparison CUE does not expose, and the published `v2.0.0-beta.1` manifest carries no `org.cuelang.vcs-commit` annotation (`source: kind: "self"`), so there is no cheap provenance check either.
- **Authenticate with `GITHUB_TOKEN`.** Not needed: the package is public. If it ever turns private the anonymous probe gets 401 and refuses (fail closed), which is the safe direction.

### D2. One recovery rule: re-run while nothing is published, roll forward once it is

- The probe exits 2 (inconclusive) or the job fails before `cue mod publish` pushes its manifest: nothing was published. The job is re-run in CI. This is what the existing schema-release requirement already prescribes ("a failed publish is debugged and re-run in CI").
- The probe exits 1 (version present), whether on a first run or a re-run: the version is never published again. If it is broken, the next release from `main` supersedes it (`-beta.N+1` during beta). The tag is never moved, and the run stays red.

`putCheckedModule` pushes the manifest last, after every blob, so a job that dies before that leaves the version absent and a re-run is safe; a job that pushed the manifest and then reported failure is caught by the probe on re-run, and the post-publish resolve verification the schema-release spec requires ("The published artifact is verified to resolve", a step the releaser performs by hand; `release.yml` has no such step) tells the operator whether the published version is usable. The spec's MODIFIED requirement states this once so the existing re-run sentence and the new refusal cannot be read against each other.

One path is outside the publish job: release-please itself can fail after it created the tag and GitHub Release (release-please 17.3.0 `manifest.ts`: `createRelease` succeeds, a later comment or label call fails). A re-run then hits `DuplicateReleaseError`, relabels the PR and fails, and the run after that finds no pending release PR and leaves `release_created` empty: green, nothing published. Core has no dispatch recovery. So: **if the tag exists, the module is absent and no release PR is pending, the recovery is the next version, not a re-run.** The gap predates this change and is rare.

### D3. Force `task publish` to a local registry in-script

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

**How it is tested: never against GHCR, and never against the workspace registry.** The workspace `opm-registry` container listens on `localhost:5000` on this machine, so a plain run of the task would write into shared local state, and a broken forcing would reach GHCR through the ghcr.io credential in `~/.docker/config.json`. Every check therefore runs in containers, with the sentinel `CUE_REGISTRY='opmodel.dev=127.0.0.1:1,registry.cue.works'` and `DOCKER_CONFIG` pointing at an empty directory:

1. **Forcing (negative).** A glibc container with `git` and `bash` (for example `golang:1.25`) and `--network none`, with the host's `cue` and `task` binaries mounted read-only. The worktree's `.git` is a file pointing at the main checkout's gitdir, so the container copies the tree into a scratch directory and makes it a fresh repository (`git init && git add -A && git commit`) before running `task publish VERSION=v2.0.0-0.probe.1`. Pass: the error names `localhost:5000`. An error naming `127.0.0.1:1` means the forcing is broken.
2. **Probe against a throwaway registry.** `docker network create --internal core-publish-test`; `docker run -d --rm --name core-publish-reg --network core-publish-test registry:2`. A test container joins its network namespace (`--network container:core-publish-reg`), so `localhost:5000` is the throwaway registry and there is no route off the host. In a scratch copy whose `src/cue.mod/module.cue` names `testing.opmodel.dev/core-probe@v0` (the fixture domain, so no `opmodel.dev/*` module is published anywhere), `CUE_REGISTRY=testing.opmodel.dev=localhost:5000+insecure cue mod publish v0.0.1`. Pass: `PROBE_BASE_URL=http://localhost:5000 PROBE_NAMESPACE= bash .tasks/publish-probe.sh v0.0.1` exits 1 and `v0.0.2` exits 0, with and without `jq` on the path (jq is optional: `registry:2` needs no token, and a missing `jq` leaves the token empty).
3. `docker rm -f core-publish-reg; docker network rm core-publish-test`.

A positive end-to-end `task publish` of `opmodel.dev/core` into the throwaway registry is not part of the gate: Registry Policy rule 2 allows an `opmodel.dev/*` local publish only on the user's explicit request, and step 1 already proves where the task sends the module. Even if the forcing were broken, the sentinel points at a closed port, the credential store is empty and the network is `none`, so no outcome of the test can write to GHCR or to the workspace registry.

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

### Can Taskfile `env:` force the registry?
**Context**: D3.
**Explored**: a scratch Taskfile under task 3.52.0 with `CUE_REGISTRY=ghcr` exported.
**Decision**: Export in the command script.
**Rationale**: the ambient value won over the task-level `env:`.

## Risks / Trade-offs

- [A publish that pushed its manifest but reported failure leaves a permanently red run] → the next release supersedes it; the spec's post-publish resolve verification (a manual step) tells the operator whether the version is usable. Accepted over an idempotent re-run that cannot verify bytes.
- [GHCR outage or rate limit blocks a release] → fail closed by design; re-run the job once the registry answers (D2). Safe because nothing was published.
- [A refused release leaves a GitHub Release and tag with no published module] → expected; the CHANGELOG entry stands, and the next release publishes. Never delete the release or the tag (rulesets refuse it anyway).
- [The probe hard-codes the GHCR layout (`ghcr.io/<namespace>/<module path>`)] → that layout is the one `CUE_REGISTRY` in `release.yml` already encodes; a registry move edits both in one place each.
- [`task publish` loses the ability to target GHCR] → intended; that was never a sanctioned use.

## Migration Plan

Merge as one PR of hidden-type commits; its title, which becomes the squash commit, MUST also be a hidden type (`ci(release): ...`), or the merge would cut `v2.0.0-beta.2`. The probe takes effect on the next release PR merge. Rollback is a revert of the workflow and Taskfile edits; nothing published changes either way.

After the PR merges: archive is already done on the branch, so from the workspace root run `task enhancements:delivery:log FROM=core/openspec/changes/archive/<dated-name> SUMMARY="..."` (the log records landings, not starts; it declares no decisions).

Ordering with other repositories: the AGENTS.md pointer names the workspace rule "Release Tags Are Immutable", which exists only on open-platform-model/workspace PR 3 (open on 2026-10-01). Merge this PR after workspace PR 3, or the pointer dangles until it lands. Check: `gh pr view 3 -R open-platform-model/workspace --json state` reports `MERGED`.

Platform preconditions, owner-applied and not repo content. None of them gates merging this change: the probe and the local-only `task publish` work without them. They gate the policy's guarantee, so each is listed with its state on 2026-10-01 and a read-only check:

| # | Precondition | State 2026-10-01 | Check |
| --- | --- | --- | --- |
| 1 | `v1`'s `release.yml` runs release-please as the release App (a separate `ci:` change on `v1`, with the D1 probe) | not done | `git show origin/v1:.github/workflows/release.yml` has an `actions/create-github-app-token` step whose token release-please uses (today it has none, so release-please runs as `GITHUB_TOKEN`) |
| 2 | `tags-immutable` active on core, empty bypass | active | `gh api 'repos/open-platform-model/core/rulesets?includes_parents=true'` lists it `active` (id 24299539); `gh api repos/open-platform-model/core/rulesets/24299539` shows `bypass_actors: []` and rules `update`, `deletion`, `non_fast_forward` (read as a repo admin; the org endpoint needs `admin:org`, which agents never get) |
| 3 | `tags-create-app-only` active on core, only bypass the opm-release-please App | not active | the same listing shows it `active`; `gh api repos/open-platform-model/core/rulesets/<id>` shows rule `creation` and one `Integration` bypass actor, id 5132303. Enable only after 1, or `v1`'s next release cannot create its tag. Until then the dropped tag-to-commit assertion rests on `tags-immutable` alone, which stops a moved tag but not a hand-made one created before release-please reaches that version |
| 4 | GitHub immutable releases on for core | on | `gh api repos/open-platform-model/core/immutable-releases` returns `"enabled":true` |
| 5 | `docs-branches-pinned` deleted (the owner replaces it with `release-branches`) | still active | the listing no longer shows it. While it is active it blocks deleting ordinary `docs/<topic>` PR branches on core. `release-branches` as drafted has no `required_status_checks` rule; settle that before Phase 2 cuts the first branch |

## Phase 2 notes

Inputs for the Phase 2 release-branch change. Nothing here is implemented in Phase 1.

- **Policy to implement** (0021 D10, owner canon): lazy `release/vX.Y` (core: `release/v2.0`), cut by one automated action from the newest final `vX.Y.*` tag, never deleted, changed only by squash PRs, branch-local `versioning: always-bump-patch` and `prerelease: false`, every release tagged by release-please as the App, docs-only fixes cut no release and the docs site pins the commit SHA. **Version-line rule:** `release/vX.Y` is cut only when `main`'s next release is `X.(Y+1).0` or higher, and after the cut `main` never releases an `X.Y.*` version.
- **Design carried from the withdrawn draft:** one `release.yml` with `push.branches: [main, 'release/**']`, `target-branch: ${{ github.ref_name }}` (the default on `main`, so `main` is unchanged), and the CI dispatch ref built from `github.ref_name` through `env:`. Checked: release-please 17.3.0 `src/util/branch-name.ts` parses `release-please--branches--(?<branch>.+)--components--...`, so a target containing `/` works. `ci.yml`'s `pull_request` trigger has no branch filter. `v1` is the precedent (`target-branch: v1`, `always-bump-patch`).
- **Cut-action failure (review major):** the shared `cut-release-branch.yml` (open-platform-model/.github, commit 72f7d5d) creates `release/<x>` before pushing its setup branch, and its setup commit edits `release.yml`, which the opm-release-please App cannot push (no `workflows` permission). The result is an undeletable, unconfigured release branch that still carries `main`'s `versioning: prerelease`. Fix in .github: push and check the setup branch first, and skip adding `target-branch` when it is already present. Core: the release-branch trigger must be in the tree of the tag being cut, so the setup PR edits `release-please-config.json` only; dry-run the reusable Prepare step against core and assert `git diff --name-only` is exactly that file.
- **Caller interface:** the reusable workflow declares `tag_prefix`, `minor`, `package_path`, `release_workflow`, `release_app_client_id` and secrets `release_app_private_key`, `token`. A core caller passes `package_path: .`, the client id from `vars.RELEASE_APP_CLIENT_ID` and the private key explicitly (not `secrets: inherit`), with `permissions: {}`, pinned by commit SHA.
- **Beta and App facts:** the reusable workflow already refuses a minor with only prerelease tags, so a cut during beta is refused by the tool, not by an operator rule. The App token is used so CI runs on the setup PR; it is not what lets the branch pass `release-branches` (that ruleset has no creation rule). Prove in release-flow-sandbox that creating `release/*` through the API succeeds while the ruleset is active.
- **"Latest" badge (a Phase 2 requirement):** `0021:D10:R3` requires that a release from a `release/*` branch never moves `latest` or GitHub's Latest flag. release-please 17.3.0 calls `createRelease` without `make_latest`, so by default a backport patch released after a newer minor takes the Latest flag. Phase 2 must pass `make_latest: false` for branch releases (or reset the flag in the same run) and prove it in the sandbox.
- **Workspace hook:** the agent hook lets a `gh api` POST to `git/refs` with `ref=refs/heads/release/...` through, and `release-branches` would make such a branch permanent. Block it in `check_gh_api` before Phase 2.
- **Sandbox proof** before core adopts it: a cut from a pre-change tag, and the collision where `main` and the branch would both claim an `X.Y.*` version.

## Open Questions

- `task publish:branch` still follows the ambient `CUE_REGISTRY`, while workspace Registry Policy rule 2 says publish tasks force a local mapping. CI uses it for `-0.dev.*` builds, so forcing it local would break `branch-publish.yml`. Follow-up: refuse to run outside CI with a GHCR mapping, as a separate `chore(publish)` change.
- The canon calls `-0.dev.*` builds "mutable by design"; enhancements PR 74's D10 "Registry tags" paragraph (head c52aaf2) records them as create-only, "a fact of 0011, not a requirement of this decision". R3 itself covers only tags a release pushes. This change says only that branch builds are outside its requirement. The owner settles the wording in 0021.
- The `v1` follow-up is Migration Plan precondition 1; it is an owner or follow-up-PR action, not an apply step.
