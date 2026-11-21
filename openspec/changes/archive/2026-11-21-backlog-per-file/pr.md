chore(backlog): split the backlog into one file per named path

## Summary

Moves every backlog entry out of the single docs/backlog.md into docs/backlog/, one file per source file the entry names first, and points groom, backlog-pick, backlog-oldest, the planner, and the documents at the folder. The one backlog file had grown to about 1 MB, and the sprint planner read it whole; the user asked on 2026-11-21 that the planner read only the files its queue and pool name.

---

## Changes

- Move each entry, its lines unchanged, to docs/backlog/ followed by its path, a leading dot of each path part written as an underscore, or to docs/backlog/_general.md when it names no file, adding an Also line for the other files it names, a Category line (a security entry always security), and an Added date line, and remove docs/backlog.md
- Add the run_state.sh backlog-move command, which files every entry, proves the folder's headings and entry lines equal those before plus the moved file's (count and set) before it removes the file, and refuses a symbolic link on the way to a backlog file
- Change groom to file each findings entry and each groomed.md entry into the backlog file of its first named path, to remove and merge entries per backlog file, removing a file left empty, and to remove the findings files
- Change backlog-pick and backlog-oldest to read files or folders and order entries oldest first by their Added date across files, and backlog-dups to read the folder
- Change the planner's sprint mode to read only the backlog files of the files and areas its queue items and pool name, plus the closing sprint's findings files, and sprint-planning.js to run backlog-oldest and backlog-pick over the folder
- Change docs_lint.sh to check the folder's files as documents and to accept a backticked docs/backlog.md, now retired, in a backlog file or a lane queue
- Add tools-test cases for the move, the symbolic link refusals, the underscore folders, groom per file, and backlog-pick and backlog-oldest over a folder
- Document the folder in CLAUDE.md, README.md, docs/architecture.md, docs/codebase-map.md, docs/spinel-notes.md, and the comments of gates.sh and lint.rb, and add the user-approved exception line under the Sprint 25 heading of docs/queue-backlog.md

---

## Testing

- Run the security review of the committed diff at bb58f82, pass with no High, Medium, or Low finding open, after the fix round closed two Lows (the symbolic link write and the dotted folder names)
- Run the checker's stages at bb58f82 (gates, docs-lint, dev-build, test-build, diagnose, test-run, tools-test, bench-budget, metrics), all pass
- Run the benchmark review, pass with nothing blocking
- Run the contributor's quality review of the diff, two findings fixed with a test each and one recorded in the findings file
- Run make spec-validate after the archive, 55 passed and 0 failed

---

## Notes

The guard on the folder, the contributor's read access to its own edited files' backlog files, the backlog-index command, and the planner's sprint order are the next backlog-lane change, backlog-per-file-b. The docs/backlog.md alternative of tools/rules.sh and the pointer on line 3 of docs/queue-feature.md, the feature lane's file, stay for later changes, both named in this change's findings file. The plan-apply of the package step brought back a stale lane queue, which was restored to the branch's version and recorded in the findings file.
