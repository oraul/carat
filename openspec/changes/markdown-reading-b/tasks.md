# Tasks

## 1. Tables in the reader

- [x] 1.1 Give `MarkdownText.parse` (`carat/domain/markdown_text.rb`) the width and the table layout (`table`, `split_cells`, `alignments`, the column widths, cell wrapping, alignment, `box`), passing the width from `FormatDocs` (`carat/use_cases/docs/format_docs.rb`); prove with `test/domain_markdown_text.rb` (a three-column table at 100 and 60 columns with each alignment, ascii borders, no separator row, short and long rows, a separator mismatch and a narrow measure left as source lines)
- [x] 1.2 Prove the view end to end with `test/use_cases_toggle_reading.rb` (the table at 100 and 60 columns, under ascii)

## 2. The gathering

- [x] 2.1 Add `MarkdownText.gather` and call it from `ToggleReading` (`carat/use_cases/docs/toggle_reading.rb`); prove with `test/domain_markdown_text.rb` (an over-cap line read only to the cap on a character boundary, lines under the cap joined whole)

## 3. Docs and checks

- [x] 3.1 Update `docs/codebase-map.md` (`FormatDocs` naming `ToggleReading`, the `MarkdownText` entry and its test's tables) and the README (tables in the reading view); prove with `make docs-lint` and `make lint`
- [ ] 3.2 Run `make gates`, `make spec-validate`, and `make metrics-compare`
