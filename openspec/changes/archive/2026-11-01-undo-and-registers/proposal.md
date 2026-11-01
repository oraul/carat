# Proposal

## Why

`u`, `<C-r>`, and `.` are bound but answer "Not implemented", so a mistaken edit cannot be taken back and no change can be repeated, and only the unnamed and named registers exist, so a yank is lost to the next delete. The edit pipeline already groups every edit into transactions whose records share line strings with the buffer and keeps the last one on the buffer as the hook for this change; the undo tree, the dot command, and the remaining registers can now be built on it.

## What Changes

This change delivers roadmap item 4 of `docs/architecture.md`, `undo-and-registers`, the last change of the core-quality queue the user approved. It consumes the hooks `edit-pipeline` left (`Buffer#transaction`, `last_transaction`, `closed_count`, change records sharing line strings, the modified flag derived from `saved_change`) and covers the visual operators that `visual-modes` delivered ahead of it.

- Add an undo tree per buffer, built from the closed transactions: every transaction that closes on a file buffer becomes an undo state with its change records, the cursor before and after it, a sequence number, and the time it closed. The tree keeps branches as Vim does: a change made after undoing starts a new branch, and the older branch stays reachable in time order.
- `u` and `<C-r>` with counts undo and redo along the current branch; `U` undoes all recent changes on the last changed line and is itself undoable; `g-` and `g+` move through the states in time order across branches; `:u[ndo]` with an optional state number (0 for the original text), `:red[o]`, `:undol[ist]`, `:ea[rlier] N`, and `:lat[er] N` with a count of changes. Messages follow Neovim's formats: `1 line less; before #3  0 seconds ago`, `Already at oldest change`, `Already at newest change`, `E830: Undo number 7 not found`, and the `:undolist` table.
- Undo and redo apply inverse records through the buffer's one splice: they produce change records and a closed transaction for observers, so the render, cursor clamping, signs, and the plugins' `buffer_change` events follow them, but they create no undo state. The modified flag clears when undo or redo returns to the state of the last save and sets again when moving away.
- An `undolevels` option (default 1000, from the configuration's `options`) trims the oldest states; states share the line strings with the buffer, so memory grows with the lines changed, not with the buffer's size.
- Insert sessions stay one undo state from the command that entered insert mode to leaving it, as the transactions already are; an arrow key in insert mode closes the state so far and starts a new one, as Neovim does. A plugin edit request and a visual block insert are one state each.
- Add the dot command `.`: it repeats the last change, recorded as its command (register, count, operator, motion or text object, character argument) plus the keys typed in its insert session, with a typed count replacing the old one for this and later repeats. It repeats operators with motions or text objects, the standalone edits, insert commands with their text, and visual operators over a region of the same size from the cursor; not motions, yanks, undo, or ex commands. A numbered register `"1` to `"8` named in the change is incremented on each repeat.
- Add normal-mode `r{char}` and `~` with counts, which the dot command is asked to repeat and which existed only in visual mode.
- Add the numbered registers `"0` (last yank) and `"1` to `"9` (deletes and changes of a line or more, or with the motions Vim lists, shifting down), the small delete register `"-`, the black hole `"_`, and the read-only registers `".` (last inserted text), `":` (last command line), and `"%` (current file name). Writing to a read-only register is refused with `E354: Invalid register name: '.'`. `:reg[isters]` and `:di[splay]`, with optional register names, list them.
- Show a message of several lines, which `:undolist` and `:registers` produce, over the bottom rows of the screen with Neovim's `Press ENTER or type command to continue` line; Enter or Space dismisses it, any other key dismisses it and is handled.
- Benchmark scenarios for undo and redo on 100,000 lines, the dot command against the commands it repeats, and the memory a thousand single-line edits add.
- Update `docs/compatibility.md`, `docs/actions.md`, `docs/architecture.md`, `CLAUDE.md`, and the default configuration.

Out of scope:

- `:earlier` and `:later` with a time (`10s`, `5m`, `1h`, `1d`) or a file-write count (`1f`) suffix: they answer `Not implemented: :earlier 10s`, recorded in `docs/backlog.md`.
- The `"/` register, which waits for search: it is accepted as a name and holds nothing. The `"#`, `"=`, `"*`, and `"+` registers.
- Persistent undo files (`undofile`), `:undojoin`, `<C-g>u`, insert-mode `<C-r>`, `@:` and macros, and counts before `i a I A o O`, which stay ignored as before (so `3.` after an insert inserts its text once).
- The plugin API's selection read and set, which stays in the backlog.
- Neovim's `-- More --` paging of long messages and the `k`, `u`, `b`, `g` scrolling keys of the hit-enter prompt.

## Assumptions

Recorded here rather than asked, all following Neovim unless stated:

- Scratch buffers owned by plugins keep no undo history, as a plugin's `nomodifiable` list buffer in Neovim; `u` in one says `Already at oldest change`.
- `:e!` is an undoable change, as Neovim's `undoreload` default does for a buffer of that size, and the state it makes counts as saved.
- Register writes follow Neovim's `op_delete` code rather than its help text: a delete or change of a line or more, or with `(`, `)`, `{`, or `}`, also shifts the numbered registers and writes `"1` when a named register is given; a smaller delete writes `"-` only when no register is named; a yank writes `"0` only when no register is named. The unnamed register keeps holding only the new text after an uppercase append, as the existing `registers` spec says.
- A visual `p` stores the replaced text by the delete rules (unnamed, `"1` or `"-`), as Neovim's `v_p` deletes the selection with `d`.
- An operator naming a read-only register does nothing and shows `E354: Invalid register name: '.'`; Neovim only beeps there and uses that message for `:let @.`, but Carat has no bell.
- `U` saves the line before the first of a run of changes on one line; a change on another line saves that line instead, and a change that inserts or removes lines forgets it. Undo and redo leave it alone, `U` is not repeated by `.`, and with nothing saved it does nothing.
- An arrow key in insert mode ends the undo state and the change `.` repeats; text typed afterwards is a new change repeated as `i` with that text.
- Times in messages and `:undolist` are always shown as seconds ago, because the clock port is monotonic and has no time of day; Neovim shows a clock time after 100 seconds.
- `g-` at the oldest state says `Already at oldest change` and `g+` at the newest `Already at newest change`, as `u` and `<C-r>` do.
- An `undolevels` of 0 keeps no undo states; Neovim's Vi-compatible single level, where `u` undoes itself, is not implemented.
- A message of more lines than the screen shows its last lines.
- A visual operator repeated with a count uses the count for the operator (the shift amount, the put count) over a region of the original size.

## Capabilities

### New Capabilities

- `undo-history`: the undo tree per buffer and the keys and ex commands that move through it, with their messages, the saved state, `undolevels`, and how insert sessions, plugin edits, and visual inserts become states.
- `repeat-command`: the dot command, what it records, what it repeats, and how a count and a numbered register change on a repeat.

### Modified Capabilities

- `registers`: the numbered, small delete, black hole, and read-only registers, the refusal to write a read-only one, and `:registers` and `:display`.
- `text-buffer`: the modified flag also clears when undo or redo returns to the saved state.
- `normal-mode`: `u`, `<C-r>`, and `.` no longer report "Not implemented", so the requirement for actions of later roadmap items takes another example; normal-mode `r{char}` and `~` are added.
- `screen-rendering`: a message of several lines is shown over the bottom rows with the hit-enter line.
- `plugin-host`: an undo or redo reaches the plugins as `buffer_change` with its rows, and a plugin edit request is undone in one step.

## Impact

- Domain: the new `carat/domain/undo_tree.rb` and `carat/domain/last_change.rb`; `buffer.rb` (the tree, applying states, the line for `U`), `transaction.rb` (the history flag and merging records on one line), `buffer_feed.rb` (the time and `undolevels`), `registers.rb` and `register_entry.rb` (the new registers), `command_grammar.rb` (the register names), `options.rb` (`undolevels`), `editor_state.rb` (messages of several lines).
- Use cases: the new `carat/use_cases/undo.rb`, `repeat_last.rb`, `actions/history_handler.rb`, `ex/history_command_handler.rb`, and `ex/register_command_handler.rb`; `dispatcher.rb` (recording the last change, the insert-mode split, the time), `handle_key.rb` (the hit-enter keys), `insert_text.rb`, `leave_insert.rb`, `operate.rb`, `visual/operate_on_selection.rb`, `edit_command_line.rb`, `actions/action_handler.rb` and every handler (the repeat flag), `actions/edit_handler.rb` (`r` and `~`), `actions/message_handler.rb`, `plugins/buffer_requests.rb`.
- Adapters: `frame_presenter.rb` (the message of several lines), `editor_assembly.rb` (wiring).
- Configuration: `config/default.json` (`undolevels`, `U`, `g-`, `g+`, `r`, `~`) and the generated `carat/domain/default_config.rb`.
- Tests: the new `test/domain_undo_tree.rb`, `test/editor_undo.rb`, and `test/editor_repeat.rb`; `test/editor_registers.rb`, `test/domain_registers.rb`, `test/domain_edits.rb`, `test/editor_transactions.rb`, `test/editor_plugins.rb` or `test/use_cases_plugins.rb`, `test/editor_normal.rb`, `test/adapters_frame_presenter.rb`, and the snapshots they change.
- Benchmark: `bench/keys.rb` and `bench/run.sh` scenarios.
- Docs: `docs/compatibility.md`, `docs/actions.md`, `docs/architecture.md`, `docs/backlog.md`, `CLAUDE.md`.
- No new dependency and no plugin API change.
