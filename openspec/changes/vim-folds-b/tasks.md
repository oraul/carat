## 1. Nesting at a shared first row

- [x] 1.1 Change the crossing test of `Folds#create` (`carat/domain/folds.rb`) so a fold sharing the new fold's first row nests or is held, proven by the `[[2,6],[2,3]]` row in `test/domain_folds.rb` and the `zf3jzozfj` rows in `test/editor_folds.rb` (scenario "zf at the first row of an open fold nests in it")

## 2. Folds back on a reverted edit

- [ ] 2.1 Keep a copy of every tracked fold list at `Buffer#transaction_mark` and put it back in `Buffer#revert_to` (`carat/domain/buffer.rb`), proven by "A reverted plugin edit leaves the folds as before" in `test/domain_edits.rb`

## 3. Docs

- [ ] 3.1 Update `docs/compatibility.md` Folding (nesting at a shared first row) and `docs/plugins.md` `edit_buffer` (a failed request leaves the folds), checked by `make docs-lint`

## Workflow follow-up

- Archive with `openspec archive vim-folds-b -y` at packaging.
