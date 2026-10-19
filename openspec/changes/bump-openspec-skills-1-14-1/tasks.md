## 1. Regenerate skills

- [x] 1.1 Build pristine 1.12.0 and 1.14.1 skill output in a scratch directory, with no network.
- [x] 1.2 Run `openspec update --force` in the worktree; merge the `openspec-verify-change` edit with `git merge-file`.
- [x] 1.3 Confirm every generated skill is at `generatedBy: "1.14.1"` and `openspec-cleanup-change` and `openspec/config.yaml` are unchanged.

## 2. Verify

- [x] 2.1 Run `openspec validate --all --no-interactive` and `task check`.
- [x] 2.2 Scan the changed skills for hidden Unicode.
