# Tasks

## 1. Bindings

- [x] 1.1 Add the ten `keymap.normal <C-w><C-x>` lines to `config/default.caratrc` beside their plain forms and regenerate `carat/domain/default_config.rb` with `make gen-config`; proved by `test/config_sync.rb` and `test/domain_keymap.rb` ("default configuration has no keymap problems")
- [x] 1.2 Add a row for two Ctrl keys in one keys word to `test/domain_keys.rb` and a lookup row per new chord to `test/domain_keymap.rb`, snapshots updated

## 2. Behavior tests

- [x] 2.1 Add rows to `test/editor_windows.rb` for every held-Ctrl chord, with counts for `<C-s>`, `<C-v>`, `<C-j>`, `<C-w>`, and `<C-q>`, quit on the last window, and `<C-w><C-c>` changing nothing
- [x] 2.2 Add rows to `test/editor_explorer.rb` for `<C-w><C-l>`, `<C-w><C-h>`, `<C-w><C-w>`, and `<C-w><C-p>` into and out of the tree, with and without a pause after `<C-w>`

## 3. Docs and plan records

- [x] 3.1 Add the held-Ctrl forms to the Windows rows of `docs/compatibility.md` and replace the Differences clause on the `<C-w><C-x>` aliases, stating that `<C-w><C-c>` cancels; checked by `make docs-lint`
- [x] 3.2 Copy `build/plan/goals.md` over `docs/goals.md`, `build/plan/queue.md` over `docs/queue.md`, and add the every-three clarification to `.claude/agents/planner.md` step 2; checked by `make docs-lint` and `make gates`
