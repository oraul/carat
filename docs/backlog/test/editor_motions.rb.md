# Backlog: test/editor_motions.rb

### Area 6 tests and docs drift (sprint-14 sweep quality)

- Location: test/editor_motions.rb:105, :125 to :127, test/editor_text_objects.rb:67 to :69 (untyped table values); carat/domain/vim_pattern.rb:641 (collection_end comment), :674 (POSIX after private); docs/codebase-map.md:205 (LastSearch, SearchPrompt, VimPattern methods unnamed; code_class tested only in test/domain_line_cache.rb:115).
- Why: the typed-table rule of CLAUDE.md, a comment that misstates the return, and map drift.
- Fix outline: convert with to_s and to_i, reword and move the constant, name the methods and move the assertions. Queued in `motions-search-tidy`.
- Also: test/editor_text_objects.rb, carat/domain/vim_pattern.rb, docs/codebase-map.md, test/domain_line_cache.rb, CLAUDE.md
- Category: code-quality
- Added: 2026-11-17
