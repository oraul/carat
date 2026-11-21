# Backlog: docs/actions.md

### The leader buffer list prints Vim's :ls line

- Location: the `buffer.list` action, `docs/actions.md:168` (`List the buffers as :ls does`).
- Why: `<Space>bb` prints `1 %a   "greet.rb"   line 3` on the message row, Vim's format with nothing to pick, while the buffer list is first in the user's UI order of `docs/goals.md` (ux-pass review finding 11). Reproduction: start on a file, `<Space>bb`, `openspec/changes/archive/*-ux-pass/screens/float-buffers.txt`.
- Fix: bind `<leader>bb` to a buffer picker float in the finder's style, `:ls` keeping Vim's output; a behavior change for planning to decide.
- Also: docs/goals.md
- Category: design
- Added: 2026-11-15
