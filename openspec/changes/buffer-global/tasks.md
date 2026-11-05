# Tasks

## 1. Domain

- [x] 1.1 Add `Domain::GlobalMarks` and the `Buffer#global_marks` member shifted in `Buffer#splice`, proven by `test/domain_global.rb` (marks through inserts and deletes, `take`, `clear`)
- [x] 1.2 Add `Domain::GlobalArgs.parse` (delimiter, pattern, command, E146, E148, Not implemented), proven by `test/domain_global.rb`
- [x] 1.3 Add `Domain::RegisterCount.parse` (`[x] [count]`, E488, E939), proven by `test/domain_global.rb`

## 2. Commands

- [x] 2.1 Add `UseCases::DeleteLines` and `DeleteCommandHandler` (`d[elete]`), wired in `EditorAssembly`, proven by `test/editor_global.rb` and `test/use_cases_ex.rb` (every documented spelling)
- [x] 2.2 Add `UseCases::GlobalCommand` (marks, budget, memory, transaction, loop, messages, recursion) and `GlobalCommandHandler` (`g[lobal]`, `v[global]`), wired in `EditorAssembly`, proven by `test/editor_global.rb` and `test/use_cases_ex.rb`

## 3. Documents and checks

- [x] 3.1 Document `:g`, `:g!`, `:v`, `:d`, and their differences in `docs/compatibility.md`, the files in `docs/codebase-map.md`, `README.md`, and the status line of `CLAUDE.md`, checked by `make docs-lint` and `make gates`
- [x] 3.2 Apply the plan notes to `docs/backlog.md` (remove the image-viewer entry, end three fix outlines with the `phase-shares` line) and add the `:m`, `:t`, `:normal`, `:p` follow-up entry, checked by `make docs-lint`
- [ ] 3.3 Check that `lh`, `j`, `insert`, and `undo` hold 27.0, 28.0, 35.0, and 53.0 objects per key with `make bench-budget` and `make metrics`, and run `make lint`, `make test`, `make diagnose`, and `make gates`, all passing

## Workflow follow-up

- Archive with `openspec archive buffer-global -y`, copy `build/plan/queue.md` over `docs/queue.md`, add the `agent-inputs` metrics row with `sh tools/run_state.sh history`, push, and open the pull request.
