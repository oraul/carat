## 1. Baseline

- [x] 1.1 Build the key benchmark from `main` (0d47323) into the scratch directory and record `make bench` numbers for `lh`, `j`, `insert`, `w`, and `ddp`, pinned to one core (`bench/keys.rb`, no test)

## 2. Domain: the undo tree and the buffer

- [x] 2.1 Add `Domain::UndoTree` (`carat/domain/undo_tree.rb`): the flat table, `push`, `undo_step`, `redo_step`, `path_to`, `nearest`, trimming at the levels, `leaves`, saved-state tracking, and the line `U` restores; proven by the new `test/domain_undo_tree.rb` (branching, `g-` and `g+` order, trimming, saved state)
- [x] 2.2 Merge records on one line in `Transaction#add` and add the history flag and the mark (`carat/domain/transaction.rb`); `test/domain_edits.rb`
- [x] 2.3 Give `BufferFeed` the time and `undolevels` (`carat/domain/buffer_feed.rb`) and `Options` the `undolevels` option (`carat/domain/options.rb`, `config/default.json`, the generated mirror); `test/domain_undo_tree.rb`, `test/config_sync.rb`
- [x] 2.4 Give `Buffer` its tree: push closed transactions of listed file buffers, `revert` and `reapply` through the splice, `transaction_mark`, and the saved state on `mark_saved` (`carat/domain/buffer.rb`); `test/domain_undo_tree.rb` (memory sharing), `test/domain_buffer.rb`, `test/domain_edits.rb`

## 3. Registers

- [x] 3.1 Add the numbered, small delete, black hole, and read-only registers, `yank`, `delete`, `read_with_file`, `valid_name?`, and `read_only?` (`carat/domain/registers.rb`); `test/domain_registers.rb`
- [x] 3.2 Write registers by the yank and delete rules and refuse read-only names in `Operate` and `OperateOnSelection`, and store the last command line in `EditCommandLine`; `test/editor_registers.rb`
- [x] 3.3 Add `RegisterCommandHandler` for `:registers` and `:display` (`carat/use_cases/ex/register_command_handler.rb`); `test/editor_registers.rb`, `test/use_cases_ex.rb`

## 4. Undo use case and keys

- [x] 4.1 Add the `Undo` use case (`carat/use_cases/undo.rb`): undo, redo, absolute, time travel, `U`, `:undolist`, the cursor rule, and the messages; `test/editor_undo.rb`
- [x] 4.2 Add the repeat flag to `ActionHandler` and every handler, and `HistoryHandler` (`carat/use_cases/actions/`); `test/use_cases_actions.rb`
- [x] 4.3 Add `HistoryCommandHandler` for `:undo`, `:redo`, `:undolist`, `:earlier`, `:later` (`carat/use_cases/ex/history_command_handler.rb`); `test/editor_undo.rb`
- [x] 4.4 Bind `U`, `g-`, and `g+` and remove the history actions from the reserved list (`config/default.json`, `carat/use_cases/actions/message_handler.rb`); `test/editor_normal.rb`, `test/config_sync.rb`
- [x] 4.5 Time stamps and the insert-mode arrow split in the dispatcher (`carat/use_cases/dispatcher.rb`); `test/editor_undo.rb`, `test/editor_transactions.rb`
- [x] 4.6 Mark plugin edit requests with the transaction mark (`carat/use_cases/plugins/buffer_requests.rb`); `test/editor_undo.rb` (a plugin edit undone in one step, an undo seen as `buffer_change`)

## 5. Dot command

- [x] 5.1 Add `Domain::LastChange` (`carat/domain/last_change.rb`) and record changes in the dispatcher, `InsertText`, and `LeaveInsert`; `test/editor_repeat.rb`
- [x] 5.2 Add the `RepeatLast` use case (`carat/use_cases/repeat_last.rb`) with counts, numbered registers, visual regions, and insert steps; `test/editor_repeat.rb`
- [x] 5.3 Add normal-mode `r{char}` and `~` (`carat/use_cases/operate.rb`, `carat/use_cases/actions/edit_handler.rb`, `config/default.json`); `test/editor_operators.rb`, `test/editor_repeat.rb`

## 6. Messages of several lines

- [x] 6.1 Paint a message of several lines over the bottom rows with the hit-enter line (`carat/adapters/frame_presenter.rb`) and dismiss it in `HandleKey`; `test/adapters_frame_presenter.rb`, `test/editor_registers.rb`

## 7. Wiring

- [x] 7.1 Wire the tree's feed values, the last change, the clock, and the new handlers in `EditorAssembly` (`carat/adapters/editor_assembly.rb`); `test/adapters_assembly.rb`

## 8. Benchmarks

- [ ] 8.1 Add the `undo`, `undo-line`, `dot-r`, `r`, `dot-dd`, `dd`, `dot-ciw`, `ciw`, and memory scenarios (`bench/keys.rb`, `bench/run.sh`); run `make bench` against the baseline, interleaved and pinned, and record the results in design.md

## 9. Docs and checks

- [x] 9.1 Add every implemented Neovim command to `docs/compatibility.md` and every new action to `docs/actions.md`; record the deferred `:earlier` and `:later` suffixes and `"/` in `docs/backlog.md`
- [x] 9.2 Update `docs/architecture.md` and `CLAUDE.md` (Status: roadmap item 4 done, Layout, Commands if any)
- [ ] 9.3 Regenerate snapshots with `make snapshots`, review the diff, and run `make check` (build, gen-config, test, diagnose) and `make types` for the tree's members
