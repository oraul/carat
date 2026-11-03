# Design

## Context

The `<C-w>` commands are `keymap.normal` lines in `config/default.caratrc:113` to `:125`, each naming a `window.*` action that `WindowHandler` serves with the count typed before `<C-w>`. `KeyNotation.parse` already reads a keys word with two Ctrl keys, so `<C-w><C-h>` is the codes 23 and 8 (Ctrl-H, distinct from `<BS>`, 127). The terminal is put in raw mode by `STDIN.raw`, whose `cfmakeraw` turns off flow control and newline translation, so Ctrl-S (19), Ctrl-Q (17), Ctrl-J (10), and Ctrl-C (3) reach the editor as those codes.

The explorer tree has its own scratch keymap of plain keys (`h`, `l`, and so on); `HandleKey#lookup` asks it first and falls through to the mode's keymap when it neither binds nor begins a binding with the keys, so every `<C-w>` chord in the tree is answered by the global keymap.

## Goals / Non-Goals

**Goals:**
- Each held-Ctrl form Vim accepts does what its plain form does in carat, counts included, in file windows and in the tree.
- `<C-w><C-c>` is documented and tested as cancelling.

**Non-Goals:**
- New window commands, `<C-w>` followed by a count, `<C-w><BS>` and the arrow forms, other modes.

## Decisions

- Bindings only. Each new line names the existing action of the plain form (`keymap.normal <C-w><C-h> window.left`), so there is no new action, handler, or grammar rule, and `docs/actions.md` stays as it is; its rows describe actions, not keys. Alternative considered: a key-notation alias that folds a held-Ctrl letter into the plain one after `<C-w>`; rejected because it hard-codes a binding rule in Ruby, which `CLAUDE.md` forbids, and would also fold chords Vim does not accept.
- `<C-w><C-c>` stays unbound. Vim's help, tag `CTRL-W_CTRL-C`, says closing a window that way does not work because the `<C-c>` cancels the command. In carat a `<C-w>` followed by a key that is not bound under it is `:none`, which cancels the pending command and drops the keys in normal mode (`HandleKey#step`), so the behavior already matches; a test row pins it.
- `<C-w>W` has no held-Ctrl form: `<C-W>` is the same code as `<C-w>`, so `<C-w><C-W>` is `<C-w><C-w>`, as in Vim.
- The new lines sit right after the plain lines they mirror, in the same order, so the defaults file reads as one block of window keys.
- Tests: the editor rows reuse the existing table shapes of `test/editor_windows.rb` and `test/editor_explorer.rb` (keys in, window shape out), one row per chord, with counts where the plain form takes one and the pause form in the tree; `test/domain_keymap.rb` gets one lookup row per chord against the shipped defaults; `test/domain_keys.rb` a row for two Ctrl keys in one word, which no test asserted.

## Risks / Trade-offs

- A terminal with flow control left on would swallow Ctrl-S and Ctrl-Q; carat's raw mode turns it off, and Vim's help carries the same note for `CTRL-W CTRL-S`.
- Ctrl-H is the backspace code of some terminals; after `<C-w>` that reads as `<C-w><C-h>`, which is what Vim does too.
- Allocations per key: the keymap gains ten leaves at start-up; a key lookup walks the trie by code, so the `lh` and `j` scenarios are unchanged.
