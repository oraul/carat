fix(tabs): keep the file's tab selected while a sidebar has focus

## Summary

Keeps the file window's tab marked while a sidebar such as the explorer has focus. Before, the tab row selected the tab of the focused window's buffer, which is the sidebar's scratch buffer with no tab, so no tab looked selected although a file was still showing.

---

## Changes

- Fix the tab bar to select the tab of the editing window's buffer while a sidebar window has focus, leaving every other frame, a focused float included, on the current window's buffer
- Add a buffer-tabs scenario and a row in test/adapters_tab_bar.rb that focuses the explorer window and expects the file's tab in the selected group, with and without a previous window to name it
- Document the rule in the TabBar class comment, the README buffer tabs sentence, and the code map line

---

## Testing

- Run the fast stages on the contributor's commit (docs-lint, dev-build, test-build, test-run, gates, diagnose, bench-budget, tools-test, metrics), all pass
- Run the security review of the committed diff, no findings at any severity
- Run the benchmark review, passes with no blocking finding
- Run the spec validation after archiving the change, 56 items pass

---

## Notes

A focused float, such as the finder, is still the current window, so the tab mark under a float is unchanged; this is recorded as a follow-up in the findings file.
