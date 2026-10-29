# Tasks

## 1. Exit and quit-all in the ex registry

- [x] 1.1 Add the `x xit exi exit` arm and the private `exit_editor` helper to `ExecuteEx` in `carat/use_cases/files/execute_ex.rb`, writing through `SaveFile` when the buffer is modified or an argument is given and quitting through `Quit` with the bang forced after a successful write, with inline RBS signatures; verify with a table in `test/use_cases_ex.rb` covering every spelling with and without bang on a clean buffer, a modified buffer, a buffer with no name, a file argument, and an unwritable file
- [x] 1.2 Add the `qa qall quita quitall` arm to `ExecuteEx` calling `Quit` with the command's bang; verify with a table in `test/use_cases_ex.rb` covering every spelling with and without bang on a clean and a modified buffer, asserting `E37` and the quit flag

## 2. Write-all and write-quit-all

- [x] 2.1 Add the `wa wall` arm and the private `write_all` helper to `ExecuteEx`, skipping an unmodified buffer, reporting `E141: No file name for buffer 1` for a modified buffer with no path, and otherwise writing through `SaveFile`; verify with a table in `test/use_cases_ex.rb` covering both spellings with and without bang on a clean buffer, a modified buffer, a buffer with no name, and an unwritable file
- [x] 2.2 Add the `wqa wqall xa xall` arm to `ExecuteEx` composing `write_all` and a forced `Quit` as `:wq` does; verify with a table in `test/use_cases_ex.rb` covering every spelling with and without bang on a clean buffer, a modified buffer, a buffer with no name, and an unwritable file, asserting the file text, the message, and the quit flag

## 3. Whole-editor coverage and documentation

- [x] 3.1 Extend `test/editor_cmdline.rb` with `:x<CR>` on a modified and a clean buffer, `:wqa!<CR>`, `:wa<CR>`, `:qa<CR>` refused on a modified buffer and `:qa!<CR>`, typed through `EditorHarness`; verify the assertions on the file text, the message row, and the quit flag pass
- [x] 3.2 Add one row per command to the ex section of `docs/compatibility.md` in the style of the `:wq` row, naming `use_cases_ex` and `editor_cmdline`, extend the differences note with the single-buffer reading of the "all" forms, the missing `E162` line, and the `:x` file-argument reading, and name the new commands in the Status paragraph of `CLAUDE.md`; verify every new command has a row and the note lists no command that now exists
- [x] 3.3 Run `make snapshots` for `test/use_cases_ex.rb` and `test/editor_cmdline.rb`, review the diff, then `make check` (build, gen-config, test, diagnose); verify everything passes and `spinel-doctor` reports clean

## Workflow follow-up

- Run the security review on the committed branch, then archive the change, open the pull request, and squash-merge it after CI is green.
