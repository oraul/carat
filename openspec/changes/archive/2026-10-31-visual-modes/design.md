# Design

## Context

See proposal.md for motivation. Today `HandleKey` runs normal and operator-pending keys through `CommandGrammar`, which classifies an action by its name and produces a `Command`; `Dispatcher` routes operator commands to `Operate`, motions to `Move`, and the rest by name, and answers "Not implemented" to `mode.visual`, `mode.visual_line`, and `mode.visual_block`. `Motions` and `TextObjects` are pure functions of the state and a count that read `state.cursor`; `Operators` holds the buffer work over a charwise or linewise `Range`; `RegisterEntry` is `Data.define(:text, :linewise)`. `EditorState#max_col` lets the cursor rest after the last character only in insert mode. A `Window` is a `Struct` with its buffer, cursor, scroll, rectangle, and fixed-width flag; the frame presenter paints each window's lines with tabs expanded on display columns computed in the presenter, and the mode line knows only `-- INSERT --`. `docs/architecture.md` names `Selection` as an entity resolving anchor and head to a range by the visual kind, and `StartVisual`, `ExtendVisual`, and `OperateOnSelection` as the visual use cases under `carat/use_cases/visual/`.

The Spinel facts recorded by the earlier designs shape the representation: `Array[T]` pins only with a builtin `T`, so an `Array[untyped]` of `Data` values leaks `untyped`; a local holding two types widens a method for the whole program; a method of a `Data` instance read from a `Hash` member cannot be reached by dynamic dispatch, so `RegisterEntry.joined` stays a class method with typed parameters; block-form `Data.define` and `Struct.new` ignore inline RBS; an empty array literal is `Array[Integer]` unless stored through a writer after `super()`; an empty array literal held in a local and passed to another method is copied, so results are built on the way back up; `Array[Symbol]` is not pinned; `# @rbs @member` pins apply to a `Data` subclass only when its body holds a statement; a nullable local stays nullable after a nil check; there is no reflection and no computed `send`.

## Goals / Non-Goals

**Goals:**

- One key path: visual keys go through the keymap and the command grammar exactly as normal keys do, so counts, registers, motions, and text objects need no second parser, and every binding stays data in `config/default.json`.
- The selection is a domain value computed from the window and the state, so the operators, the presenter, and the domain tests resolve it the same way, including the block's display columns over tabs and wide characters.
- Every operator on the selection reuses the buffer work in `Operators` and the register writes of normal mode.
- `make diagnose` stays clean and `make types` shows no new `untyped` member.

**Non-Goals:**

- `:'<,'>` ranges, because `ExGrammar` parses no ranges yet; `:` stays unbound in visual mode so it cannot start a command line that would ignore the selection.
- The `'<` and `'>` marks: there are no marks yet. The window keeps the last selection, and the change that brings marks sets `'<` and `'>` from it.
- Undo and the dot command (roadmap item 4), `gq`, `g?`, `=`, `!`, `<C-a>`, `<C-x>`, `zf`, select mode, the mouse, `virtualedit`, and `selection=exclusive`.
- The plugin API's selection read and set requests, which `docs/architecture.md` section 9.1 lists; they are recorded in `docs/backlog.md`.
- A selection size in the showcmd area; only pending keys show there, as the task asks.

## Decisions

### The selection lives on the window and is resolved by a domain value

`Window` gains `anchor` (a `Position`) and `last_selection` (a `Selection`). The cursor end is the window's own cursor, and the kind is the mode, so the visual state cannot drift from what is drawn: `EditorState#selection` builds `Selection < Data.define(:anchor, :head, :kind, :to_end)` from the current window's anchor, its cursor, the kind for the mode (`:charwise`, `:linewise`, `:blockwise`, or `:none`), and `to_end`, true when the cursor's wanted column is -1 after `$`. `Selection.none` stands for "no selection" so no member is nullable. Only the current window can be in visual mode, because no visual map binds a window command, and the presenter draws only its selection; another window on the same buffer draws none. The alternative, a selection record on the state, would make "the selection belongs to the window" a convention rather than a fact, and `gv` per window would need a second store anyway.

`Selection` answers `start`, `finish`, `top`, `bottom`, `char_range(buffer)` (a charwise `Range`: inclusive, or ending at the start of the next line when its later end rests on the end of a line or an empty line, which is how the line break is included), `line_range`, `span(buffer, row, tabstop)` (a `Span < Data.define(:from, :to, :eol)` of code point columns on one row and whether its line break is selected), and `block(buffer, tabstop)`. `Block < Data.define(:top, :bottom, :left, :right, :to_end)` holds display columns: `left` is the smaller start column and `right` the larger end column of the anchor's and the cursor's characters (the end of a line counts as one cell), so a wide character or a tab at a corner widens the block to cover it. `Block#span(line, tabstop)` gives the code point columns of the characters whose cells meet the block, so the operators take a partly covered tab or wide character whole, and `Block#short?(line, tabstop)` says whether the line ends before the block. Display columns move from the presenter into `DisplayWidth` (`cell`, `column`, `col_at`), so the domain and the presenter measure a line the same way.

### The cursor may rest on the end of a line in visual mode

`EditorState#max_col` returns the line length in the visual modes, as in insert mode. That alone gives Neovim's `selection=inclusive` behavior: `l` steps onto the end of the line, `$` lands there, and a vertical motion to a shorter line stops there, and a selection ending there includes the line break. Leaving visual mode moves the cursor back onto the last character, keeping the wanted column.

### Visual keys use the grammar; operators complete at once

`HandleKey#grammar_mode?` includes the three visual modes. In them it calls `CommandGrammar#accept_visual(action, keys)`, a second entry point that reads `register.select` and the character-wanting actions (the find motions and `visual.replace`) as normal mode does and completes every other action at once, operators included, with no pending operator. `finish` keeps the visual mode on `:complete` and `:cancel`, so an unbound key or a bad register name drops the pending keys and stays in visual mode, and the dispatched command decides the next mode. The alternative, a separate visual key path, would duplicate counts, registers, and the find characters.

`Dispatcher#call` asks first, in a visual mode, whether the action is a visual one: a text object goes to `ExtendVisual`, the five operators and the `visual.*` actions to `OperateOnSelection`, `mode.normal` to `StartVisual#leave`. Motions keep going to `Move`, which moves only the cursor, so the selection grows from the anchor. `mode.visual`, `mode.visual_line`, `mode.visual_block`, and `visual.reselect` go to `StartVisual` from both normal and visual mode. The visual maps reuse the operator action names for `d y c > <` because they are the same operators; the keys whose meaning differs in visual mode (`J gJ p P r ~ u U X D C S R Y I A o O gv`) get `visual.*` names, so `docs/actions.md` can describe each once.

### Three use cases

`StartVisual` enters, switches, leaves, and reselects: `toggle(state, mode)` sets the anchor when entering from normal mode, leaves when the mode is the same, and switches otherwise; `leave` calls `EditorState#end_visual`, which stores the selection on the window, returns to normal mode, clamps the cursor, and returns the selection; `reselect` restores `last_selection` clamped to the buffer, exchanging it with the current one inside visual mode. `Window#show` forgets the last selection, so `gv` never selects positions of another buffer. `ExtendVisual` holds `o`, `O`, and the text objects. `O` in a block follows Neovim's `v_swap_corners`: the anchor goes to the block's left column on its row and the cursor to the right one on its own, or the other way round when the cursor was already there. Text objects run `TextObjects.call` with the cursor placed where the object is looked up (the start of the selection, or the position after or before the cursor end when extending) and put back afterwards, since the functions read `state.cursor`; the result sets the anchor and the cursor end, switching the kind as the object requires.

`OperateOnSelection` ends visual mode first, through `end_visual`, then works on the returned selection, so every operator sees normal-mode cursor rules and `gv` always has the selection that was operated on. The uppercase keys build a derived selection: a linewise one for `X D Y C` in charwise and linewise mode and for `S R` in every kind, and a block with `to_end` set for `D` and `C` in blockwise mode, which is Neovim's `v_visop` table.

### Registers get a kind

`RegisterEntry` becomes `Data.define(:text, :kind)` with `:charwise`, `:linewise`, and `:blockwise`; `linewise` stays as a method so normal-mode code reads it unchanged, and `blockwise` is added. A block entry's text is its rows joined with newlines. `RegisterEntry.joined` makes the result linewise when either part is, blockwise when either part is, and charwise otherwise. `Operators.put_block` inserts the rows at a display column on consecutive rows, padding short rows and adding rows past the end, and repeating each row count times, padded to the block's width except at the end of a line; normal-mode `p` and `P` call it for a blockwise entry.

### Block insert and append repeat on leaving insert mode

`I`, `A`, and `c` in blockwise mode start insert mode on the top row and fill `EditorState#block_insert`, a `BlockInsert` record with the row, the column and line length at the start, the line count, the other rows to repeat on (rows that end before the block are left out for `I` and `c`), the display column, and whether to pad or append at the end. `LeaveInsert` checks it: when the cursor is still on that row, no line was added, and the row grew, the inserted text is the part after the start column, and it is inserted on every listed row at the column's code point position, padded or at the end as recorded; the cursor then goes to the block's top-left for `I` and `A`. This is Neovim's `op_insert` and `op_change` rule. The alternative of inserting on every row while typing would need insert mode to know about blocks.

### Put replaces the selection

`p` and `P` read the register before anything is deleted, delete the selection without touching the registers, and store the deleted text in the unnamed register only for `p`. The register is then put by the rules of Neovim's `nv_put` in visual mode: before the start of a charwise selection, splitting the line for a linewise register; as whole lines in place of a linewise selection (replacing the empty line left when the whole buffer was selected); and into a block, on every row for one line of charwise text, as a block for a blockwise register, and below or above the block for a linewise one.

### Rendering

`Highlight::VISUAL` is a new group, which `ScreenPresenter#sgr` maps to reverse video, Vim's default for `Visual` on a terminal. `FramePresenter#paint_window` receives the selection for the current window in a visual mode and gives `paint_line` a range of display columns and whether to paint the line end cell: for charwise and linewise rows the display columns of the row's span, for a block its `left` to `right` (or the row's end after `$`), so a tab or wide character on the block's edge is covered cell by cell. Tab cells are painted one by one so a partly covered tab is partly highlighted. The cell under the cursor is painted back in its normal highlight, as Vim's `noinvcur` does for a block cursor. The mode line shows the three indicators.

### Bindings

Each of the three visual maps lists every motion of the normal map, every text object of the operator-pending map, `<Esc>` and `<C-c>` as `mode.normal`, `v V <C-v>`, `"`, and the operator keys. `gv` is added to the normal map. The `CLAUDE.md` convention now says a new motion needs a binding in the normal, operator-pending, and three visual maps.

### Tests

`test/domain_selection.rb` checks `Selection` and `Block` directly: charwise spans on the first, middle, and last row with and without the line break, linewise spans, the block's columns over tabs and wide characters, `to_end`, and the char and line ranges. `test/editor_visual.rb` is table-driven over the harness with a row per key and kind; `test/adapters_frame_presenter.rb` checks the highlight for all three kinds, the cursor cell, the block over a tab and a wide character, and two windows on one buffer; `test/domain_registers.rb` the blockwise kind and joins; `test/domain_grammar.rb` `accept_visual`; `test/editor_registers.rb` the block put; `test/smoke_editor.rb` runs `Vjd` and `:wq` in the pseudo-terminal.

## Risks / Trade-offs

- [`max_col` changes for the visual modes, and every motion reads it] → that is the intended behavior; `editor_visual` covers `l`, `$`, and `j` onto a shorter line, and leaving visual mode clamps the cursor.
- [Text objects read `state.cursor`, so `ExtendVisual` moves it temporarily] → the row, column, and wanted column are restored on every path before the result is applied; the tests compare the cursor after each object.
- [Neovim's visual rules have many edge cases (partial tabs, `virtualedit`, exclusive selection)] → each implemented rule is a scenario and a table row; the differences are listed in `docs/compatibility.md`.
- [A wider `Dispatcher` constructor] → three more use cases, built once in `EditorAssembly`, which is the only constructor.
- [`RegisterEntry` changes shape] → it is only built through its class methods outside the tests, and `linewise` remains a method, so normal-mode code is unchanged.
