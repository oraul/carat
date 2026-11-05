# Proposal

## Why

Roadmap item 7 (`buffers-windows-tabs`, `docs/architecture.md` section 12) has its second half left: there is no `:ls`, `:bn`, `:bp`, `:bd`, or `:b N`, and `:qa` on unsaved work shows only `E37` where Neovim adds the `E162` line naming the buffer (queue item 1, goal 1). Today a buffer also leaves the list as soon as no window shows it and is clean, so a list command would have almost nothing to list or cycle through, and `E141` names a buffer by a position that shifts.

## What Changes

- A file buffer stays in the list after its last window stops showing it, hidden and loaded, as Neovim keeps it with `'hidden'` on; it leaves the list only through `:bd`. A plugin's scratch buffer still leaves when no window shows it. The empty unnamed buffer the editor starts with is reused by the first file opened over it, so that file is buffer 1, as in Neovim.
- Each buffer remembers the cursor position a window last left it at, and showing it again in a window (`:e`, `:b`, `:bn`, `:bp`, `:bd`) puts the cursor back there.
- `:ls`, `:buffers`, `:files`, with `!` and the flag filters: Neovim's listing of buffer number, flags (`%`, `a`, `h`, `+`, `u`), quoted name, and line.
- `:bn[ext]`, `:bp[revious]`, `:bN[ext]` with a count argument and a bang, wrapping over the listed buffers; `:b[uffer] N` and `:b[uffer]` with a bang. A modified current buffer refuses the switch with `E37` unless the bang is given, as `:e` does; with the bang it stays hidden with its changes. Errors `E85`, `E86`, `E488`.
- `:bd[elete][!] [N]`: removes the buffer from the list, closing the windows that show it as Neovim does, the current window showing the next listed buffer or, for the last one, a new empty buffer. Errors `E89` and `E516`.
- `:qa`, `:q` on the last window, `:q!`, `:wq`, and `:x` refused by unsaved work show Neovim's two lines, `E37: No write since last change` and `E162: No write since last change for buffer "name"`, and go to that buffer: its window when one shows it, else the current window. `:q` on a modified current buffer keeps its one line `E37 ... (add ! to override)`.
- `E141` from `:wa`, `:wqa`, and `:xa` names the buffer number, which no longer shifts.

Out of scope: `:b name` and `:bd name` (a name argument answers `Not implemented`), several numbers or a range for `:bd`, the count before the command (`:3bn` stays `E481`), `:badd`, `:bwipeout`, `:bunload`, `:sbuffer` and the split forms, the alternate buffer (`#`, `Ctrl-^`, `:e #`), `:ls t`, and reading a hidden buffer's file again when it is shown.

## Capabilities

### New Capabilities

- `buffer-list`: the buffer list as the user sees it: which buffers are listed and their numbers, the remembered cursor, `:ls`, the buffer switch commands, and `:bd`.

### Modified Capabilities

- `command-line-mode`: `:e` keeps the buffer it leaves listed; `:q`, `:q!`, `:wq`, `:x`, and `:qa` refused by another buffer's unsaved work show `E37` and `E162` and go to that buffer; `E141` names the buffer number.
- `windows`: closing a window keeps every file buffer it showed in the list, not only a modified one.
- `tab-pages`: the hidden buffer that refuses `:qa` after a tab page closes is named with `E162`.

## Impact

- Domain: `Buffer` (the remembered cursor), `BufferList` (the keep policy, `load` with reuse and cursor restore, the cycle and the unsaved-buffer search), `TabList` (going to a buffer's window), `Messages` (`E37` without the hint, `E162`).
- Use cases: new `ListBuffers`, `SwitchBuffer` with `BufferRequest`, `DeleteBuffer` under `carat/use_cases/buffers/`; `Quit`, `QuitAll`, `SaveAll` changed; new `BufferCommandHandler`; wiring in `EditorAssembly` and `carat.rb`.
- Plugins see fewer `buffer_close` events, since a buffer leaves the list only through `:bd`; the API does not change.
- Tests: `test/editor_buffers.rb` (new), `test/domain_buffer_list.rb`, `test/use_cases_ex.rb`, `test/adapters_assembly.rb`, and the editor tests whose expectations of a buffer leaving the list change.
- Docs: `docs/compatibility.md`, `docs/codebase-map.md`, `docs/architecture.md` (item 7 and the `BufferList` policy), `CLAUDE.md` status, `README.md` where it lists commands.
- Assumption: the commands follow Neovim with `'hidden'` on for keeping buffers loaded and listed, and with `'hidden'` off for refusing to leave a modified buffer without a bang, which is the rule `:e` already follows.
