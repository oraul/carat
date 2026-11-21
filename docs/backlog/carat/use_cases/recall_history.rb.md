# Backlog: carat/use_cases/recall_history.rb

## The palette's prompt recalls the command history

- Where: `carat/use_cases/recall_history.rb` line 34 at 847851d; `keymap.cmdline` binds `<Up>` and `<Down>` to `cmdline.history_older` and `cmdline.history_newer`. Periodic quality. Queue item `discoverability-tidy`.
- Why it matters: at the palette's prompt they put `:` history into the filter text; the command-palette spec says nothing of history.
- Fix outline: answer nothing or move the selection while the palette is active, with an `editor_palette` row for `<Up>`.
- Category: editor
- Added: 2026-11-09
