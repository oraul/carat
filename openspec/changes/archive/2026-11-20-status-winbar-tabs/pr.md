refactor(status): read one no-name word and test the status bar rows

## Summary

Defines the no-name word once and adds frame-row tests for the status bar in both themes and under ascii icons. A change of the word needed five edits, and the status bar's look had no test reading its row per theme. This is part a of the queue item; the winbar and tab styling and the lh-winbar check are left for status-winbar-tabs-b.

---

## Changes

- Add Messages::NO_NAME as the one word for a buffer with no path or title, read by StatusBar, Winbar, TabBar, ListBuffers, and Messages.unsaved_buffer with the shown text unchanged
- Add status bar frame-row tests in carat-dark, carat-light, and option.icons ascii checking the pill, file, and fill groups and the theme colors
- Change the unnamed rows of the status bar and tab bar tests to build their text from the constant
- Document NO_NAME in the code map entry for Messages

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low findings
- Run the quality review, pass with no blocking findings
- Run the benchmark review, pass with no blocking findings
- Run the checker stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, and tools-test, all exit 0 at the reviewed commit

---

## Notes

The remaining styling of the winbar and the tabs and the lh-winbar check are the follow-up status-winbar-tabs-b. README.md is unchanged because no behavior or file changes.
