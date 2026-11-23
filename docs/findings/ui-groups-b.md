### StatusSlots lsp_label is no longer read by the bar
- Location: `carat/domain/status_slots.rb` (`lsp_label`, `label`), `test/adapters_language_gateway.rb:179`
- Why: the status bar draws the name, a dot, and `hint(state)` from `lsp_name` and `lsp_state`, so the record member and its state words are read only by the gateway tests and `set_lsp`'s change check.
- Fix: assert `lsp_state`, `hint`, and the progress percent in the gateway tests, then drop `lsp_label` and `label` from the record.
### Server states differ only by the dot's color
- Location: `carat/adapters/status_bar.rb` (`paint_lsp`, `lsp_group`)
- Why: starting, indexing, ready, and stopped are the same dot, so at 16 colors and under NO_COLOR, where the group colors collapse, they read alike; the crash and untrusted hints still name themselves.
- Fix: in the terminal-byte proof of NO_COLOR and 16 colors (`ui-groups-c`), decide whether the dot needs a second glyph for stopped.
### The folder cannot be dropped on a narrow bar
- Location: `carat/adapters/status_bar.rb` (`paint_file_name`, `fit`)
- Why: the folder is part of the file entry, which is never dropped, so a long path takes the width a narrow bar's other segments need before the file is cut.
- Fix: draw only the last segment of the path when the bar is narrow, or give the folder its own entry of low priority.
### The lsp group is computed twice per paint
- Location: `carat/adapters/status_bar.rb` (`paint_entry`, `paint_lsp`)
- Why: `paint_lsp` and the closing space in `paint_entry` each call `lsp_group`, a small duplication kept because returning the column and the group together would allocate each frame.
- Fix: keep the group in an integer instance variable that `paint_lsp` sets and `paint_entry` reads.
