## 1. Records rule

- [x] 1.1 Add `docs/backlog/.+\.md$` to `RECORDS_RE` and name the backlog folder in its comment (`tools/rules.sh`); proven by the `rules: RECORDS_RE` cases of `tools/tools_test.sh` for `docs/backlog.md`, `docs/backlog/_general.md`, `docs/backlog/carat/adapters/tab_bar.rb.md` (records) and `docs/backlogs.md`, `docs/backlog/x.txt` (not)
- [x] 1.2 Prove the readers take the folder's Markdown files as records: `settled_at` (gates security passes after a backlog-folder file, refuses after `docs/backlog/x.txt`), `TEST_ONLY` (check carries a stage after a backlog-folder commit, reruns after `docs/backlog/x.txt`), `outside_records` (`settled` passes), and `documentation` (`ci_scope` skips) in `tools/tools_test.sh`

## 2. Quality review

- [x] 2.1 Review the whole committed diff by `.claude/agents/quality-reviewer.md` steps 1 to 4 (inline, no sub-agents): no bug and no untested behavior change found; the five pattern cases, the security gate's three, the check's two, and the settled case fail with the regex reverted (1970 of 1981 against the reverted `tools/rules.sh`), the two `ci_scope` cases pass either way since `documentation()` already read every Markdown file as documentation, which the proposal states
