# Backlog: carat/domain/operators.rb

## Visual r over an illegal byte has no test row

- Where: the `:replace` branch of `ascii_recase` in `carat/domain/operators.rb` (line 243, `char * text.length` over text that is not UTF-8), while `~`, `U`, and `u` have rows in `test/editor_registers.rb` (lines 49 to 51). Advisory of the periodic quality review at 6ea61b1.
- Why it matters: an untested branch on hostile text is where the next crash on an illegal byte would hide.
- Fix outline: add a `v$r` row over a line with an illegal byte.
- Also: test/editor_registers.rb
- Category: editor
- Added: 2026-11-03

## Seven more methods are public with no outside caller

- Where: `Operators.ascii_recase` and `indent_width` (`carat/domain/operators.rb` lines 239 and 271), `Registers#unnamed?` (`carat/domain/registers.rb` line 65), `Buffer#layer_at` (`carat/domain/buffer.rb` line 232), `UndoTree#transaction_at`, `parent_of`, `head_of` (`carat/domain/undo_tree.rb` lines 99, 105, 111), at 31919d9. Periodic quality. Queue item: backlog items, needless public methods. Raised again at ce6abdb (periodic quality): `UndoTree#parent_of` and `transaction_at` have no production caller, queue item `editing-counts`.
- Why it matters: needless public surface, called only by tests.
- Fix outline: make them private and test them through their public callers.
- Also: carat/domain/registers.rb, carat/domain/buffer.rb, carat/domain/undo_tree.rb
- Category: editor
- Added: 2026-11-09

## Requires out of step with the constants a file names

- Where: `carat/domain/operators.rb` line 6 (requires `selection`, unused; `registers` where it uses `RegisterEntry`); `last_change.rb`, `reselect_visual.rb`, `toggle_slot.rb`, `completion_handler.rb`, `show_completion.rb` (unused requires); `carat/domain/layout.rb`, `window.rb`, `slot.rb`, `tab_page.rb`, `layout_node.rb` (build constants they never require). Periodic quality at e49f63d.
- Why it matters: they compile only by the load order of `carat.rb`.
- Fix outline: require what each file names and drop the rest, `make diagnose` confirming. Queue item: Backlog batches.
- Also: carat/domain/layout.rb, carat.rb
- Category: editor
- Added: 2026-11-10

### The tabstop fallback is re-spelled beside Options#tab_width

- Location: dispatcher.rb:112, leave_insert.rb:69, repeat_last.rb:104, visual/extend_visual.rb:54, arrange_view.rb:43, insert_tab.rb:22 under carat/use_cases/, and carat/domain/operators.rb:172, 251, 272 (sprint-4 sweep, quality advisory).
- Why: `tabstop > 0 ? tabstop : 8` repeats Options#tab_width (options.rb:130), and Options already refuses a tabstop below 1, so the fallback is dead.
- Fix: call options.tab_width, and one shift width helper for the operators.
- Category: editor
- Added: 2026-11-14

### Operators repeats the indent step fallback

- Location: carat/domain/operators.rb:172, :251, :272 (sweep, quality).
- Why: shift_block and shift repeat the shiftwidth-else-tabstop-else-8 step and indent_width the tab fallback.
- Fix outline: one private step_width(shiftwidth, tabstop), or an Options reader passed in.
- Category: editor
- Added: 2026-11-17

### The shift width is written twice at carat/domain/operators.rb:172 (sprint-28 sweep quality, note 26)

- Location: carat/domain/operators.rb:172, :320, :337
- Why: the shiftwidth fallback is in shift_block and shift; indent_width recomputes DisplayWidth.column.
- Fix: one private shift_width helper and DisplayWidth.column(indent, indent.length, tabstop).
- Category: editor
- Added: 2026-11-22
- Merged: ### duplication: the shiftwidth fallback shiftwidth > 0 ? shiftwidth at carat/domain/operators.rb:172 (sprint-26 sweep quality, note 24)
- Location: carat/domain/operators.rb:172
- Why: duplication: the shiftwidth fallback shiftwidth > 0 ? shiftwidth : (tabstop > 0 ? tabstop : 8) is spelled in shift_block and again in shift (320), and indent_width (341) repeats the tab fallback
- Fix: one private Operators.step_width(shiftwidth, tabstop) and the tab fallback taken from callers passing Options#tab_width

### ascii_recase, indent_width (340), make_indent (353), recase_row (254), unindent (199) at carat/domain/operators.rb:308 (sprint-30 sweep quality, note 31)

- Location: carat/domain/operators.rb:308
- Why: ascii_recase, indent_width (340), make_indent (353), recase_row (254), unindent (199), ExGrammar.range_end, address_char?, letter? (ex_grammar.rb:36-59), RegisterCount.writable? (register_count.rb:79), Registers#numbered_at (registers.rb:70), UndoTree#note_line (undo_tree.rb:328), and Window#scroll_folded are public but called only inside their own file
- Fix: make them private (private_class_method for the module functions) and drop them from the method lists of docs/codebase-map.md areas 7, 9, 11, and 12
- Also: docs/codebase-map.md
- Category: editor
- Added: 2026-11-23
