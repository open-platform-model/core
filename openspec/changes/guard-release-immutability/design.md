## Context

See proposal.md for why. Current state:

- `.github/workflows/release.yml`: the `release-please` job (action v4.4.1, release-please 17.3.0, acting as the release App) exposes `release_created`, `tag_name` and `version`. The `publish-cue` job checks out `tag_name`, logs into GHCR with `GITHUB_TOKEN`, runs `cue vet ./...` and `cue mod publish "v${version}"` from `src/`. Nothing checks the tag's commit or the registry first.
- `Taskfile.yml` `publish`: `cue fmt`, a clean-diff check, `cue vet`, `cue mod publish {{.VERSION}}`, all under the caller's `CUE_REGISTRY`.
- `publish:branch` and `.github/workflows/branch-publish.yml` publish `-0.dev.*` tags to GHCR on every non-main push. Those tags are mutable by the workspace rule and stay untouched.

Nothing under `src/` changes, so no `src/*.cue` file, no construct in `.tasks/spec-tracked.txt` and no `SPEC.md` section moves. No construct is newly tracked. Every commit in this change is spec-neutral and lands with `SPEC_IMPACT=none` (reason: CI and tooling only).

## Goals / Non-Goals

**Goals:**

- A release run never overwrites a version GHCR already holds, and never publishes from a tag that names a commit other than the one release-please released.
- `task publish` cannot reach GHCR from a laptop.
- Every refusal fails the run loudly; nothing degrades to a warning or a skip.

**Non-Goals:**

- Branch builds. `-0.dev.*` tags stay mutable and `publish:branch` keeps honouring `CUE_REGISTRY`, because CI publishes them to GHCR through it.
- The `v1` maintenance branch's own `release.yml`.
- Platform controls (org tag ruleset, immutable releases): owner-applied in the browser, not repo content.
- Making a red release run green again. The recovery is the next version.

## Decisions

### D1. Probe GHCR anonymously over the OCI distribution API, fail closed

`.tasks/publish-probe.sh VERSION` derives the module path from `src/cue.mod/module.cue` (`opmodel.dev/core@v2` to repository `open-platform-model/opmodel.dev/core`), fetches an anonymous pull token, and sends `HEAD /v2/<repo>/manifests/<VERSION>`:

```bash
repo="open-platform-model/${module%@*}"          # opmodel.dev/core
token=$(curl -fsS "https://ghcr.io/token?scope=repository:${repo}:pull" | jq -r '.token // empty' || true)  # no token: the HEAD below answers 401 or 000
code=$(curl -sS -o /dev/null -w '%{http_code}' -I \
  ${token:+-H "Authorization: Bearer ${token}"} \
  -H 'Accept: application/vnd.oci.image.manifest.v1+json' \
  -H 'Accept: application/vnd.oci.image.index.v1+json' \
  "https://ghcr.io/v2/${repo}/manifests/${VERSION}")
case "$code" in
  404) echo "${VERSION} is not on GHCR; publishing"; exit 0 ;;
  200) echo "::error::opmodel.dev/core ${VERSION} is already published; a published version is never overwritten. Release the next version." >&2; exit 1 ;;
  *)   echo "::error::GHCR answered ${code} for ${VERSION}; cannot prove the version is absent, refusing to publish" >&2; exit 2 ;;
esac
```

The registry base URL and namespace are overridable by environment (`PROBE_BASE_URL`, default `https://ghcr.io`, used for both the token and the manifest request; `PROBE_NAMESPACE`, default `open-platform-model`) so the script can be checked against a local registry. Measured 2026-10-01 against GHCR: `v2.0.0-beta.1` returns 200 (digest `sha256:a9ef2153...`), `v2.0.0-beta.99` returns 404, and a repository that does not exist returns a null token and then 404 (absent, correct).

Alternatives:

- **Rely on `cue mod publish`.** Rejected: at cue v0.17.1 `modregistry.Client.putCheckedModule` calls `PushManifest` under the version tag with no existence check, so it overwrites.
- **`crane` / `oras` / `docker manifest inspect`.** Rejected: a new tool install for one HEAD request, and `docker manifest inspect` is not guaranteed to accept a CUE module artifact's media types. `curl` and `jq` are on every runner and laptop.
- **Treat "present" as success (idempotent re-run).** Rejected for now: proving the present bytes equal the tag's tree needs a rebuild and digest comparison CUE does not expose. A publish that pushed its manifest and then reported failure leaves a red run; the existing "published artifact is verified to resolve" check tells the operator whether the version is complete, and the canon forbids re-publishing it either way.
- **Authenticate with `GITHUB_TOKEN`.** Not needed: the package is public. If it ever turns private the anonymous probe gets 401 and refuses (fail closed), which is the safe direction.

### D2. Assert the tag's peeled commit against release-please's `sha`

release-please's `createRelease` returns `sha: resp.data.target_commitish`, and it passes the release commit as `target_commitish`, so the action's `sha` output is the commit release-please meant to release (verified on `v2.0.0-beta.1`: `target_commitish` is `4f9b245a...`, the same commit `refs/tags/v2.0.0-beta.1` names). A step in the `release-please` job, gated on `release_created`, compares it with the remote:

```bash
want="${{ steps.release.outputs.sha }}"
[[ "$want" =~ ^[0-9a-f]{40}$ ]] || { echo "::error::release-please gave no commit SHA ('${want}')"; exit 1; }
refs=$(git ls-remote "https://github.com/${GITHUB_REPOSITORY}" "refs/tags/${TAG}" "refs/tags/${TAG}^{}")
got=$(awk -v t="refs/tags/${TAG}^{}" '$2==t{print $1}' <<<"$refs")      # annotated: peeled line
[[ -n "$got" ]] || got=$(awk -v t="refs/tags/${TAG}" '$2==t{print $1}' <<<"$refs")  # lightweight
[[ "$got" == "$want" ]] || { echo "::error::tag ${TAG} names ${got:-nothing}, release commit is ${want}; refusing to publish. Release the next version; never move the tag."; exit 1; }
```

The job adds `sha` to its outputs. `publish-cue` then asserts `git rev-parse HEAD` equals `needs.release-please.outputs.sha` right after checkout, which also covers a tag that changed between the two jobs.

Placed in the `release-please` job rather than only in `publish-cue` so the failure is attributed to the release, and so any future job that consumes the release inherits the gate through `needs`.

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

Measured 2026-10-01 with task 3.52.0: a task-level `env: {CUE_REGISTRY: local}` prints the ambient `ghcr` value when the shell exports one, so an `env:` block would not force anything. Unlike library's publish tasks, there is no `OPM_PUBLISH_REGISTRY` override: a core release publish has exactly one sanctioned path, CI, and an override is the leak this decision closes. The mapping routes only `opmodel.dev`; core imports nothing else from it.

## Research & Decisions

### Does `cue mod publish` refuse an existing version?
**Context**: D1 is only needed if CUE itself does not guard the tag.
**Explored**: `cuelang.org/go@v0.17.1/mod/modregistry/client.go`, `putCheckedModule`.
**Decision**: Add a probe.
**Rationale**: the manifest is pushed under the version tag with no prior lookup, and GHCR offers no tag immutability (workspace research `tagres/critic.md` C7).

### What does release-please's `sha` output carry?
**Context**: D2 compares against it.
**Explored**: release-please-action v4.4.1 `src/index.ts` (`outputReleases` emits every `CreatedRelease` field), release-please v17.3.0 `src/github.ts` `createRelease`; the live `v2.0.0-beta.1` release and tag.
**Decision**: Use `sha` as the expected commit.
**Rationale**: it is `target_commitish`, which release-please sets to the release commit; GitHub attaches a release to an existing tag of the same name regardless, which is the case the assertion catches.

### Can Taskfile `env:` force the registry?
**Context**: D3.
**Explored**: a scratch Taskfile under task 3.52.0 with `CUE_REGISTRY=ghcr` exported.
**Decision**: Export in the command script.
**Rationale**: the ambient value won over the task-level `env:`.

## Risks / Trade-offs

- [A publish that pushed its manifest but reported failure leaves a permanently red run] → the next release supersedes it; the resolve-after-publish check tells the operator whether the version is usable. Accepted over an idempotent re-run that cannot verify bytes.
- [GHCR outage or rate limit blocks a release] → fail closed by design; re-run the job once the registry answers. A re-run is safe because nothing was published.
- [A refused release leaves a GitHub Release and tag with no published module] → expected; the CHANGELOG entry stands, and the next release publishes. Never delete the release or the tag.
- [The probe hard-codes the GHCR layout (`ghcr.io/<namespace>/<module path>`)] → that layout is the one `CUE_REGISTRY` in `release.yml` already encodes; a registry move edits both in one place each.
- [`task publish` loses the ability to target GHCR] → intended; that was never a sanctioned use.

## Migration Plan

Merge as one PR of hidden-type commits; no release is cut. The guards take effect on the next release PR merge. Rollback is a revert of the workflow and Taskfile edits; nothing published changes either way.

## Open Questions

- Whether the `v1` maintenance branch should get the same probe and assertion as a separate `ci:` change on that branch.
