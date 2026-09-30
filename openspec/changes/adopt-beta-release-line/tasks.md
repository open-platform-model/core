# Tasks

`<wt>` is `/var/home/emil/dev/open-platform-model/core/.claude/worktrees/beta-adopt-beta-release-line`, branch `beta/adopt-beta-release-line` from `origin/main` 748dfc7. `<scratch>` is the worker's scratch directory, outside any repo. Run every command as `cd <wt> && ...`; never edit the main checkout. Find each edit by its text (design.md D5), not by line number.

**Gates in a worktree.** `task check` fails in any worktree on `src/INDEX.md` line 1 only (the title is built from the directory name; measured on the untouched tree). Wherever a task says "gates", run both: `task fmt:check vet spec:check docs:check` (stage first: `fmt:check` compares the working tree with the git index) and `bash .tasks/generate-index.sh "$(pwd)" | sed '1s/^# [^ ]* /# core /' | diff - src/INDEX.md` (prints nothing).

**Delivery.** One PR, the core beta carrier. This change's stated deliverable is a release operation, so section 5 (push and PR) is the `rules.tasks` sole exception in `openspec/config.yaml`. The worker never merges anything.

| PR | Squash commit type | Carrier | Exact footer (final paragraph of the squash message) | Merge gate | Expected release PR |
| --- | --- | --- | --- | --- | --- |
| `chore(release): adopt the beta release line` | `chore(release)` | yes | `Release-As: 2.0.0-beta.1` then `Co-Authored-By: Claude <noreply@anthropic.com>` | none | `chore(main): release 2.0.0-beta.1` |

**Supervisor patches.** None. Core pins no upstream OPM release; no root task (`deps:update`, `deps:pins:*`) touches this change.

## Gates

Ticked by the supervisor, not by the worker, and outside every commit.

- [ ] Merge gate: none (owner decisions of 2026-09-30 are final). Before squashing, the supervisor confirms the squash message is byte-identical to the 4.6 carrier message, parses with release-please's parser to type `chore` and `Release-As` `2.0.0-beta.1`, carries no bare `@`, and has no body line starting with `word(`. No other core PR merges between this PR and G1.
- [ ] Release PR: after the merge, `chore(main): release 2.0.0-beta.1` appears within one `release.yml` run. No PR, or an `alpha` title, means the footer was lost: edit the merged PR body with `BEGIN_COMMIT_OVERRIDE` (conventional header plus the footer) and re-run the workflow; never merge an alpha release PR. Merge the release PR with a plain squash once its title names `2.0.0-beta.1`.
- [ ] G1: `v2.0.0-beta.1` is on GHCR. `publish-cue` succeeded; in a scratch module, `cue mod get opmodel.dev/core@v2.0.0-beta.1` resolves and a minimal `#Module` evaluates (`schema-release`, "The published artifact is verified to resolve"). A failed publish after tagging moves the target to `2.0.0-beta.2`; no hand tagging or publishing.

## 1. Policy text: the constitution and AGENTS.md

- [ ] 1.1 Baseline. Run the gates on the untouched tree and verify all pass. Run `openspec validate adopt-beta-release-line --strict --no-interactive` and verify it prints `is valid`.
- [ ] 1.2 `openspec/config.yaml` Principle IV: apply the three D5 rows (the `@v2` bullet with the canonical promise, the crossing bullet at `beta`, the new type-change/GA bullet). Keep the YAML block scalar indentation (two spaces inside `context: |`). Verify: `grep -n -e 'alpha' openspec/config.yaml` prints nothing, and `python3 -c 'import yaml,sys; yaml.safe_load(open("openspec/config.yaml"))'` exits 0.
- [ ] 1.3 `openspec/config.yaml` Commit Conventions `feat!:` bullet, the new `feat:`/`fix:` prerelease bullet (D4), and the `rules.proposal` Principle IV rule (D5 rows). Verify: `openspec instructions proposal --change adopt-beta-release-line` shows the new rule text and no `Rules for 'proposal' must be an array of strings` warning.
- [ ] 1.4 `AGENTS.md`: the branch table `main` row, the Repository Rules prerelease bullet (full rewrite per D5, with the canonical promise and the D4 sentence), and the commit table `feat!:` row. Verify: `grep -n -e '-alpha' -e 'alpha counter' AGENTS.md` prints nothing, and the rewritten bullet names `prerelease-type: "beta"`, `Release-As: X.0.0-beta.1`, the owner sign-off for a `catalogs/opm` major, and the GA clause.
- [ ] 1.5 Gates green, then commit `docs: state the beta promise in the constitution and AGENTS.md` (hidden type, cuts nothing). Stage only `openspec/config.yaml`, `AGENTS.md` and this `tasks.md`. Verify `git status --short` prints nothing.

## 2. Published docs: README, publishing notes, versions page

- [ ] 2.1 `README.md` ~7, ~31, ~40 per D5 (including the `@v1` stable-at-`v1.1.0` correction on ~7). Verify: `grep -n 'alpha' README.md` prints nothing.
- [ ] 2.2 `docs/publishing.md` ~5, ~7, ~66, ~72, ~79, ~106, ~124 per D5; leave ~67, ~77, ~118. The ~106 rewrite states that prereleases are excluded from `@latest` and major-only queries only when the major has a stable release, and that `@v2` today resolves to its highest prerelease. Verify: `grep -n 'alpha' docs/publishing.md` lists only the three kept lines plus the `v2.0.0-alpha.1` term in the ~72 ordering example; the anchor `#why-branch-builds-carry-a-leading-0` matches the heading `## Why branch builds carry a leading \`0\``.
- [ ] 2.3 `docs/site/concepts/versions.md` planning comments ~13, ~29 ("The core schema major") and ~93 ("convention:") per D5. Change no front matter and no heading (workspace `STYLE.md` Site Pages). Verify: `head -6 docs/site/concepts/versions.md` is unchanged against `origin/main`; `grep -n 'promises nothing yet' docs/site/concepts/versions.md` prints nothing; `grep -rn -e '^sidebar:' -e ':::' docs/site` prints nothing.
- [ ] 2.4 Gates green, then commit `docs: move the README, publishing notes and versions page to the beta line`. Stage only the three files and this `tasks.md`. Verify `git status --short` prints nothing.

## 3. Tooling comments

- [ ] 3.1 Load `<wt>/.claude/skills/core-schema-edit/SKILL.md` before touching `src/cue.mod/module.cue` (core Principle II; a comment edit counts).
- [ ] 3.2 `src/cue.mod/module.cue`: the one comment line per D5. Verify: `git diff -U0 src/cue.mod/module.cue` shows comment lines only; `task vet` passes.
- [ ] 3.3 `Taskfile.yml` `publish` desc, `.tasks/branch-tag.sh` ~78-80 and ~98, `.github/workflows/release.yml` ~88, per D5. Verify: `bash -n .tasks/branch-tag.sh` exits 0; `task --list-all >/dev/null` exits 0; `python3 -c 'import yaml; yaml.safe_load(open(".github/workflows/release.yml"))'` exits 0; `git diff -U0 -- Taskfile.yml .tasks .github` shows only comment or `desc:` lines.
- [ ] 3.4 Gates green, then commit `chore: name the beta line in tooling comments` with `SPEC_IMPACT=none git commit ...` and the body line `Spec-Impact: none (comment-only edit to src/cue.mod/module.cue)`. Stage only the four files and this `tasks.md`. Verify `git status --short` prints nothing.

## 4. Flip, verify, archive: the carrier commit

- [ ] 4.1 `release-please-config.json`: `"prerelease-type": "alpha"` becomes `"prerelease-type": "beta"`, nothing else. Verify: `jq -r '.packages["."]["prerelease-type"]' release-please-config.json` prints `beta`; `grep -ci 'release-as' release-please-config.json` prints `0`; `git diff --quiet origin/main -- .release-please-manifest.json CHANGELOG.md` exits 0.
- [ ] 4.2 Residual sweep. Run `git grep -n -i 'alpha' -- ':!CHANGELOG.md' ':!openspec/changes' | grep -v -e 'v1alpha' -e 'alpha1'` and read every hit. Each remaining hit must be historical or a different ladder (design.md Non-Goals): `.release-please-manifest.json`, `SPEC.md` ~581, `docs/publishing.md` ~67/~72/~77/~118, `.tasks/branch-tag.sh` ~83/~98, `src/cue.mod/module.cue` "alpha until", `src/*_pins.cue`, `src/types.cue`, `docs/site/concepts/platforms-and-catalogs.md`, `what-enforces-a-rule.md`, the `versions.md` contract-level and catalog-release text, and `openspec/specs` (the partial-tag requirement and unrelated specs). Any other hit is fixed before 4.3.
- [ ] 4.3 Gates green on the whole tree, and `openspec validate adopt-beta-release-line --strict --no-interactive` prints `is valid`.
- [ ] 4.4 Verify the implementation by following `<wt>/.claude/skills/openspec-verify-change/SKILL.md` for `adopt-beta-release-line` (never the root `/opsx:verify` router). Fix every CRITICAL finding; list WARNING and SUGGESTION findings in the report.
- [ ] 4.5 Tick 4.1 to 4.5, then archive: `openspec archive adopt-beta-release-line --yes` (not `--skip-specs`). Verify: `openspec/changes/archive/<date>-adopt-beta-release-line/` exists and `openspec/changes/adopt-beta-release-line` does not; `grep -c 'A line changes prerelease type or goes stable only through a forced carrier commit' openspec/specs/schema-release/spec.md` prints `1`; `grep -c 'A break does not move the module path by itself' openspec/specs/schema-release/spec.md` prints `1`; the partial-tag requirement is unchanged (`git diff origin/main -- openspec/specs/schema-release/spec.md` touches none of its lines); `openspec validate --specs --strict --no-interactive` passes.
- [ ] 4.6 Write the carrier message to `<scratch>/carrier-msg.txt`, exactly:

  ```text
  chore(release): adopt the beta release line

  Flip prerelease-type to beta and move the constitution, AGENTS.md,
  the README, the publishing notes and the versions page to the beta
  promise. From its first beta the v2 line is on the path to GA: a
  break is still allowed, only as a feat! commit whose breaking-change
  footer is the migration note, and it advances the beta counter
  without moving the module path. The schema-release spec gains the
  rule that a prerelease type change or GA is forced by a Release-As
  footer. The schema bytes equal v2.0.0-alpha.13.

  Release-As: 2.0.0-beta.1
  Co-Authored-By: Claude <noreply@anthropic.com>
  ```

  Verify: `grep -n '@' <scratch>/carrier-msg.txt` prints only the `Co-Authored-By` line; `tail -n +2 <scratch>/carrier-msg.txt | grep -nE '^[A-Za-z0-9_.-]+\('` prints nothing; `grep -n 'BREAKING' <scratch>/carrier-msg.txt` prints nothing; the last two lines are the footer and the trailer, in that order.
- [ ] 4.7 Tick 4.6 and 4.7 in the archived `tasks.md`, stage `release-please-config.json`, the archive move (`git add -A -- openspec/changes openspec/specs`) and nothing else, run the gates once more, then `git commit -F <scratch>/carrier-msg.txt`. This is the carrier commit and the last commit on the branch. Verify: `git log -1 --format=%B | diff - <scratch>/carrier-msg.txt` prints nothing (a trailing blank line aside); `git show --name-status --format= HEAD` lists only `release-please-config.json`, `openspec/specs/schema-release/spec.md` and the archive rename; `git status --short` prints nothing.

## 5. Open the PR

These boxes are not ticked in the tree: the archived `tasks.md` is already committed, and nothing may follow the carrier commit. The worker reports them; the supervisor tracks them.

- [ ] 5.1 Push: `git push -u origin beta/adopt-beta-release-line`. Verify the branch-publish workflow runs (it publishes a `-0.dev.` tag; that is expected).
- [ ] 5.2 Open the PR with title `chore(release): adopt the beta release line` and this body (prose under 250 words; the `Spec-Impact` line is required by the CI co-update gate because `src/cue.mod/module.cue` changes):

  ```text
  Core's beta carrier. Squash it with the branch's last commit message: its final paragraph is `Release-As: 2.0.0-beta.1`, and the expected release PR is `chore(main): release 2.0.0-beta.1`, with the same schema bytes as `v2.0.0-alpha.13`.

  Why a footer: flipping `prerelease-type` alone cuts nothing. release-please keeps the `alpha` label on a type change, and every commit since alpha.13 is a hidden type, so without the footer no release PR opens at all.

  Where to look first: Principle IV in `openspec/config.yaml` and the synced `schema-release` spec. They state the beta promise the library, catalog, cli and operator changes copy.

  Risk: a squash message that loses the footer, or gains a body line starting with an identifier and `(`, cuts nothing. Downstream beta cuts wait on `v2.0.0-beta.1` being on GHCR.

  Spec-Impact: none (the only .cue edit is a comment in src/cue.mod/module.cue)
  ```

  Verify before creating: every `@` in title and body is inside backticks or glued to a word character (the body has none); `gh pr create` succeeds; the `mention-guard` and `ci` checks start.
- [ ] 5.3 Report to the supervisor: PR number and URL, the carrier message file path, squash type `chore(release)`, carrier yes, footer `Release-As: 2.0.0-beta.1`, merge gate none, expected release PR `chore(main): release 2.0.0-beta.1`. Never merge this PR or the release PR.
