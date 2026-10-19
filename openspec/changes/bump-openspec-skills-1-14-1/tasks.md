## 1. Regenerate skills

- [ ] 1.1 Build pristine 1.12.0 and 1.14.1 skill output in a scratch directory, with no network.
- [ ] 1.2 Run `openspec update --force` in the worktree; merge the `openspec-verify-change` edit with `git merge-file`.
- [ ] 1.3 Confirm every generated skill is at `generatedBy: "1.14.1"` and `openspec-cleanup-change` and `openspec/config.yaml` are unchanged.

## 2. Verify

- [ ] 2.1 Run `openspec validate --all --no-interactive` and `task check`.
- [ ] 2.2 Scan the changed skills for hidden Unicode.
