# Tasks

## 1. The flow

- [ ] 1.1 Join a paragraph's and a same-depth quote's lines in `MarkdownText.parse` (`carat/domain/markdown_text.rb`, `flow_key`) with `DocsText#extend_last` (`carat/domain/docs_text.rb`), a hard break and every other block ending the flow; prove with `test/domain_markdown_text.rb` (a two-line paragraph and quote at 60 columns, their spans, a heading, list item, rule, depth change, and hard break left apart)
- [ ] 1.2 Repeat a wrapped row's prefix on its continuation rows in `MarkdownText.wrapped`, spans shifted by `DocsText#copy_spans`, code rows as before; prove with `test/domain_markdown_text.rb` (a flowed quote wider than 60 columns, a bullet's hanging text, ascii) and `test/use_cases_toggle_reading.rb` (the two-line paragraph and quote at 60 columns end to end)

## 2. The folds

- [ ] 2.1 End a table's rows at a block opener in `MarkdownText.table` (`opens_block?`); prove with `test/domain_markdown_text.rb` (a heading, quote, and list item with a pipe right after a table)
- [ ] 2.2 Keep the gap row and top border under the cap in `MarkdownText.table` and `draw_table`; prove with `test/domain_markdown_text.rb` (a table after a gap at a cap of two rows)
- [ ] 2.3 Pass the caps to `FormatDocs#call` (`carat/use_cases/docs/format_docs.rb`) from `ShowHover`, `ShowCompletionDocs`, and `ToggleReading`; prove with `test/use_cases_toggle_reading.rb` and `test/adapters_hover.rb`

## 3. Docs and checks

- [ ] 3.1 Update `docs/codebase-map.md` (the `MarkdownText`, `DocsText`, and `FormatDocs` entries) and the README (paragraphs and quotes flowed); prove with `make docs-lint` and `make lint`
- [ ] 3.2 Run `make gates`, `make spec-validate`, and `make bench SCENARIOS="lh j insert"` (allocations held)
