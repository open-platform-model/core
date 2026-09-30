# Tasks

`<wt>` is `/var/home/emil/dev/open-platform-model/core/.claude/worktrees/beta-adopt-beta-release-line`, branch `beta/adopt-beta-release-line` from `origin/main` 748dfc7. `<scratch>` is the worker's scratch directory, outside any repo. Run every command as `cd <wt> && ...`; never edit the main checkout. Find each edit by its text (design.md D5), not by line number. Nothing under `src/` is edited, `src/cue.mod/module.cue` included (design.md Non-Goals); every section verifies `git diff --quiet origin/main -- src` exits 0.

**Gates in a worktree.** `task check` fails in any worktree on `src/INDEX.md` line 1 only (the title is built from the directory name; measured on the untouched tree). Wherever a task says "gates", run both: `task fmt:check vet spec:check docs:check` (stage first: `fmt:check` compares the working tree with the git index) and `bash .tasks/generate-index.sh "$(pwd)" | sed '1s/^# [^ ]* /# core /' | diff - src/INDEX.md` (prints nothing).

**Release-line grep.** `<alpha-grep>` below is `git grep -n -E -e '-alpha\.' -e '[Aa]lpha (line|counter|break|release tag)' -e 'newest alpha'`. It matches the release channel and skips `alphanumeric`, `v1alpha1` and the contract-level ladder. `<major-grep>` is `grep -n -i -E 'bumps the module major|moves the major'`.

**Delivery.** One PR, the core beta carrier. This change's stated deliverable is a release operation, so the push and PR steps are the `rules.tasks` sole exception in `openspec/config.yaml`; they sit in the unnumbered "After section 4 (delivery)" section, without checkboxes, so every numbered section closes with a commit task. The worker never merges anything.

| PR | Squash commit type | Carrier | Exact footer (final paragraph of the squash message) | Merge gate | Expected release PR |
| --- | --- | --- | --- | --- | --- |
| `chore(release): adopt the beta release line` | `chore(release)` | yes | `Release-As: 2.0.0-beta.1` then `Co-Authored-By: Claude <noreply@anthropic.com>` | none | `chore(main): release 2.0.0-beta.1` |

**Supervisor patches.** None. Core pins no upstream OPM release; no root task (`deps:update`, `deps:pins:*`) touches this change.

## Gates

Ticked by the supervisor, not by the worker, and outside every commit.

- [ ] Merge gate: none (owner decisions of 2026-09-30 are final). Before squashing, the supervisor confirms the squash subject equals the 4.6 subject plus ` (#N)` and the squash body is byte-identical to the 4.6 message from its third line on; that the message parses with release-please's parser to type `chore` and `Release-As` `2.0.0-beta.1`, carries no bare `@`, and has no body line starting with `word(`. No other core PR merges between this PR and G1.
- [ ] Release PR: after the merge, `chore(main): release 2.0.0-beta.1` appears within one `release.yml` run. No PR, or an `alpha` title, means the footer was lost: edit the merged PR body with `BEGIN_COMMIT_OVERRIDE` (conventional header plus the footer) and re-run the workflow; never merge an alpha release PR. Merge the release PR with a plain squash once its title names `2.0.0-beta.1`.
- [ ] G1: `v2.0.0-beta.1` is on GHCR. `publish-cue` succeeded; in a scratch module, `cue mod get opmodel.dev/core@v2.0.0-beta.1` resolves and a minimal `#Module` evaluates (`schema-release`, "The published artifact is verified to resolve"). A failed publish after tagging moves the target to `2.0.0-beta.2`; no hand tagging or publishing.

## 1. Policy text: the constitution and AGENTS.md

- [x] 1.1 Baseline. Run the gates on the untouched tree and verify all pass. Run `openspec validate adopt-beta-release-line --strict --no-interactive` and verify it prints `is valid`.
- [x] 1.2 `openspec/config.yaml` Principle IV: apply the four D5 rows (the "bumps the module major" bullet rescoped to after GA, the `@v2` bullet with the canonical promise, the crossing bullet as a stable-line act, the new type-change and GA bullet). Keep the YAML block scalar indentation (two spaces inside `context: |`). Verify: `sed -n '/### IV\./,/### V\./p' openspec/config.yaml | grep -n -i -w alpha` prints nothing; `<major-grep> openspec/config.yaml` prints nothing; every line `grep -n -i 'cross' openspec/config.yaml` prints is scoped to after GA or states that beta does not cross; `python3 -c 'import yaml,sys; yaml.safe_load(open("openspec/config.yaml"))'` exits 0.
- [x] 1.3 `openspec/config.yaml` Commit Conventions `feat!:` bullet, the new `feat:`/`fix:` prerelease bullet (D4), and the `rules.proposal` Principle IV rule (D5 rows). Verify: `grep -n -i -w alpha openspec/config.yaml` prints nothing; `openspec instructions proposal --change adopt-beta-release-line` shows the new rule text and no `Rules for 'proposal' must be an array of strings` warning.
- [x] 1.4 `AGENTS.md`: the branch table `main` row, the Repository Rules prerelease bullet (full rewrite per D5, with the canonical promise and the D4 sentence), the module-root paragraph (~146), and the commit table `feat!:` row. Verify: `grep -n -e '-alpha' -e 'alpha counter' AGENTS.md` prints nothing; `<major-grep> AGENTS.md` prints nothing; the rewritten bullet names `prerelease-type: "beta"`, the owner sign-off for a `catalogs/opm` major, "never crosses a major" during beta, a crossing only after GA, and the GA clause (`prerelease: false` plus a visible carrier commit); no `X.0.0-beta.1` crossing example remains (`grep -n 'X.0.0-beta' AGENTS.md` prints nothing).
- [x] 1.5 Gates green, `git diff --quiet origin/main -- src` exits 0, then commit `docs(policy): state the beta promise in the constitution and AGENTS.md` (hidden type, cuts nothing). Stage only `openspec/config.yaml`, `AGENTS.md` and this `tasks.md`. Verify `git status --short` prints nothing.

## 2. Published docs: README, publishing notes, versions page

- [ ] 2.1 `README.md` ~7, ~13, ~31, ~40 per D5 (including the `@v1` stable-at-`v1.1.0` correction on ~7 and the inert `vX.Y.Z` publish example on ~40). Verify: `grep -n -w 'alpha' README.md` prints nothing; `<major-grep> README.md` prints nothing; `grep -n 'VERSION=' README.md` prints only the `VERSION=vX.Y.Z` line; `grep -n 'beta\.1' README.md` prints nothing (no real upcoming version is named).
- [ ] 2.2 `docs/publishing.md` ~5, ~7, ~53, ~66, ~72, ~79, ~106, ~124 per D5; leave ~67, ~77, ~118. The ~106 rewrite states that prereleases are excluded from `@latest` and major-only queries only when the major has a stable release, and that `@v2` today resolves to its highest prerelease. Verify: `<alpha-grep> -- docs/publishing.md` lists exactly the kept lines ~67 and ~118 and the `v2.0.0-alpha.1` term of the ~72 ordering example; `grep -n -w alpha docs/publishing.md` additionally lists only ~5 ("alpha before"), ~53 ("the alpha, beta or rc release channels"), ~66 ("alpha and beta") and the kept ~77 (`v1.1.0-alpha`); `grep -n 'future `rc`' docs/publishing.md` prints nothing; the anchor `#why-branch-builds-carry-a-leading-0` matches the heading `## Why branch builds carry a leading \`0\``.
- [ ] 2.3 `docs/site/concepts/versions.md` planning comments ~13, ~29 ("The core schema major", both its first sentence and the promise sentence) and ~93 ("convention:") per D5. Change no front matter and no heading (workspace `STYLE.md` Site Pages). Verify: `git diff origin/main -- docs/site/concepts/versions.md | head -20` shows no change in the first 6 lines; `grep -n 'promises nothing yet' docs/site/concepts/versions.md` prints nothing; `<major-grep> docs/site/concepts/versions.md` prints nothing; `grep -rn -e '^sidebar:' -e ':::' docs/site` prints nothing.
- [ ] 2.4 Gates green, `git diff --quiet origin/main -- src` exits 0, then commit `docs(publishing): move the README, publishing notes and versions page to the beta line`. Stage only the three files and this `tasks.md`. Verify `git status --short` prints nothing.

## 3. Tooling comments

- [ ] 3.1 `Taskfile.yml` `publish` desc, `.tasks/branch-tag.sh` ~78-80 and ~98, `.github/workflows/release.yml` ~88, per D5. Verify: `bash -n .tasks/branch-tag.sh` exits 0; `task --list-all >/dev/null` exits 0; `grep -n 'VERSION=' Taskfile.yml | grep -v 'VERSION=vX.Y.Z'` prints nothing that names a version; `python3 -c 'import yaml; yaml.safe_load(open(".github/workflows/release.yml"))'` exits 0; `git diff -U0 -- Taskfile.yml .tasks .github` shows only comment or `desc:` lines.
- [ ] 3.2 Gates green, `git diff --quiet origin/main -- src` exits 0, then commit `chore(tooling): name the beta line in tooling comments`. No `.cue` file is staged, so the `SPEC.md` co-update hook does not apply and no `SPEC_IMPACT` escape is used. Stage only the three files and this `tasks.md`. Verify `git status --short` prints nothing.

## 4. Flip, verify, archive: the carrier commit

- [ ] 4.1 `release-please-config.json`: `"prerelease-type": "alpha"` becomes `"prerelease-type": "beta"`, nothing else. Verify: `jq -r '.packages["."]["prerelease-type"]' release-please-config.json` prints `beta`; `grep -ci 'release-as' release-please-config.json` prints `0`; `git diff --quiet origin/main -- .release-please-manifest.json CHANGELOG.md src` exits 0.
- [ ] 4.2 Residual sweep. Run `<alpha-grep> -- ':!CHANGELOG.md' ':!openspec/changes' ':!src'` and `git grep -n -i -E 'bumps the module major|moves the major' -- ':!CHANGELOG.md' ':!openspec/changes' ':!src'`, and read every hit. `src/` is excluded because it is never edited (4.1 checks it is unchanged). Expected hits, all historical or another versioning scheme: `.release-please-manifest.json`; `.tasks/branch-tag.sh` ~83 and the alpha term of ~98; `SPEC.md` ~581 and ~941; `docs/publishing.md` ~67, ~72 (alpha term), ~118; `docs/site/concepts/platforms-and-catalogs.md`; `docs/site/concepts/versions.md` ~21 (the release-prerelease gate list), ~63 (a catalog release example) and ~93 ("the alpha line took breaking changes"); `openspec/specs/platform-registry/spec.md` (catalog build `1.0.0-alpha.2`); `openspec/specs/schema-release/spec.md` until 4.5 syncs it, then only the partial-tag requirement. The major grep prints nothing. Any other hit is fixed now, in a non-`src/` file only; 4.7 stages the fix and lists it.
- [ ] 4.3 Gates green on the whole tree, and `openspec validate adopt-beta-release-line --strict --no-interactive` prints `is valid`.
- [ ] 4.4 Verify the implementation by following `<wt>/.claude/skills/openspec-verify-change/SKILL.md` for `adopt-beta-release-line` (never the root `/opsx:verify` router). The skill raises a CRITICAL for every open checkbox; at this point the three `## Gates` items and 4.4 to 4.7 are open by design, so those CRITICALs are expected and exempt. Fix every other CRITICAL finding (in a non-`src/` file only; 4.7 stages the fix and lists it); list WARNING and SUGGESTION findings in the report.
- [ ] 4.5 Tick 4.1 to 4.5, then archive: `openspec archive adopt-beta-release-line --yes` (not `--skip-specs`). Then edit the `## Purpose` line of `openspec/specs/schema-release/spec.md` (the archive leaves it alone): "when a pre-stable break advances the prerelease versus bumps the module major" becomes "why a break on a prerelease line advances the prerelease and only a stable line crosses a major, how a line changes prerelease type or goes GA". Verify: `openspec/changes/archive/<date>-adopt-beta-release-line/` exists and `openspec/changes/adopt-beta-release-line` does not; `grep -c 'A break on a prerelease line advances the prerelease, and only a stable line crosses a major' openspec/specs/schema-release/spec.md` prints `1`; `grep -c 'defaults to advancing' openspec/specs/schema-release/spec.md` prints `0`; `grep -c 'A line changes prerelease type through a forced carrier commit and goes stable through a visible one' openspec/specs/schema-release/spec.md` prints `1`; `grep -c 'A module line change during beta is refused' openspec/specs/schema-release/spec.md` prints `1`; the four live scenario headings of the renamed requirement are still present verbatim; the partial-tag requirement is unchanged (`git diff origin/main -- openspec/specs/schema-release/spec.md` touches none of its lines); `openspec validate --specs --strict --no-interactive` passes.
- [ ] 4.6 Write the carrier message to `<scratch>/carrier-msg.txt`, exactly:

  ```text
  chore(release): adopt the beta release line

  Flip prerelease-type to beta and move the constitution, AGENTS.md,
  the README, the publishing notes and the versions page to the beta
  promise. From its first beta the v2 line is on the path to GA: a
  break is still allowed, only as a feat! commit whose breaking-change
  footer is the migration note, and it advances the beta counter
  without moving the module path. No major is crossed before GA. The
  schema-release spec gains the rule that a prerelease type change is
  forced by a Release-As footer. The schema package is unchanged since
  v2.0.0-alpha.13.

  Release-As: 2.0.0-beta.1
  Co-Authored-By: Claude <noreply@anthropic.com>
  ```

  Verify: `grep -n '@' <scratch>/carrier-msg.txt` prints only the `Co-Authored-By` line; `tail -n +2 <scratch>/carrier-msg.txt | grep -nE '^[A-Za-z0-9_.-]+\('` prints nothing; `grep -n 'BREAKING' <scratch>/carrier-msg.txt` prints nothing; the last two lines are the footer and the trailer, in that order.
- [ ] 4.7 Tick 4.6 and 4.7 in the archived `tasks.md`, stage `release-please-config.json`, the archive move (`git add -A -- openspec/changes openspec/specs`), any file fixed in 4.2 or 4.4 (never under `src/`), and nothing else. Run the gates once more, then `git commit -F <scratch>/carrier-msg.txt`. This is the carrier commit and the last commit on the branch. Verify: `git log -1 --format=%B | diff - <scratch>/carrier-msg.txt` prints nothing (a trailing blank line aside); `git show --name-status --format= HEAD` lists only `release-please-config.json`, `openspec/specs/schema-release/spec.md`, the archive rename and the 4.2/4.4 fix files, each of which the worker names in the report; `git diff --quiet origin/main -- src` exits 0; `git status --short` prints nothing.

## After section 4 (delivery)

No checkboxes here: the archived `tasks.md` is already committed, and nothing may follow the carrier commit. The worker does these steps and reports them; the supervisor tracks them.

- Push: `git push -u origin beta/adopt-beta-release-line`. Verify the branch-publish workflow runs (it publishes a `-0.dev.` tag; that is expected).
- Open the PR with title `chore(release): adopt the beta release line` and this body (prose under 250 words):

  ```text
  Core's beta carrier. Squash it with the branch's last commit message (subject plus the PR number): its final paragraph is `Release-As: 2.0.0-beta.1`, and the expected release PR is `chore(main): release 2.0.0-beta.1`. The schema package is unchanged since `v2.0.0-alpha.13`.

  Why a footer: flipping `prerelease-type` alone cuts nothing. release-please keeps the `alpha` label on a type change, and every commit since alpha.13 is a hidden type, so without the footer no release PR opens at all.

  Where to look first: Principle IV in `openspec/config.yaml` and the synced `schema-release` spec. They state the beta promise the library, catalog, cli and operator changes copy, including that the line crosses no major before GA.

  Risk: a squash message that loses the footer, or gains a body line starting with an identifier and `(`, cuts nothing. Downstream beta cuts wait on `v2.0.0-beta.1` being on GHCR.
  ```

  Verify before creating: every `@` in title and body is inside backticks or glued to a word character (the body has none); `gh pr create` succeeds; the `mention-guard` and `ci` checks start.
- Report to the supervisor: PR number and URL, the carrier message file path, squash type `chore(release)`, carrier yes, footer `Release-As: 2.0.0-beta.1`, merge gate none, expected release PR `chore(main): release 2.0.0-beta.1`, and any 4.2/4.4 fix files. Never merge this PR or the release PR.
