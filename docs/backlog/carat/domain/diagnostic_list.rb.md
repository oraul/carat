# Backlog: carat/domain/diagnostic_list.rb

## DiagnosticList and CompletionList are plain classes

- Where: `carat/domain/diagnostic_list.rb` line 260 and `carat/domain/completion_list.rb` line 8, at b76b722. Periodic quality. Queue item `diagnostics-tidy`.
- Why it matters: CLAUDE.md makes mutable lists `Struct` records; the entry on `FloatLayer` is the same case.
- Fix outline: make them `keyword_init` `Struct` records with a pinned items member, or record in `docs/architecture.md` why item lists are behavior classes.
- Also: carat/domain/completion_list.rb, CLAUDE.md, docs/architecture.md
- Category: ide
- Added: 2026-11-09
