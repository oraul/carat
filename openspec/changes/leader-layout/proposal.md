# Proposal

## Why

The leader key holds two unrelated replays today, `<leader>w` for `:w` and `<leader>q` for `:q`, which leaves no room to group the editor's commands under mnemonic prefixes, and no core action says in words what it does, so the key hints the UI track brings next (goal 1, discoverability) would have nothing to show. This is the third change of the UI track the user ordered in `docs/goals.md` goal 1 (buffer list, bars, leader layout); it is outside the numbered roadmap of `docs/architecture.md` section 12, which predates the UI track, and the user approved it in its breaking form.

## What Changes

- **BREAKING** `<leader>w` no longer writes the file and `<leader>q` no longer quits: `<leader>w` becomes the window group and `<leader>q` the quit group. Write with `<leader>fs`, Ctrl-S, or `:w`; quit a window with `:q` or `<C-w>q`, the editor with `<leader>qq`. A user who wants the old keys back adds `keymap.normal <leader>w :w<CR>` to the user file.
- The window group: `<leader>ws` split, `<leader>wv` vertical split, `<leader>wh`, `<leader>wj`, `<leader>wk`, `<leader>wl` go to the window in that direction, `<leader>wc` close, `<leader>wo` only; each as its `<C-w>` key does, with a count.
- The quit group: `<leader>qq` quits all as `:qa` does, `<leader>qw` writes every modified buffer and quits as `:wqa` does.
- The file group: `<leader>fs` writes the current buffer as `:w` does; `<leader>ff` is bound to the reserved `file.find`, which shows `Not implemented: file.find` until the finder arrives.
- The buffer group: `<leader>bb` lists the buffers as `:ls` does until the finder can pick one, `<leader>bd` deletes the buffer as `:bd` does, `<leader>bn` and `<leader>bp` go to the next and previous buffer as `:bn` and `:bp` do, a count stepping that many.
- Ctrl-S writes the current buffer in normal mode and in insert mode, where it stays in insert mode.
- `<leader>e` opens the explorer as today.
- New actions `file.save`, `file.find`, `quit.all`, `quit.write_all`, `buffer.list`, `buffer.delete`, `buffer.next`, `buffer.previous`, each with a `docs/actions.md` row.
- Every core action carries a short description of at most 32 characters, registered with it, for the key hints.

Out of scope: the key hints popup itself, the finder behind `<leader>ff` and a buffer picker behind `<leader>bb`, Ctrl-S in the visual and command-line modes, groups for tabs, search, or code, and any change to the `<C-w>` keys.

## Capabilities

### New Capabilities

- `leader-keys`: the leader groups of the default configuration (window, quit, file, buffer, explorer) and Ctrl-S, as the keys a user presses and what each does.

### Modified Capabilities

- `keymap-config`: the leader scenario of the default configuration selects the window group instead of a replay of `:w`; the replay requirement's scenario binds its own key sequence, since the defaults no longer hold one; and every core action carries a short description.

## Impact

- Configuration: `config/default.caratrc` loses `<leader>w :w<CR>` and `<leader>q :q<CR>` and gains the groups and Ctrl-S; `carat/domain/default_config.rb` is regenerated.
- Use cases: new `FileHandler` and `BufferHandler` under `carat/use_cases/actions/`, wired in `EditorAssembly` and `carat.rb`; `ActionTable#register` takes a description and `ActionTable#describe` answers it; every core handler's `register` passes one; the `make new-action` template follows.
- Tests: a new table-driven `test/editor_leader.rb`; `test/use_cases_actions.rb` (descriptions), `test/domain_keymap.rb`, `test/editor_normal.rb`, `test/editor_cmdline.rb` (the moved keys), `test/smoke_editor.rb` (Ctrl-S and `<leader>qq` on a real terminal).
- Docs: `docs/actions.md`, `docs/codebase-map.md`, `README.md` (the leader layout and what moved), `CLAUDE.md` status where it names the next change, `docs/backlog.md` (the README's held-Ctrl entry, fixed by the README update).
- Assumptions: `<leader>qw` is `:wqa` rather than `:wq`, since the quit group quits the editor as `<leader>qq` does; `<leader>bb` lists rather than picks until the finder; Ctrl-S in insert mode stays in insert mode, as editors with that key do; a count before `<leader>bd` names the buffer number as `:bd N` does.
