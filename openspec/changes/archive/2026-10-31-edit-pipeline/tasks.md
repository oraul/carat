# Tasks

## 1. Domain: splice, records, transactions

- [x] 1.1 Add `carat/domain/line_splice.rb` (`LineSplice.apply` with the `SMALL` threshold) and require it from `carat.rb`; verify with the splice rows of the new `test/domain_edits.rb` (same count, grow, shrink, empty result, spans above the threshold at the start, middle, and end)
- [x] 1.2 Add `carat/domain/change_record.rb` (`ChangeRecord`) and `carat/domain/transaction.rb` (`Transaction`) and require them; verify with the record and transaction rows of `test/domain_edits.rb`
- [x] 1.3 Route every primitive of `carat/domain/buffer.rb` through one private `splice`, add `reload`, make `replace` one change, add `id`, `saved_change`, `mark_saved`, `mark_unsaved`, the derived `modified`, and the transaction hooks; verify with `test/domain_buffer.rb` and `test/domain_edits.rb` (records share strings and survive later edits, implicit transactions, joined and nested opens, derived modified flag)
- [x] 1.4 Add the buffer id counter to `carat/domain/editor_state.rb`; verify with the id rows of `test/domain_edits.rb`

## 2. Use cases: the three boundaries and the reloads

- [x] 2.1 Open and close transactions in `carat/use_cases/dispatcher.rb` and close the insert session in `carat/use_cases/leave_insert.rb`; verify with `test/editor_transactions.rb` (`dd`, `3dd`, `o` with typing, visual `d`, an insert session, `j`, `:e!`)
- [x] 2.2 Use `reload` in `carat/use_cases/files/open_file.rb` and `mark_saved` in `carat/use_cases/files/save_file.rb`; verify with `test/use_cases_ex.rb`, `test/editor_cmdline.rb`, and `test/editor_transactions.rb`
- [x] 2.3 Wrap `edit_buffer` and the scratch refresh in `carat/use_cases/plugins/plugin_host.rb`, use `reload` and `mark_unsaved`; verify with `test/use_cases_plugins.rb` (reload delivers `buffer_change`), `test/use_cases_plugin_files.rb`, and the plugin edit row of `test/editor_transactions.rb`

## 3. Enforcement and existing tests

- [x] 3.1 Add the rule to `test/lint.rb` that no file outside `carat/domain/buffer.rb` assigns or mutates `lines`, covering `carat/`, `bin/`, and `test/`; move the tests that wrote `lines` or `modified` directly to the primitives, `mark_saved`, and `mark_unsaved`; verify `make test` passes with the lint snapshot unchanged
- [x] 3.2 Run `make snapshots` and review the diff: only the new tests and the rows whose change counting or modified flag was wrong before may change; verify by reading the diff

## 4. Performance and documentation

- [x] 4.1 Measure `ddP`, `o<Esc>dd`, and typing in the middle of a line on 100,000 lines with the scratch harness against a copy of the branch and of `main` at 2b8b2ba, four runs each: `ddP` 33.0 to 36.2 us per key against a 30 us target (`main` 300 to 378 us), `o<Esc>dd` 28.0 to 31.6 us (`main` 226 to 251 us), typing mid-line 16.3 to 18.6 us, at or below `main` (16.7 to 20.9 us); the remainder is the per-key baseline of about 17 us and Spinel's tail move of the line array
- [x] 4.2 Check `make types` for `Buffer`, `ChangeRecord`, `Transaction`, and `LineSplice` members and keep `make diagnose` clean; verify by the command output
- [x] 4.3 Update `CLAUDE.md` (Layout for `buffer.rb` and the new files, the edit convention), `docs/architecture.md` (entities and a section on the edit path), and `docs/backlog.md` (the six findings); verify by reading the docs against the code

## Workflow follow-up

- Run the security review on the committed branch, archive the change, open the pull request, wait for CI, and squash-merge.
