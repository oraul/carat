# Backlog: test/adapters_definitions.rb

## Definition commands lack a table-driven test

- Where: `test/adapters_definitions.rb` line 184 at fafe59c, which the `gd`, Ctrl-O, and Ctrl-I rows of `docs/compatibility.md` point at, a sequence of asserts. Quality advisory in `definitions`.
- Why it matters: CLAUDE.md asks a table-driven test of each Neovim command; the answer shapes (Location, list, LocationLink, escapes, relative, NUL, negative, non-file) fit a table and would be easier to extend.
- Fix outline: a `t.table` of answers to the position or message reached.
- Also: docs/compatibility.md, CLAUDE.md
- Category: code-quality
- Added: 2026-11-10

## An edited read-only gd target's unsaved-work errors have no test

- Where: `test/adapters_definitions.rb` line 406, the read-only target rows. Quality advisory in `gd-ghost-tab`.
- Why it matters: since `gd-ghost-tab` an edited read-only buffer counts as unsaved work (E37 on `gd`, Ctrl-O, `:e`, and `:b` away from it, E162 on quit), which the old scratch view never raised, so a regression in that behavior would pass the suite.
- Fix outline: after `x` in the read-only buffer, assert that `:bp` reports E37, `:q` reports E162, and `:e!` clears the modified flag.
- Category: code-quality
- Added: 2026-11-10

## Nothing proves the read-only gd target is synced with the language server

- Where: `test/adapters_definitions.rb` line 433. Quality advisory in `gd-ghost-tab`.
- Why it matters: the `gd-ghost-tab` proposal opens the read-only buffer to the server (didOpen) so `gd` follows on from it, but no test asserts the didOpen or a `gd` from inside it, so losing the sync would pass the suite.
- Fix outline: assert the fake server received didOpen for `/gems/c.rb` and that `gd` from that buffer visits a target.
- Category: code-quality
- Added: 2026-11-10

## The replace-jump tests leave three paths unchecked

- Where: `test/adapters_definitions.rb:516` and `:519`, `test/adapters_tab_bar.rb:96`, against `docs/compatibility.md:288` and `carat/adapters/tab_bar.rb:76`. Quality advisory of `jump-replace-tab`. Raised again at be4b63a (owner moved from `jump-list` to `buffer-list-tidy`).
- Why it matters: no row runs `:bd` after a replace jump to prove `BufferList#replacement_for` skips the unlisted buffer; no tab-bar row has an unlisted current buffer (the `anchor = first if anchor < 0 || current.tabless?` fallback) or unlisted buffers beside tab-page numbers; and the other `jump_case` rows read tabs through `tab_names`, which re-applies `Buffer#tabless?` instead of reading the painted row, while one block repeats the setup of the back-and-forth row to read it.
- Fix outline: a `jump_case` row running `:bd` with a second tabbed buffer; rows with current 0 and with pages 2 in the unlisted table; `r.frame.row_text(0)` in `jump_case`'s output and the separate block dropped. Queue item `buffer-list-tidy`.
- Also: test/adapters_tab_bar.rb, docs/compatibility.md, carat/adapters/tab_bar.rb
- Category: code-quality
- Added: 2026-11-10

### Quality advisory: unused resize helper in definitions and signature rigs (test/adapters_definitions.rb:39)

- Location: test/adapters_definitions.rb:39 and test/adapters_signature.rb:39
- Why: dead code; the resize helper and the @rows/@cols state are unused there, only adapters_hover calls resize.
- Fix: drop them from those two rigs.
- Also: test/adapters_signature.rb
- Category: code-quality
- Added: 2026-11-14
