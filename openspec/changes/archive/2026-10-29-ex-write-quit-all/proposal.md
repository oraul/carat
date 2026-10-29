# Proposal

## Why

Typing `:wqa!`, `:x`, `:wa`, or `:qa` in Carat answers "E492: Not an editor command", because the ex registry knows only `:w`, `:q`, `:wq`, and `:e`. These are the commands a Neovim user reaches for to leave the editor, so their absence is felt in the first minute of use, and the file use cases they need, `SaveFile` and `Quit`, already exist.

## What Changes

This change delivers part of roadmap item 7, `buffers-windows-tabs`, ahead of time: the file commands `x wa qa wqa xa` that `docs/architecture.md` section 5.2 lists for `ExecuteEx`. With one buffer and one window, the "all" forms act on the single buffer; when the buffer list arrives, the same commands loop over it without changing their messages.

- Add `:x[it]`, `:exi[t]`, and `:x!`: write only when the buffer is modified or a file argument is given, then quit; a failed write stops the quit and shows the write error, as `:wq` does.
- Add `:wa[ll]` and `:wa!`: write every modified buffer, here the one buffer, with the messages of `:w`; a modified buffer with no name reports `E141: No file name for buffer 1`; an unmodified buffer is left alone with no message.
- Add `:qa[ll]`, `:quita[ll]`, and their bang forms: quit unless the buffer is modified, with `E37` as `:q` reports it; the bang discards changes.
- Add `:wqa[ll]`, `:xa[ll]`, and their bang forms: write every modified buffer as `:wa` does, then quit; a failed write stops the quit; a buffer with no name reports `E141` and the editor stays.
- Extend the ex use case test with table-driven rows for every new command and abbreviation, with and without bang, on a clean buffer, a modified buffer, and a buffer with no name, and the whole-editor command-line test with `:wqa!` and `:x` typed through the harness.
- Add one row per command to the ex section of `docs/compatibility.md`, and name the new commands in the Status paragraph of `CLAUDE.md`.

Out of scope: `:up[date]`, `:sav[eas]`, ranges, the `E162` companion message, `'hidden'`, `'autowriteall'`, and intermediate abbreviations such as `:xi` or `:wal`, which follow the existing `:w` precedent of accepting the shortest and the full spelling only. No key binding changes: these are typed ex commands.

Assumptions recorded here rather than asked:

- `:x` with a file argument writes even when the buffer is unmodified, as the request states; Neovim writes only when the buffer is changed. The documented behavior is the simpler one to explain and the request asked for it.
- `:wa`, `:wqa`, and `:xa` write only modified buffers, as Neovim does: a clean buffer is neither rewritten nor reported. `:wqa` and `:xa` are therefore the same command, as they are in Neovim.
- `:qa` on a modified buffer shows only the `E37` text `:q` already produces; Neovim adds a second `E162` line naming the buffer, which has no meaning with one buffer.
- After a successful write, `:x`, `:wqa`, and `:xa` quit as `:wq` quits today, so writing to another path with `:x path` still ends the editor as `:wq path` does.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `command-line-mode`: adds the requirements for `:x`, `:wa`, `:qa`, `:wqa`, and `:xa` with their long and bang forms, and the `E141` message.

## Impact

- `carat/use_cases/files/execute_ex.rb` gains the new arms of its registry and two helpers; `SaveFile` and `Quit` are reused unchanged.
- `test/use_cases_ex.rb`, `test/editor_cmdline.rb`, and their snapshots.
- `docs/compatibility.md` and the Status paragraph of `CLAUDE.md`. No dependency, port, binding, or configuration changes.
