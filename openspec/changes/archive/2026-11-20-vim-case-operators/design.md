# Design

## Context

`~` is `ToggleCase`, a standalone edit; visual `~ u U` are `visual.*` actions over `RecaseSelection`, which calls `Operators.recase`. Pending operators are `OperatorHandler` names the grammar reads by the handler's kind; `Operate` resolves the operand and runs the buffer work. `zf` and `>` show the way a new operator joins: a name in `OperatorKind`, a registration, and keymap lines in the five modes.

## Decisions

### Names and keys

`operator.swap_case`, `operator.lowercase`, `operator.uppercase`, since `operator.toggle_case` is `~`. Normal and the three visual modes bind `g~ gu gU`; operator_pending binds those and `~ u U`, so the doubled form is the key typed again in either spelling, as Neovim has it. The grammar already makes a command linewise when the key resolved under a pending operator equals the operator.

### Where the work sits

`Operators.recase_range(buffer, range, how)` returns nothing and edits the rows of the range in one `set_lines`, whole lines for a linewise range and the span of each row for a charwise one; it makes no edit when no character changes. `Operate#recase` places the cursor as `yank` does and writes no register. `OperatorHandler` in a visual mode calls `RecaseSelection`, so a rebinding of `g~` in visual behaves as `~`.

### Case mapping per letter

Whole-string `swapcase`, `downcase`, and `upcase` give `SS` for `ß` under toggle, a final sigma form, and two characters for `İ`; Neovim maps each letter alone and special-cases `ß` under upper only. `recase` keeps the whole-string call for ASCII text (length equals byte size) and otherwise maps each letter through `recase_letter`, which refuses a result of another length than the letter's except the `ß` and `İ` cases. Alternative: leave `recase` as it was; rejected, since `g~` on `straße` would insert `SS` where Neovim keeps `ß`, and the cursor arithmetic of `~` assumes unchanged length.

### Dot and undo

`OperatorHandler` is `repeat: true`; the dispatcher records the command and runs it in one transaction, so `.` and one `u` need no new code; the tests prove them.
