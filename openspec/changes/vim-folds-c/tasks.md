## 1. Domain

- [ ] 1.1 Add `Folds#open_all`, `#close_all`, `#next_fold_row`, and `#open_fold_row` (carat/domain/folds.rb), proved by test/editor_folds.rb
- [ ] 1.2 Add the motions `motion.fold_next`, `motion.fold_previous`, `motion.fold_start`, `motion.fold_end` as jumps (carat/domain/motions.rb), proved by the fold motion table of test/editor_folds.rb

## 2. Use cases and bindings

- [ ] 2.1 Add the `:open_all` and `:close_all` targets (carat/use_cases/windows/change_folds.rb) and register `fold.open_all` and `fold.close_all` (carat/use_cases/actions/fold_handler.rb), proved by test/editor_folds.rb
- [ ] 2.2 Bind `zR zM` in normal mode and `zj zk [z ]z` in normal, operator_pending, visual, visual_line, and visual_block (config/default.caratrc, `make gen-config`), proved by test/config_sync.rb and test/editor_folds.rb

## 3. Tests and docs

- [ ] 3.1 Table rows for every key and the `:q` slot-window assertion (test/editor_folds.rb)
- [ ] 3.2 Rows in docs/compatibility.md and docs/actions.md, the jump motion list, and the README fold sentence
