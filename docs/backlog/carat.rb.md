# Backlog: carat.rb

## carat.rb misses two production files

- Where: `carat.rb:2`; `carat/domain/border_style.rb`, `carat/use_cases/actions/search_handler.rb`. Periodic quality. Raised again at 9a92265 (#99): `carat/adapters/indent_guides.rb` is missing too, making three.
- Why it matters: the header promises every file once; both are reached only transitively.
- Fix outline: add both in layer order; `test/lint.rb` checks every production file is required. Queue item `docs-index`.
- Also: carat/domain/border_style.rb, carat/use_cases/actions/search_handler.rb, carat/adapters/indent_guides.rb, test/lint.rb
- Category: editor
- Added: 2026-11-10

### carat.rb misses three files

- Location: carat.rb:2 (sweep, quality).
- Why: indent_guides.rb, border_style.rb, and search_handler.rb are reached only through other files, though the header says every file is pulled in here.
- Fix outline: add each to its layer section.
- Category: editor
- Added: 2026-11-17

### Requires leaned on carat.rb order (sprint-18 sweep quality)
- Location: `carat/use_cases/plugins/buffer_requests.rb:110`, `:49`; `carat/domain/messages.rb:22`; `carat/domain/walker.rb:63`; `carat/use_cases/search/find_match.rb:140`.
- Why it matters: Highlight, ControlText, and `Motions.code_class` are named without a require, Walker and Motions form a hidden cycle, `blank?` repeats `code_class`, and one comment line is mis-indented.
- Fix outline: add the requires, move `code_class` and `blank?` where both require it, use `code_class`, reindent.
- Also: carat/use_cases/plugins/buffer_requests.rb, carat/domain/messages.rb, carat/domain/walker.rb, carat/use_cases/search/find_match.rb
- Category: editor
- Added: 2026-11-18

### drift: the comment says every file is pulled in at carat.rb:2 (sprint-26 sweep quality, note 41)

- Location: carat.rb:2
- Why: drift: the comment says every file is pulled in here once and CLAUDE.md calls carat.rb the production require graph, but six production files are not named: carat/domain/border_style.rb, carat/domain/folds.rb, carat/adapters/indent_guides.rb, carat/adapters/whitespace_marks.rb, carat/use_cases/actions/search_handler.rb, carat/use_cases/concerns/undo_syncing.rb, reached only through other files
- Fix: add each in its layer block, or reword the comment
- Also: CLAUDE.md, carat/domain/border_style.rb, carat/domain/folds.rb, carat/adapters/indent_guides.rb, carat/adapters/whitespace_marks.rb, carat/use_cases/actions/search_handler.rb, carat/use_cases/concerns/undo_syncing.rb
- Category: editor
- Added: 2026-11-22
- Merged: ### carat.rb:2: the comment says every file is pulled in here (sprint-22 sweep quality)
- Location: `carat.rb:2`
- Why: the comment says every file is pulled in here once, but carat/adapters/indent_guides.rb, carat/domain/border_style.rb, carat/domain/folds.rb, carat/use_cases/actions/search_handler.rb, and carat/use_cases/concerns/undo_syncing.rb are reached only through other files require_relative lines
- Fix: add them to carat.rb in layer order, or reword the comment
- Also: carat/adapters/indent_guides.rb, carat/domain/border_style.rb, carat/domain/folds.rb, carat/use_cases/actions/search_handler.rb, carat/use_cases/concerns/undo_syncing.rb

### methods_sent calls Json.parse without requiring carat/domain/json, relying on carat.rb's at carat/doubles/fake_processes.rb:140 (sprint-30 sweep quality, note 73)

- Location: carat/doubles/fake_processes.rb:140
- Why: methods_sent calls Json.parse without requiring carat/domain/json, relying on carat.rb's load order
- Fix: add require_relative ../domain/json
- Also: carat/doubles/fake_processes.rb
- Category: editor
- Added: 2026-11-23
