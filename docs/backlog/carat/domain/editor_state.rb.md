# Backlog: carat/domain/editor_state.rb

## Search echoes fill the message history

- Where: `carat/domain/editor_state.rb` line 135 (`show`), reached by the `/pattern` echo of `n`, `N`, `*`, and `#`, at the `feedback` change. Quality advisory of `feedback`.
- Why it matters: Neovim does not keep the search echo in `:messages`, so 500 presses of `n` evict every real error, and the deviation is not in the compatibility notes.
- Fix outline: show the search echo through `show_output`, or list the deviation under Messages and notifications in `docs/compatibility.md`, with a row pressing `n` after an error.
- Also: docs/compatibility.md
- Category: editor
- Added: 2026-11-09

## The message history is built inside EditorState, not the assembly

- Where: `carat/domain/editor_state.rb` line 42, shared with the notices as `state.history`, at 31919d9. Periodic quality. Queue item `messages-tidy`.
- Why it matters: CLAUDE.md requires everything shared to be built once in `EditorAssembly` and kept in a reader, so `test/adapters_assembly.rb` can check every holder got the one instance.
- Fix outline: build it in `carat/adapters/editor_assembly.rb` with a reader, pass it to both holders, and add the identity row.
- Also: CLAUDE.md, test/adapters_assembly.rb, carat/adapters/editor_assembly.rb
- Category: editor
- Added: 2026-11-09

## The message history name and a doubled clear

- Where: `carat/domain/editor_state.rb` line 20 and `carat/domain/notices.rb` line 76 (`history` holds a `MessageHistory`), `carat/use_cases/handle_key.rb` line 201 (`clear_message` twice per key), at df4654c. Periodic quality. Queue item `messages-tidy`.
- Why it matters: `state.history` reads as the command history; the clear runs twice on every key.
- Fix outline: rename to `message_history`; read the flag, clear once.
- Also: carat/domain/notices.rb, carat/use_cases/handle_key.rb
- Category: editor
- Added: 2026-11-09

## EditorState's class comment is wrapped unevenly

- Where: `carat/domain/editor_state.rb` line 13 (101 columns, lines 14 to 16 short and long in turn). Periodic quality at 186ddfb, blocking, queued in `periodic-blockers-b`.
- Why it matters: the layer's comments wrap at 72 columns.
- Fix outline: rewrap the class comment.
- Category: editor
- Added: 2026-11-10

### end_visual rewrites clamp_col

- Location: carat/domain/editor_state.rb:122, :97, comment lines 13 and 15 (sweep, quality).
- Why: end_visual writes clamp_col out again, and two comment lines pass the wrap.
- Fix outline: c.col = clamp_col(c.row, c.col) and rewrap.
- Category: editor
- Added: 2026-11-17

### Nothing produces a warning or information level, a -- More -- pager, or a match count
- Location: carat/domain/editor_state.rb, `show` (one bool, `message_error`); carat/adapters/frame_presenter.rb, `paint_message_text`
- Why: the Facet message styling names a yellow warning icon, a bold blue `-- More --`, and a dim match count; message-styling themes `WarningMsg` and `MoreMsg` but no code paints them, and every non-error message is drawn as information.
- Fix: give `EditorState#show` a level (error, warning, information) with a producer for the warning icon, add a pager that draws `-- More --` in `MoreMsg` for a listing taller than the screen, and paint the `search-count` text in `MsgDim` at the right edge of the row.
- Also: carat/adapters/frame_presenter.rb
- Category: editor
- Added: 2026-11-20

### carat/domain/editor_state.rb:124: duplication: end_visual re-implements clamp_col (:100) with max_col and a (sprint-22 sweep quality)

- Location: `carat/domain/editor_state.rb:124`
- Why: duplication: end_visual re-implements clamp_col (:100) with max_col and a comparison
- Fix: c.col = clamp_col(c.row, c.col)
- Category: editor
- Added: 2026-11-20

### A direct write of the command line text keeps the old cursor count
- Location: carat/domain/editor_state.rb (`cmdline_after`, `replace_cmdline`)
- Why: the cursor is the count of characters after it, so a text assigned with `state.cmdline =` after a cursor move keeps that count and the cursor lands inside the new text; every shipped writer uses `replace_cmdline`, but nothing forbids a later one
- Fix: have test/lint.rb refuse `.cmdline =` outside `carat/domain/editor_state.rb`, or make the writer reset the count
- Also: test/lint.rb
- Category: editor
- Added: 2026-11-21
