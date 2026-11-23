feat(render): draw the visual indicators in ModeMsg and prove the bar's bytes

## Summary

Draws the visual mode indicators in the ModeMsg group and removes the MoreMsg group, and proves the status bar's bytes at 16 colors, at 256 colors, and under NO_COLOR in a pty smoke case. A theme could set ModeMsg and MoreMsg with no effect on screen, and the bytes a terminal receives for the bar were only checked as group ids.

The 16-color case starts the editor at a basic terminal name, since a bare xterm is detected as 256 colors, and the child gets an empty COLORTERM so an inherited truecolor value cannot override it.

---

## Changes

- Draw the three visual indicators in ModeMsg, as Neovim's mode message does, instead of the dim message group
- Remove MoreMsg and its theme row, since carat has no pager to draw it; the group ids after it move down by one and the count becomes 118
- Add pty smoke cases at 16 colors, at 256 colors, and under NO_COLOR comparing the bytes written for the bar's file name and file type, which are real sequences of the depth and differ
- Start the gates stage after test-run in a check, so the snapshot gate and the smoke test no longer write the same output files at once, and prove the order in the tools test
- Update the README, the compatibility document, and the code map for the indicator and the removed group
- Sync the screen-rendering, color-themes, and status-bar specs and archive the change

---

## Testing

- Security review of the committed diff, no finding at any severity, none blocking
- Benchmark review, no blocking finding
- Run the check stages at the reviewed head (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics), all pass
- Run the spec validation, 56 of 56 pass

---

## Notes

A pager that draws MoreMsg and a warning icon painter are left out. The earlier design text said NO_COLOR writes no color; the bytes show bold and reverse remain, which the design now states.
