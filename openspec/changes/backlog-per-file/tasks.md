## 1. Filing and the move

- [x] 1.1 Add `BACKLOG_DIR`, `file_entries`, `backlog_stream`, and the `backlog-move FILE` subcommand to `tools/run_state.sh`; proven by the `run_state: backlog-move` cases of `tools/tools_test.sh` (first named path, `_general.md`, Also, Category, security, Added, every heading and line kept, FILE removed, a mismatch refused)
- [x] 1.2 Make `backlog-pick` and `backlog-oldest` read directories and order by the `- Added:` date, and `backlog-dups` and `folded_backlog` read the folder (`tools/run_state.sh`); proven by the `run_state: backlog-pick` and `backlog-oldest` cases over a folder
- [x] 1.3 Make `groom` fold the findings files and `groomed.md` per file and remove and merge per backlog file (`tools/run_state.sh`); proven by the `run_state: groom` cases over the folder

## 2. Readers and documents

- [x] 2.1 Check the folder's files in `tools/docs_lint.sh` with `docs/backlog.md` retired; proven by the `docs_lint:` retired-path cases
- [x] 2.2 Point the planner's sprint mode (`.claude/agents/planner.md`) and `.claude/workflows/sprint-planning.js` at the folder, the planner reading only the files it needs; proven by the `agents:` and `sprint:`/`workflow:` text cases of `tools/tools_test.sh`
- [x] 2.3 Update CLAUDE.md, README.md, `docs/architecture.md`, `docs/codebase-map.md`, `docs/spinel-notes.md`, the comments of `tools/gates.sh` and `test/lint.rb`, and `docs/queue-backlog.md` (with the exception line); proven by `make docs-lint` and `make gates`

## 3. The move

- [x] 3.1 Run `sh tools/run_state.sh backlog-move docs/backlog.md`, which proves the move and removes the file; proven by its output and `make docs-lint`

## 4. Quality review

- [x] 4.1 `backlog_move` split the folder's file list on spaces (`$(backlog_files)`): read it line by line (`tools/run_state.sh`); proven by the `run_state: backlog-move` cases
- [x] 4.2 A merged entry's own `- Category:` and `- Added:` lines were dropped without a test: the near-same fixture entry carries both, and `run_state: groom merges a near-same entry keeping both reasons and locations, its own Category and Added lines dropped` proves them gone
- [x] 4.3 The mismatch branch of `backlog-move` (the folder differing from before plus FILE) has no test: filing cannot lose a line by construction, so no fixture reaches it; recorded in `docs/findings/backlog-per-file.md`
