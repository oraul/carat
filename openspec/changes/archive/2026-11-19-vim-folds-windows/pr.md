fix(folds): open folds on insert and drop closed window folds

## Summary

Insert mode on a closed fold now opens the folds holding the cursor, and closing a window or tab page drops its folds, so folds and windows agree with Vim. Before, the edited line stayed hidden inside a closed fold, and a closed window left a dead fold list that the buffer kept shifting on every edit.

---

## Changes

- Open every closed fold holding the cursor when insert or replace mode starts, including a repeated insert replayed with dot, as Vim's foldOpenCursor does
- Drop the folds of a closed window, and of every window of a closed tab page including a kept hidden view window, so the buffer stops tracking them
- Add table rows to test/editor_folds.rb for zfjiX, a repeated insert, zfj followed by the split and close keys leaving one fold list, and :tabclose dropping a tab page's folds
- Update the folds and windows specs, docs/compatibility.md, and the README fold sentence
- Record in the proposal that the other two named places, Layout.close and Buffer.start_at, already match Vim and are unchanged
- Record four non-blocking findings in docs/findings/vim-folds-windows.md

---

## Testing

- Run the security review of the committed diff, pass with no High or Medium finding and one Low finding recorded
- Run the quality review, pass with no blocking finding and three advisory findings recorded
- Run the benchmark review, pass with no blocking finding
- Run the checker stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, and metrics, all pass
- Run spec-validate after archiving the change, all 54 items pass

---

## Notes

Replace mode opening folds has no test row because R is unbound in normal mode, which is left as a finding. The Low security finding about push --pr-text came in with the merge of main, not with this change, and is recorded as a finding.
