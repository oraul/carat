# Tasks

## 1. The flow

- [x] 1.1 Join a paragraph's and a same-depth quote's lines in `MarkdownText.parse` (`carat/domain/markdown_text.rb`, `flow_key`) with `DocsText#extend_last` (`carat/domain/docs_text.rb`), a hard break and every other block ending the flow; prove with `test/domain_markdown_text.rb` (a two-line paragraph and quote at 60 columns, their spans, a heading, list item, rule, depth change, and hard break left apart)
- [x] 1.2 Repeat a wrapped row's prefix on its continuation rows in `MarkdownText.wrapped`, spans shifted by `DocsText#copy_spans`, code rows as before; prove with `test/domain_markdown_text.rb` (a flowed quote wider than 60 columns, a bullet's hanging text, ascii) and `test/use_cases_toggle_reading.rb` (the two-line paragraph and quote at 60 columns end to end)

## 2. The folds

- [x] 2.1 End a table's rows at a block opener in `MarkdownText.table` (`opens_block?`); prove with `test/domain_markdown_text.rb` (a heading, quote, and list item with a pipe right after a table)
- [x] 2.2 Keep the gap row and top border under the cap in `MarkdownText.table` and `draw_table`; prove with `test/domain_markdown_text.rb` (a table after a gap at a cap of two rows)
- [x] 2.3 Pass the caps to `FormatDocs#call` (`carat/use_cases/docs/format_docs.rb`) from `ShowHover`, `ShowCompletionDocs`, and `ToggleReading`; prove with `test/use_cases_toggle_reading.rb` and `test/adapters_hover.rb`
- [x] 2.4 Keep each line of a table the width cannot draw its own row, unflowed, in `MarkdownText.parse` and `MarkdownText.table` (-2 for a matching header and separator too narrow for the width); prove with `test/domain_markdown_text.rb` (a narrow table with a third, longer row and a paragraph line after it, at width 15)

## 3. Docs and checks

- [x] 3.1 Update `docs/codebase-map.md` (the `MarkdownText`, `DocsText`, and `FormatDocs` entries) and the README (paragraphs and quotes flowed); prove with `make docs-lint` and `make lint`
- [x] 3.2 Run `make gates`, `make spec-validate`, and `make bench SCENARIOS="lh j insert"` (allocations held)
