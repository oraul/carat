# Tasks

## 1. Security: a replacement is charged before it is built

- [x] 1.1 `Replacement.size` (`carat/domain/replacement.rb`) and `Substitution.line` (`carat/domain/substitution.rb`) charging it before `Replacement.expand`, the recased difference charged or refunded after (proved by `test/domain_substitute.rb`, "the size of a replacement is the bytes expand builds" and "a replacement past the budget is never built", scenario "A replacement past the budget is never built"; the second fails with the fix reverted)

## 2. One question about the path opened

- [x] 2.1 `MemoryFiles#dangling` (`carat/doubles/memory_files.rb`) and `OpenFile#call` (`carat/use_cases/files/open_file.rb`) probing once (proved by `test/editor_cmdline.rb`, "a dangling link is refused", scenario "A dangling link is refused"; it fails with the fix reverted; `test/use_cases_ex.rb`'s stale stat-race check now expects a new file, and "edit of a path removed between its stat and the read is E484" covers the read's race)

## 3. No 64 MiB string a test run

- [x] 3.1 `MemoryFiles#pad` and `test/editor_cmdline.rb` padding `big.bin` and `edge.bin` (proved by "a file over the limit" and "a file of exactly the limit opens")

## 4. The openat gap

- [x] 4.1 Append the three file-operation headings, merged, to `docs/findings/files-ex-lows.md` with the openat fix outline

## 5. Docs

- [x] 5.1 `docs/compatibility.md` (`:e` row and the two Differences paragraphs), `docs/codebase-map.md` (`replacement.rb`, `substitution.rb`, `open_file.rb`, `memory_files.rb`), README's `:e` sentence; `docs/architecture.md` section 7's project-file line trimmed back under its docs-lint budget, which main exceeded by 8 bytes

## Quality review

- [x] Q.1 `Substitution`'s and `MemoryFiles`' doc comments had lines past the file's wrap after the edits; rewrapped (fixed)
- [x] Q.2 `MemoryFiles#dangling` (listing, create refused) and `MemoryFiles#pad` (the write dropping it, the read limit) had no direct test; `test/use_cases_plugin_files.rb` checks each (fixed; "a dangling link is listed and stats as a link that is not regular, yet does not exist", "a write drops the padding")
- [x] Q.3 `Replacement.size` restates `Replacement.expand`'s item walk; kept, guarded by the comparison table (recorded in `docs/findings/files-ex-lows.md` with its reason)
- [x] Q.4 The never-built check fails its reverted fix only by exhausting memory (recorded in `docs/findings/files-ex-lows.md` with its reason)
