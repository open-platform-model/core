#!/usr/bin/env bash
set -euo pipefail

# publish-probe.sh: refuse to publish a module version the registry already holds.
#
# A published version always names the bytes first pushed under it. `cue mod
# publish` has no existence check and GHCR has no tag immutability, so the
# release job asks the registry first and publishes only on a definite "absent".
#
# Exit codes (each maps to a recovery):
#   0  the registry answered 404: the version is absent, publish it.
#   1  the registry answered 200: the version is already published. Never
#      publish it again; release the next version.
#   2  any other answer (auth error, rate limit, 5xx, unreachable): the state is
#      unknown. Nothing was pushed, so re-run the job once the registry answers.
#
# The module path comes from src/cue.mod/module.cue (opmodel.dev/core@v2 maps
# to the repository opmodel.dev/core: CUE drops the major from the path).
#
# A repository that does not exist answers 401 to an anonymous HEAD, not 404,
# so this exits 2 for it. That is the safe direction for an existing module and
# the reason this script cannot prove absence for a first-ever publish.
#
# Overrides (for tests against a throwaway registry):
#   PROBE_BASE_URL   registry base URL, default https://ghcr.io
#   PROBE_NAMESPACE  repository prefix, default open-platform-model; set it
#                    empty for a registry that serves modules at the root
#
# Usage (from the repo root):
#   bash .tasks/publish-probe.sh vX.Y.Z

if [[ $# -ne 1 || -z "$1" ]]; then
  echo "usage: $0 VERSION" >&2
  exit 2
fi
version="$1"

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
module=$(sed -n 's/^module:[[:space:]]*"\([^"]*\)".*/\1/p' "${root}/src/cue.mod/module.cue")
if [[ -z "$module" ]]; then
  echo "::error::cannot read the module path from src/cue.mod/module.cue; refusing to publish." >&2
  exit 2
fi
path="${module%@*}"

base="${PROBE_BASE_URL:-https://ghcr.io}"
ns="${PROBE_NAMESPACE-open-platform-model}"
repo="${ns:+${ns}/}${path}"

# Anonymous pull token. A registry that needs none (registry:2), a missing jq
# or a refused token all leave it empty; the HEAD below then decides.
token=$(curl -fsS "${base}/token?scope=repository:${repo}:pull" 2>/dev/null | jq -r '.token // empty' 2>/dev/null) || token=""

auth=()
if [[ -n "$token" ]]; then
  auth=(-H "Authorization: Bearer ${token}")
fi

# curl exits non-zero when the registry is unreachable; keep that fail-closed
# but fall through to the message that says a re-run is safe.
code=$(curl -sS -o /dev/null -w '%{http_code}' -I \
  "${auth[@]}" \
  -H 'Accept: application/vnd.oci.image.manifest.v1+json' \
  -H 'Accept: application/vnd.oci.image.index.v1+json' \
  "${base}/v2/${repo}/manifests/${version}") || code=000

case "$code" in
  404)
    echo "${path} ${version} is not on the registry; publishing"
    exit 0
    ;;
  200)
    echo "::error::${path} ${version} is already published; a published version is never overwritten. Release the next version." >&2
    exit 1
    ;;
  *)
    echo "::error::registry answered ${code} for ${path} ${version}; cannot prove the version is absent, refusing to publish. Nothing was pushed: re-run the job once the registry answers." >&2
    exit 2
    ;;
esac
