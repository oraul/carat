# Backlog: test/adapters_pathless_language.rb

## The pathless sync row starts its window after the file type is set

- Where: `test/adapters_pathless_language.rb` line 88 at 2ccf124: the sync row counts the sent methods only from after `:set filetype=ruby` and two idle ticks. Quality advisory in `docs-nil-path`.
- Why it matters: a didOpen sent for the pathless buffer at the first sync after the file type is set falls outside the window, so the row does not prove on its own that the buffer is never opened (a later didChange would still show it).
- Fix outline: take `from = r.processes.bodies.length` before typing `:new<CR>`, so the window covers every sync of the pathless buffer.
- Category: ide
- Added: 2026-11-09
