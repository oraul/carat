# Design

## Context

See proposal.md for why. Today `config/default.caratrc` binds `<leader>w :w<CR>` and `<leader>q :q<CR>` as key-sequence replays, the window keys exist only as `<C-w>` sequences naming the `window.*` actions, and writing, quitting all, and the buffer list are ex commands with no action name (`FileCommandHandler`, `BufferCommandHandler`). The keymap is a trie per mode (`Keymap#lookup`), so a leader group is only bindings: `<leader>w` becomes a prefix as soon as `<leader>ws` is bound and nothing binds `<leader>w` itself; in normal mode a lone prefix waits with no deadline (`HandleKey#step`). The `ActionHandler` holds a kind and a repeat flag and nothing else; the only per-action description in the code is a plugin manifest's (`PluginApi::Manifest#describe`).

The terminal runs in `STDIN.raw`, which Spinel's `io/console` implements with `cfmakeraw` (its `lib/sp_io.c`), clearing `IXON`, so Ctrl-S arrives as byte 19 and `KeyDecoder` passes it on as code 19, `<C-s>` in notation.

## Goals / Non-Goals

**Goals:**

- Each group key is a binding of an action name, so every new key has a `docs/actions.md` row and a handler, and the key hints can show a description for it.
- No new key costs an allocation on the hot path: the descriptions are stored once at registration.

**Non-Goals:**

- The hints popup, the finder, and a buffer picker.
- Changing the ex commands or the use cases behind them.

## Decisions

- The window group binds the existing `window.*` actions (`keymap.normal <leader>ws window.split`), as the held-Ctrl forms did in `window-ctrl-keys`: no new handler, and the count works as for `<C-w>`.
- Two new action handlers, one per feature, as `docs/architecture.md` section 5 asks: `FileHandler` (`file.save`, `file.find`, `quit.all`, `quit.write_all`) over the injected `SaveFile`, `SaveAll`, and `QuitAll`, and `BufferHandler` (`buffer.list`, `buffer.next`, `buffer.previous`, `buffer.delete`) over `ListBuffers`, `SwitchBuffer`, and `DeleteBuffer`. They call the same use cases the ex handlers call, with the same arguments a bare ex command gives, so the messages and refusals are the ex commands' by construction. Alternative: bind key-sequence replays such as `<leader>fs :w<CR>`; rejected because a replay has no action name, so no `docs/actions.md` row and no description for the hints, and in insert mode a replay of `<Esc>:w<CR>` would leave insert mode.
- `quit.write_all` runs `SaveAll` and then `QuitAll` with the bang, as `:wqa` does; the quit group quits the editor, so `<leader>qw` is `:wqa`, not `:wq`, which with several windows would only close one.
- `file.find` is registered with a variant that answers `Not implemented: file.find` and is listed under Reserved in `docs/actions.md`; the finder change replaces the variant. Registering it keeps the binding valid, since `Keymap#add_checked` refuses an action no handler or plugin declares.
- `buffer.list` lists rather than picks until the finder, so its name says what it does today; the finder may rebind `<leader>bb` to a picker action.
- A count before `buffer.next` and `buffer.previous` is the number of buffers to step (0 meaning 1), and before `buffer.delete` the buffer number (0 meaning the current one), mirroring `:bn N` and `:bd N`; the `typed` text of `E516` is `bdelete`.
- Ctrl-S binds `file.save` in normal and insert mode. In insert mode the dispatcher runs a plain action inside the open insert transaction, and `Buffer#mark_saved` already records a save inside an open transaction, so the insert session goes on and a later key makes the buffer modified again.
- Descriptions are registered with the name: `ActionTable#register(name, handler, description)` keeps them in a parallel `Array[String]`, and `ActionTable#describe(name)` answers the description or `""`. Each handler's `register` passes a `descriptions` array beside its `names`. Alternative: one domain table of descriptions keyed by name; rejected because it can drift from the registrations, while a required argument cannot be forgotten, and the key hints read both the table and `PluginHost#describe` by name anyway. A test asserts that every registered name has 1 to 32 characters, which keeps them short enough for a hint column.
- `test/editor_leader.rb` is the table-driven test of every new binding, through `EditorHarness` with the shipped defaults; the smoke test sends 0x13 over a real pseudo-terminal to prove the raw mode delivers it.

## Risks / Trade-offs

- [Users with `<leader>w` and `<leader>q` in their fingers press a prefix that now waits] → the README and the pull request say what moved and the one line that restores the old binding; Escape cancels the waiting prefix.
- [A terminal multiplexer or a terminal emulator that intercepts Ctrl-S before the editor] → outside the editor's control; `<leader>fs` and `:w` remain.
- [The descriptions double the registration's string literals] → they are allocated once at startup, never per key; `make bench-budget` and `make metrics` check the per-key figures.

## Migration Plan

A user who wants the old keys adds `keymap.normal <leader>w :w<CR>` and `keymap.normal <leader>q :q<CR>` to `~/.config/carat/caratrc`; the later line replaces the group prefix's binding, and the group keys under it then wait for `timeoutlen` as an ambiguous prefix does.
