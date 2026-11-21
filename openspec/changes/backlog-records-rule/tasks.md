## 1. Records rule

- [ ] 1.1 Add `docs/backlog/.+\.md$` to `RECORDS_RE` and name the backlog folder in its comment (`tools/rules.sh`); proven by the `rules: RECORDS_RE` cases of `tools/tools_test.sh` for `docs/backlog.md`, `docs/backlog/_general.md`, `docs/backlog/carat/adapters/tab_bar.rb.md` (records) and `docs/backlogs.md`, `docs/backlog/x.txt` (not)
- [ ] 1.2 Prove the readers take the folder's Markdown files as records: `settled_at` (gates security passes after a backlog-folder file, refuses after `docs/backlog/x.txt`), `TEST_ONLY` (check carries a stage after a backlog-folder commit, reruns after `docs/backlog/x.txt`), `outside_records` (`settled` passes), and `documentation` (`ci_scope` skips) in `tools/tools_test.sh`
