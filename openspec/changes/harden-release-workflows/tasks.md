## 1. Workflow credentials

- [x] 1.1 `release.yml`: replace the workflow-level `permissions` with `{}`; give `release-please` `environment: release` and `permissions: {actions: write, contents: read}`, and `publish-cue` `permissions: {contents: read, packages: write}` (design D1, D2). Leave `publish-docs` and `notify-downstream` unchanged.
- [x] 1.2 `ci.yml`: add top-level `permissions: {}` and job `ci` `permissions: {contents: read}`.
- [x] 1.3 `branch-publish.yml`: top-level `permissions: {}`, job `publish` `permissions: {contents: read, packages: write}`; add `release-please--**`, `deps/cascade` and `dependabot/**` to `branches-ignore` (design D3).
- [x] 1.4 Verify: every workflow has a top-level `permissions:` and every job its own; exactly one job reads `RELEASE_APP_PRIVATE_KEY` and it declares `environment: release`; no `actions/cache`, `cache:` or `type=gha` in any workflow; `actionlint` reports nothing new; `task cascade:wiring:check` passes unchanged.
- [x] 1.5 `task check` green, then commit `ci: scope every workflow token and gate the release key on the release environment`

## 2. Review and update config

- [x] 2.1 Add `.github/CODEOWNERS` with the plan's header line and owners for `/.github/`, `/.tasks/`, `/Taskfile*.yml`, `/release-please-config.json`, `/.release-please-manifest.json` (no `/.cascade-frozen`, no `/hack/`: neither exists).
- [x] 2.2 Add `.github/dependabot.yml`: `github-actions`, directory `/`, weekly, prefix `ci`, ignoring `open-platform-model/docs-kit*` and `open-platform-model/.github*`, with the same comments cli and library carry.
- [x] 2.3 `AGENTS.md` "Release & publishing": record the `release` Environment on `release-please`, the per-job permissions rule, the bot heads `branch-publish.yml` skips, and CODEOWNERS.
- [x] 2.4 `task check` green, then commit `ci: add code owners and dependabot for actions`

## 3. Final checks

- [x] 3.1 Gates: `task check`, `actionlint`, `task cascade:wiring:check`, `openspec validate harden-release-workflows --strict`.
- [x] 3.2 Commit the ticked task list as `docs(openspec): record the harden-release-workflows checks`
