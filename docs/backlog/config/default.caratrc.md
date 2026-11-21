# Backlog: config/default.caratrc

## Visual star and hash search the word, not the selection

- Where: the `keymap.visual *` and `keymap.visual "#"` lines of `config/default.caratrc` (line 213), bound to `search.word_forward` and `search.word_backward`. Quality advisory of `buffer-search` at 2b54295641e0 and again at a36858a2bc88.
- Why it matters: Neovim's default visual `*` and `#` search the selected text, so a user selecting part of a line gets a different search than in Neovim, and the Search rows of `docs/compatibility.md` do not say so.
- Fix outline: list the difference under Search in `docs/compatibility.md` now, and bind the visual keys to a selection search when one is added. Queued in `search-tidy`.
- Also: docs/compatibility.md
- Category: editor
- Added: 2026-11-04

### The key-hint menu names its entries three ways

- Location: `config/default.caratrc:200` to `:205` (the group names), the action descriptions shown for single keys (the explorer's toggle in `carat/plugins/explorer/plugin.rb`), `carat/domain/key_hints.rb`.
- Why: under `<Space>` entries read as a long sentence (`Open the file tree, focus it, or close it when it is focused`), lowercase group names (`files`, `windows`), and title case (`Command palette`), in an order neither alphabetical nor the configuration's (ux-pass review finding 7). Reproduction: start on a file, `<Space>`, wait one second, `openspec/changes/archive/*-ux-pass/screens/msg-leader-menu.txt`.
- Fix: a short sentence-case label for every entry, groups included (a hint label beside the long description), sorted by key.
- Also: carat/plugins/explorer/plugin.rb, carat/domain/key_hints.rb
- Category: editor
- Added: 2026-11-15
