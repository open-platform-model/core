## 1. Rules

- [ ] 1.1 `openspec/config.yaml`: add `references:` for `opm-enhancements` with its remote; replace the comment bullets for the `NNNN:Dn` form with the comment rule; set the proposal rule to the `Delivers` line (`## Enhancement`, `Delivers NNNN, task X.Y.` per task, otherwise `None.`); add a `context` line to read an entry with `openspec show <id>-<slug> --store opm-enhancements`; remove the `enhancement.yaml` and `task enhancements:delivery:*` rules; change the specs rule so a citation is an id beside a reason.
- [ ] 1.2 `AGENTS.md`: the same rule text (comment rule, `Delivers` line); remove the `enhancement.yaml` and `delivery:log` text; reword the two history lines that name decision numbers.
- [ ] 1.3 `openspec validate align-enhancement-store --strict` passes, then commit `docs(openspec): move the enhancement rules into config.yaml`

## 2. Mechanical rewrite

- [ ] 2.1 Run `enh cite-rewrite --root <worktree> --write --worklist <file>` once over the clean tree.
- [ ] 2.2 Read at least 40 of the tool's edits across the places; fix a wrong edit by hand and record it in the report.
- [ ] 2.3 Commit by place: code comments (`SPEC_IMPACT=none`, comment text only), live specs, `SPEC.md` and `docs/`, archived changes (`docs(openspec)`); delete the nine `enhancement.yaml` files in the archived commit.

## 3. The worklist

- [ ] 3.1 Rewrite the code rows by hand (lone WHY labels, ids inside sentences, question ids, entry paths, strings), each by the comment rule.
- [ ] 3.2 Rewrite the rows in `SPEC.md`, `docs/`, live specs and archived text; keep "Renamed from" in the `SPEC.md` breadcrumbs.
- [ ] 3.3 Run `task generate:index`. `task check` is green. `enh cite-lint` reports 0 findings and `enh cite-rewrite --dry-run` reports 0 edits. Commit by place.

## 4. Verify and archive

- [ ] 4.1 `openspec validate align-enhancement-store --strict`; review; fix findings.
- [ ] 4.2 Archive the change on this branch and commit `docs(openspec): archive align-enhancement-store`.
