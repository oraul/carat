# Tasks

## 1. Security: a replacement is charged before it is built

- [ ] 1.1 `Replacement.size` (`carat/domain/replacement.rb`) and `Substitution.line` (`carat/domain/substitution.rb`) charging it before `Replacement.expand`, the recased difference charged or refunded after (proved by `test/domain_substitute.rb`, "the size of a replacement is the bytes expand builds" and "a replacement past the budget is never built", scenario "A replacement past the budget is never built"; the second fails with the fix reverted)

## 2. One question about the path opened

- [ ] 2.1 `MemoryFiles#dangling` (`carat/doubles/memory_files.rb`) and `OpenFile#call` (`carat/use_cases/files/open_file.rb`) probing once (proved by `test/editor_cmdline.rb`, "a dangling link is refused", scenario "A dangling link is refused"; it fails with the fix reverted)

## 3. No 64 MiB string a test run

- [ ] 3.1 `MemoryFiles#pad` and `test/editor_cmdline.rb` padding `big.bin` and `edge.bin` (proved by "a file over the limit" and "a file of exactly the limit opens")

## 4. The openat gap

- [ ] 4.1 Append the three file-operation headings, merged, to `docs/findings/files-ex-lows.md` with the openat fix outline

## 5. Docs

- [ ] 5.1 `docs/compatibility.md` (`:e` row and the two Differences paragraphs), `docs/codebase-map.md` (`replacement.rb`, `substitution.rb`, `open_file.rb`, `memory_files.rb`), README's `:e` sentence
