# Design

## Context

See proposal.md for motivation. The ex registry is the `case` over `command.name` in `ExecuteEx#call`, fed by `ExGrammar.parse`, which already yields the name, the bang, and the argument for every spelling this change adds (`x`, `exit`, `wa`, `qall`, `wqa!`, and so on are a run of letters, an optional bang, and the rest). `SaveFile#call(state, path_arg)` writes to the argument or to the buffer's own path and reports the written message, `E32`, and `E212`; `Quit#call(state, bang)` sets the quit flag or reports `E37`. `:wq` composes the two: it writes, returns the write outcome when it failed, and otherwise quits with the bang forced. The editor holds one buffer and one window until roadmap item 7, so there is no buffer list to loop over.

## Goals / Non-Goals

**Goals:**

- Every new command is one arm of the existing `case` plus a small private helper in `ExecuteEx`, so the registry stays the single place that names ex commands.
- The "all" commands have exactly the shape they will keep when the buffer list arrives: a loop over the buffers that today has one iteration.
- Messages match Neovim's text where the single-buffer case has a meaning: the written message, `E32`, `E212`, `E37`, and `E141: No file name for buffer 1`.

**Non-Goals:**

- A `SaveAll` or `QuitAll` use case. Architecture section 5.2 lists them, but with one buffer they would wrap `SaveFile` and `Quit` and nothing else; they are introduced with the buffer list, when they have a loop to own.
- Intermediate abbreviations (`xi`, `wal`, `qal`, `quital`, `wqal`, `xal`), an abbreviation table, `:update`, `:saveas`, and ranges.

## Decisions

### Shortest and full spellings only, as `:w` does

The registry accepts `x xit exi exit`, `wa wall`, `qa qall quita quitall`, and `wqa wqall xa xall`. The existing commands accept only their shortest and full spellings (`w` and `write`, not `wr`), and `docs/compatibility.md` records the gap; this change keeps that precedent and extends the note. Alternative considered: a prefix-matching abbreviation table in `ExGrammar`; rejected because it is a separate change that touches every command and the grammar's spec, not this one.

### `:x` writes when modified or when a file argument is given

`exit_editor` in `ExecuteEx` (named so because `exit` would shadow the kernel method) writes through `SaveFile` when `state.buffer.modified` is true or `command.args` is not empty, returns the write outcome when it failed, and otherwise calls `Quit` with the bang forced, exactly as `:wq` does. The request asks for the file-argument case; Neovim writes only when the buffer is changed. The forced quit after a successful write follows `:wq`: the write just cleared the modified flag, and the one case where it did not, writing to another path, ends the editor under `:wq path` today, so `:x path` matches it. The bang on `:x` therefore changes nothing today; it exists so `:x!` is accepted, as `:wq!` is.

### Write-all writes only modified buffers and reports `E141`

`write_all` returns an empty success for an unmodified buffer, `E141: No file name for buffer 1` for a modified buffer with no path, and otherwise `SaveFile#call(state, "")`. This is Neovim's `do_wqall` loop reduced to one buffer: it considers only changed buffers, reports `E141` with the buffer number for a nameless one, and writes the rest. Alternative considered: writing unconditionally with the messages of `:w`, which would rewrite a clean file and show a written message Neovim does not show; rejected because the request asks for Neovim's semantics. The buffer number is the literal `1` because the editor has one buffer; the buffer list replaces it with the buffer's index.

### `:wqa` and `:xa` are one command

Both call `write_all`, return its outcome when it failed, and otherwise call `Quit` with the bang forced, as `:wq` does. In Neovim `:wqa` and `:xa` share `do_wqall` and write only changed buffers, so there is no `:wqa` that writes a clean buffer. A failed write or an `E141` stops the quit, which is what keeps `:wqa` from losing a nameless buffer.

### `:qa` reports the plain `E37`

`:qa` and `:quita` call `Quit#call(state, command.bang)` directly. Neovim prints `E37` followed by `E162: No write since last change for buffer "name"`; the second line names which buffer blocks the quit, which carries no information with one buffer, and Carat's message row shows one line. The `E162` line is left to the buffer list change.

### Tests

`test/use_cases_ex.rb` gains one table per command family, driven by `Testing#table`, with rows `[label, [command line, buffer state], [ok, message, quit, file text or modified flag]]`, so every spelling appears with and without bang on a clean buffer, a modified buffer, and a buffer with no name. `test/editor_cmdline.rb` types `:x<CR>`, `:wqa!<CR>`, `:wa<CR>`, and `:qa<CR>` through the harness so the full key path is covered.

## Risks / Trade-offs

- [`:x` differs from Neovim when a file argument is given on a clean buffer] → Recorded in the proposal and in the compatibility note; the behavior is the documented one and the clean-buffer case without an argument matches Neovim.
- [The literal buffer number in `E141` is wrong once there are several buffers] → The buffer list change replaces `write_all` with a loop and the number with the buffer's index; the compatibility row says the "all" forms act on the single buffer.
- [`make snapshots` rewrites every `.expected` file] → The diff is reviewed; only the two ex test snapshots gain lines.
