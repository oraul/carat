# Tasks

## 1. The marker scan

- [x] 1.1 Read a line's spaces and quote markers once in `MarkdownText.markers` (`carat/domain/markdown_text.rb`) for `flow_key`, `marker_end`, and `block`, the dead indent cap dropped and an indented code line in a quote kept on its row; prove with `test/domain_markdown_text.rb` (two indented code lines in a quote, a quote line mixing spaces and markers alone and joined, its cut byte equal for all readers)

## 2. Headings and framed code

- [x] 2.1 Frame fenced code in `MarkdownText.wrap` when asked, spans shifted onto the code, and pass the flag through `FormatDocs#call` (`carat/use_cases/docs/format_docs.rb`) from `ToggleReading` (true), `ShowHover` and `ShowCompletionDocs` (false); prove with `test/domain_markdown_text.rb` (a heading and a framed code block each in its style, a line wider than the measure, ascii) and `test/use_cases_toggle_reading.rb` (the notes view with its frame)

## 3. Docs and checks

- [x] 3.1 Update `docs/codebase-map.md` (the `MarkdownText`, `FormatDocs`, and `ToggleReading` entries) and the README (framed code); prove with `make docs-lint` and `make lint`
- [ ] 3.2 Run `make gates` and `make spec-validate`
