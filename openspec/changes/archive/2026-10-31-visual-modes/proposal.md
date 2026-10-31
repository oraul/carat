# Proposal

## Why

`v`, `V`, and `<C-v>` are bound in `config/default.json`, but pressing them shows "Not implemented", so a Neovim user cannot select text and act on it, one of the most used parts of modal editing. The user asked for visual mode now, ahead of the undo change, and syntax highlighting after it; the command grammar, the motions, the text objects, the operators, and the window layout it builds on are all in place.

## What Changes

This change delivers roadmap item 5, `visual-modes`, taken ahead of item 4, `undo-and-registers`, at the user's request; the roadmap note in `docs/architecture.md` and the status in `CLAUDE.md` say so, and item 4 is next in order afterwards.

- Add charwise, linewise, and blockwise visual modes: `v`, `V`, and `<C-v>` start them from normal mode, the same key again leaves, another of the three switches the kind keeping the selection, and `<Esc>` and `<C-c>` leave. The anchor and the cursor define the selection; `o` swaps them, `O` in blockwise moves to the other corner on the same row (as `o` in the other kinds), and `gv` reselects the last selection of the window (exchanging it with the current one inside visual mode).
- Feed visual-mode keys through the command grammar: counts and the `"x` register prefix work as in normal mode, every motion moves the cursor end of the selection, the text objects select or extend, and an operator completes at once with the selection as its operand. The mode line shows `-- VISUAL --`, `-- VISUAL LINE --`, or `-- VISUAL BLOCK --` with the pending keys at the right.
- Add the operators on the selection with Neovim's semantics: `d x <Del>` delete, `y` yank, `c s` change, `>` `<` shift by the count, `J` and `gJ` join, `p` and `P` replace the selection with a register, `r{char}` replace every character, `~ u U` change case, `X D` delete lines, `C S R` change lines, `Y` yank lines, `I` and `A` insert and append (on every row of a block when insert mode is left), and `$` extending a block to every row's end. After an operator the mode returns to normal, or insert for the change family.
- Add a blockwise register kind: block yanks and deletes store their rows as a block, and `p` and `P` in normal mode put a block at the cursor's display column, row by row.
- Draw the selection with a new `Visual` highlight group in the current window only, for all three kinds, the block on display columns with tabs and wide characters, the character under the cursor left unhighlighted so the cursor shows on top.
- Store the last selection on each window for `gv`. Marks do not exist yet, so `'<` and `'>` are not set; they arrive with the change that brings marks, which will set them from the same stored selection.
- Bind every visual key in the `visual`, `visual_line`, and `visual_block` maps of `config/default.json`, bind `gv` in the normal map, and regenerate the mirror; a new motion now needs a binding in the normal, operator-pending, and the three visual maps, and the `CLAUDE.md` convention says so.
- Record every command in `docs/compatibility.md` and every new action in `docs/actions.md`; update `docs/architecture.md`, `CLAUDE.md`, and the README.

Out of scope, recorded in the design: `:'<,'>` ranges on ex commands (there is no range parsing yet, so `:` is not bound in visual mode), the dot command and undo (roadmap item 4), `gq`, `g?`, `=`, `!`, `<C-a>` and `<C-x>` increments, `zf`, select mode, the mouse, the `'<` and `'>` marks themselves, the plugin API's selection read and set requests, and `virtualedit`.

Assumptions recorded here rather than asked:

- Neovim's `v_visop` rule decides the uppercase keys: `X` and `Y` in blockwise act on the block, not on whole lines, and `D` and `C` in blockwise act from the block's left edge to the end of every row; in the charwise and linewise kinds all four act on whole lines. `S` and `R` change whole lines in every kind.
- The selection is inclusive, as `selection=inclusive`: in visual mode the cursor may rest on the end of a line, where `l`, `$`, and vertical motions to a shorter line put it, and a selection whose end is there, or on an empty line, includes the line break.
- A count before `v`, `V`, or `<C-v>` is ignored, and so is a count on `J`, `gJ`, `r`, `~`, `u`, `U`, `I`, and `A`. A count on `p` and `P` repeats the text, a count on `>` and `<` multiplies the shift.
- After a linewise yank, case change, or replace the cursor goes to column 0 of the top row when the anchor is there, and stays at its own position on the top row when the cursor is there, which is where Neovim's start of a linewise operand lies; linewise `I` uses the same position and `A` appends after the last character of the bottom row.
- Text objects: on a selection of one character (one line for `ip` and `ap`) the object is selected; on a larger one word, sentence, and paragraph objects extend the end the cursor is on by count objects, and bracket and quote objects select the smallest object that is strictly larger than the selection, or leave it alone. A charwise object turns a linewise selection charwise, and a linewise object (`ip`, `ap`, and an inner bracket object between brackets that end their lines) turns the selection linewise.
- In blockwise, a character that the block's display columns only partly cover (a tab or a wide character on the edge) is taken whole by the operators instead of being split into spaces; `>` and `<` on a block insert and remove spaces at the block's left edge, never tabs; `I` and `c` skip rows that end before the block, `A` pads them with spaces.
- `p` in visual mode with an empty register shows `E353`, leaves visual mode, and changes nothing. `r` followed by a key that is not printable cancels and stays in visual mode. A key that visual mode does not bind is dropped and the mode stays, as Neovim beeps.

## Capabilities

### New Capabilities

- `visual-mode`: entering, leaving, and switching the three visual modes, the anchor and the cursor, `o`, `O`, `gv`, motions, counts, and text objects inside visual mode, the mode line, and the last selection kept per window.
- `visual-operators`: every operator and command that acts on the selection, the cursor and mode each leaves behind, block insert and append, and replacing the selection with a register.

### Modified Capabilities

- `screen-rendering`: the message row shows the visual mode indicators, and the selection is drawn with the `Visual` highlight in the current window.
- `registers`: a register entry may be blockwise, and appending to one follows a stated rule.
- `operators`: `p` and `P` in normal mode put a blockwise register as a block.

## Impact

- New entities `carat/domain/selection.rb` (`Selection`, `Span`, `Block`) and `carat/domain/block_insert.rb`; `window.rb` gains the anchor and the last selection; `editor_state.rb` the selection, leaving visual mode, and the pending block insert; `mode.rb`, `registers.rb` (the entry kind), `operators.rb` (block, case, replace, raw join), `display_width.rb` (display columns of a line), `command_grammar.rb` (visual acceptance), `highlight.rb`.
- New use cases `carat/use_cases/visual/start_visual.rb`, `extend_visual.rb`, `operate_on_selection.rb`; `handle_key.rb`, `dispatcher.rb`, `operate.rb`, `leave_insert.rb`, and `editor_assembly.rb` change; `frame_presenter.rb` and `screen_presenter.rb` draw the selection.
- `config/default.json` and the generated mirror; `carat.rb`'s require graph.
- Tests: `test/editor_visual.rb`, `test/domain_selection.rb`, and additions to `test/adapters_frame_presenter.rb`, `test/domain_registers.rb`, `test/domain_grammar.rb`, `test/editor_registers.rb`, and `test/smoke_editor.rb`.
- Docs: `docs/compatibility.md`, `docs/actions.md`, `docs/architecture.md`, `docs/backlog.md`, `CLAUDE.md`, `README.md`.
- No new dependencies and no new ports.
