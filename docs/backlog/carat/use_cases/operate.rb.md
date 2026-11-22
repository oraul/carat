# Backlog: carat/use_cases/operate.rb

## Operate passes the search outcome through an instance variable

- Where: `Operate#search_motion` in `carat/use_cases/operate.rb` (line 131), which sets `@notice` deep in `motion_for` for `call` to read. Quality advisory of `buffer-search` at 2b54295641e0 and again at a36858a2bc88. Raised again at 9a92265 (#99): the same side channel in `walk_history.rb` line 32.
- Why it matters: the outcome travels by a side channel in a use case instead of a return value, which is harder to follow and easy to leave stale when another path through `motion_for` is added.
- Fix outline: return the hit's outcome with the operand as a small result value, or have the operator handler run `FindMatch` first and pass the hit in. Queued in `search-structure`.
- Category: editor
- Added: 2026-11-04

## REGISTER_ONE_MOTIONS repeats the search action names

- Where: `REGISTER_ONE_MOTIONS` in `carat/use_cases/operate.rb` (line 47), which lists the eight search action names `Domain::Search` already lists. Quality advisory of `buffer-search` at 2b54295641e0 and again at a36858a2bc88.
- Why it matters: a search action added to `Domain::Search` and not to the list would delete within a line without writing register 1, unlike Vim.
- Fix outline: keep the four sentence and paragraph motions in the list and test `Domain::Search.action?(action)` beside it. Queued in `search-structure`.
- Category: editor
- Added: 2026-11-04

## Operate and RepeatLast each copy EditorState#clamp_col

- Where: the private `clamp(state, row, col)` in `carat/use_cases/operate.rb` (line 202 at `theme-tokens`) and `carat/use_cases/repeat_last.rb` (line 117), each `EditorState#clamp_col` in `carat/domain/editor_state.rb` (line 97) line for line. Periodic quality at 4c65f4e. Raised again at ce6abdb (`operate.rb:202`, `repeat_last.rb:116`; periodic quality), queue item `editing-counts`.
- Why it matters: three copies of one clamp must change together, and a fix to the domain's misses the two use cases.
- Fix outline: call `state.clamp_col(row, col)` at the six call sites and delete both private methods. Listed in the queue's backlog item.
- Raised again as "end_visual re-implements clamp_col": Where: `carat/domain/editor_state.rb` line 120 at c1b3a12 (periodic quality), beside the entry Operate and RepeatLast each copy EditorState#clamp_col. Queued in item 46. Why it matters: a third copy of the clamp. Fix outline: call clamp_col after the mode is set to normal.
- Also: carat/use_cases/repeat_last.rb, carat/domain/editor_state.rb
- Category: editor
- Added: 2026-11-05

## Small code findings of the b76b722 periodic review

- Where: `carat/use_cases/operate.rb` line 65 (dispatches on `command.operator` again; yank at lines 174 to 175 sets the cursor by hand); `carat.rb` line 288 (no `require_relative` of `carat/use_cases/actions/search_handler.rb`); `carat/use_cases/actions/motion_handler.rb` line 33 (the register loop over NAMES and DESCRIPTIONS copied 16 times under `carat/use_cases/actions/`); `carat/domain/control_text.rb` line 102 (calls `Utf8` but requires nothing); `carat/domain/filetype.rb` lines 29 and 45 (`from_name` and `from_shebang` answer strings, public helpers only `detect` calls); `carat/domain/syntax_table.rb` line 254 (`size` has no caller); `carat/plugins/ruby/tokenizer.rb` line 15 (says the terminator table only grows, but it stops at `LineState::MAX_TERMINATORS`). Queue item 42.
- Why it matters: a repeated dispatch, a require graph that no longer names every file, a 16-fold copy, a compile that depends on require order, the `from_x` naming rule bent, dead code, and a wrong comment.
- Fix outline: case on the bound operator and use `move_to`; add the require; one `ActionTable` method taking names, handler, and descriptions; `require_relative "utf8"`; rename the Filetype helpers and make them private; drop `size`; say the table grows up to its cap.
- Also: carat.rb, carat/use_cases/actions/search_handler.rb, carat/use_cases/actions/motion_handler.rb, carat/domain/control_text.rb, carat/domain/filetype.rb, carat/domain/syntax_table.rb, carat/plugins/ruby/tokenizer.rb
- Category: editor
- Added: 2026-11-09

## Operate dispatches with case on constants the pinned Spinel may fold

- Where: `carat/use_cases/operate.rb` line 65, `case`/`when` on `Domain::OperatorKind::DELETE` and `::INDENT`, String constants whose bare names are Integer constants elsewhere (`Key::DELETE`, `RcParser::DELETE`, `FormatDocs::INDENT`). Periodic quality blocking at e49f63d. Raised again at 9a92265 (#99 note 34).
- Why it matters: `docs/spinel-notes.md` (Known miscompilations, f34005bf) says the pinned Spinel folds this shape to false; it passes only by how the name resolves today, so a rename elsewhere silently breaks delete or indent.
- Fix outline: dispatch with `==` guards as `Mode.visual_kind` does, citing the note, with a row per operator kind. Queue item: `periodic-blockers-b`.
- Also: docs/spinel-notes.md
- Category: editor
- Added: 2026-11-10

### Operate and RepeatLast copy EditorState#clamp_col

- Location: carat/use_cases/operate.rb:204, carat/use_cases/repeat_last.rb:116, carat/domain/editor_state.rb:97 (sprint-4 sweep, quality).
- Why: two private clamps duplicate clamp_col.
- Fix: call state.clamp_col and delete both.
- Also: carat/use_cases/repeat_last.rb, carat/domain/editor_state.rb
- Category: editor
- Added: 2026-11-14

### Editing helpers repeat existing ones

- Location: carat/use_cases/operate.rb:204 and repeat_last.rb:117 (clamp repeats EditorState#clamp_col), carat/domain/operators.rb:271 (indent_width repeats DisplayWidth.column; the shift step written at :172 and :251), carat/use_cases/visual/put_over_selection.rb:126 (repeated duplicates Operators.put's loop at operators.rb:42) (sprint-8 sweep, quality); queued in `editing-dedup-a`.
- Why: four private copies of logic the domain already holds.
- Fix: call state.clamp_col, DisplayWidth.column, one shift-width helper, and one Operators function for repeated lines.
- Also: carat/domain/operators.rb, carat/use_cases/visual/put_over_selection.rb
- Category: editor
- Added: 2026-11-16

### Operate and RepeatLast copy clamp_col

- Location: carat/use_cases/operate.rb:204, repeat_last.rb:116 (sweep, quality).
- Why: both private clamp methods copy EditorState#clamp_col line for line.
- Fix outline: call state.clamp_col(row, col) and delete both.
- Category: editor
- Added: 2026-11-17

### Three private clamps repeat EditorState#clamp_col (sprint-16 sweep quality)

- Location: carat/use_cases/operate.rb:233, carat/use_cases/repeat_last.rb:116 (private clamp), carat/domain/editor_state.rb:123 (end_visual); clamp_col at editor_state.rb:97.
- Why: the clamp is copied line for line in 3 places beside the one EditorState method (LineCommandHandler#place_cursor goes in `vim-line-commands-c`).
- Fix outline: call clamp_col at each site and delete the two private clamp methods.
- Also: carat/use_cases/repeat_last.rb, carat/domain/editor_state.rb
- Category: editor
- Added: 2026-11-18

### Use cases re-implement clamp_col and wanted_col (sprint-18 sweep quality)
- Location: `carat/use_cases/operate.rb:233`, `:70`, `:205`; `carat/use_cases/repeat_last.rb:116`; `carat/domain/editor_state.rb:126`; `carat/use_cases/ex/line_command_handler.rb:54`.
- Why it matters: private `clamp` copies and `end_visual` repeat `EditorState#clamp_col` (`editor_state.rb:100`); `place_cursor` repeats `Motions.wanted_col` (`motions.rb:247`); `yank` writes the cursor directly where siblings use `move_to`.
- Fix outline: call `state.clamp_col` and `Motions.wanted_col`, `case operator`, `cursor.move_to` in yank.
- Also: carat/use_cases/repeat_last.rb, carat/domain/editor_state.rb, carat/use_cases/ex/line_command_handler.rb
- Category: editor
- Added: 2026-11-18

### Operate keeps per-call state in @notice (sprint-20 sweep quality, operate.rb:46)

- Location: `carat/use_cases/operate.rb:46`
- Why: Operate keeps per-call state in @notice: search_motion sets it and call resets it, so a use case built once in EditorAssembly carries a mutable result between private methods
- Fix: return the search outcome with the motion (for example a small result value, or operand returning the failure Outcome) and drop the instance variable
- Category: editor
- Added: 2026-11-19

### carat/use_cases/operate.rb:247: private clamp(state, row, col) and its copy at carat/use_cases/repeat_last.rb:117 (sprint-22 sweep quality)

- Location: `carat/use_cases/operate.rb:247`
- Why: private clamp(state, row, col) and its copy at carat/use_cases/repeat_last.rb:117 duplicate EditorState#clamp_col (carat/domain/editor_state.rb:100), which ToggleCase and PutOverSelection already call
- Fix: call state.clamp_col(row, col) and delete both private methods
- Also: carat/use_cases/repeat_last.rb, carat/domain/editor_state.rb
- Category: editor
- Added: 2026-11-20

### Operate and RepeatLast restate EditorState#clamp_col (sprint-24 sweep quality)

- Location: `carat/use_cases/operate.rb:247`, `carat/use_cases/repeat_last.rb:117`, `carat/domain/editor_state.rb:100`
- Why: two private clamp methods copy `clamp_col`, which ChangeFolds already calls.
- Fix: call `state.clamp_col(row, col)` at the eight call sites and delete both.
- Also: carat/use_cases/repeat_last.rb, carat/domain/editor_state.rb
- Category: editor
- Added: 2026-11-21

### Operate#big? tests an operator every caller has (sprint-24 sweep quality)

- Location: `carat/use_cases/operate.rb:225`, `:61`, `:71`
- Why: every caller reaches Operate with an operator, and call switches on `command.operator` beside the local it read.
- Fix: drop the `empty?` test and use the local operator in the case.
- Category: editor
- Added: 2026-11-21

### duplication: the private clamp(state, row, col) here and in at carat/use_cases/operate.rb:262 (sprint-26 sweep quality, note 22)

- Location: carat/use_cases/operate.rb:262
- Why: duplication: the private clamp(state, row, col) here and in carat/use_cases/repeat_last.rb:117 are EditorState#clamp_col verbatim
- Fix: call state.clamp_col(row, col) and delete both copies
- Also: carat/use_cases/repeat_last.rb
- Category: editor
- Added: 2026-11-22

### consistency: the linewise yank assigns cursor.row and cursor.col directly at carat/use_cases/operate.rb:212 (sprint-26 sweep quality, note 29)

- Location: carat/use_cases/operate.rb:212
- Why: consistency: the linewise yank assigns cursor.row and cursor.col directly while every other branch of Operate uses cursor.move_to, so the wanted column is left as it was
- Fix: cursor.move_to(range.from.row, clamp_col(...)), or a comment saying the kept wanted column is intended
- Category: editor
- Added: 2026-11-22

### clamp duplicates EditorState#clamp_col at carat/use_cases/operate.rb:262 (sprint-28 sweep quality, note 22)

- Location: carat/use_cases/operate.rb:262; carat/use_cases/repeat_last.rb:117
- Why: two private copies of a method PutOverSelection and GlobalCommand already call.
- Fix: call state.clamp_col and remove both.
- Also: carat/use_cases/repeat_last.rb
- Category: editor
- Added: 2026-11-22
