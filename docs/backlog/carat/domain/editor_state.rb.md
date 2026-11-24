# Backlog: carat/domain/editor_state.rb

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

### the class comment lines 13 and 16 run far at carat/domain/editor_state.rb:13 (sprint-26 sweep quality, note 8)

- Location: carat/domain/editor_state.rb:13
- Why: the class comment lines 13 and 16 run far past the wrap of the rest, end_visual (editor_state.rb:153) repeats clamp_col, and the map line of area 4 omits replace_cmdline and cmdline_position
- Fix: rewrap, set c.col = clamp_col(c.row, c.col), and add the two methods to the EditorState line of docs/codebase-map.md
- Also: docs/codebase-map.md
- Category: editor
- Added: 2026-11-22
