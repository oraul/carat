# Backlog: test/domain_jump_list.rb

## Jump list tidy at 9a92265

- Where: `test/domain_jump_list.rb:78` (a Ctrl-I row labeled Ctrl-O); `carat/domain/jump_list.rb:37` (`push` loops though one entry per line exists, and `length_after_push` at :95 repeats the scan); `carat/domain/jump_list.rb:4` (comment wrapped at 37 against 72 columns); `carat/use_cases/definitions/walk_jumps.rb:42` (a gone buffer's entry is dropped and the key does nothing, where Neovim steps on, unstated in `docs/compatibility.md:70`). Periodic quality.
- Why it matters: a mislabeled row and a behavior gap with no compatibility note.
- Fix outline: relabel, one line-index helper, rewrap, and step past dropped entries or record the difference. Queue item `definitions-tidy`.
- Also: carat/domain/jump_list.rb, carat/use_cases/definitions/walk_jumps.rb, docs/compatibility.md
- Category: code-quality
- Added: 2026-11-10
