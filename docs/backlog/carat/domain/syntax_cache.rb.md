# Backlog: carat/domain/syntax_cache.rb

## No semantic highlighting from the language server

- Where: the syntax cache in `carat/domain/syntax_cache.rb` holds only a tokenizer's tokens; roadmap item 10, `language-services`, brings `ruby-lsp`.
- Why it matters: a language server knows which names are locals, parameters, methods, and constants, which a line tokenizer can only guess (vim-ruby's heuristics for `/`, `%`, `?`, and `<<` misjudge unusual code).
- Fix outline: once the language gateway exists, request `textDocument/semanticTokens/range` for the visible rows and paint them as a layer over the tokenizer's, invalidated by the same change records.
- Category: editor
- Added: 2026-11-03

### SyntaxCache#lookup recomputes start_of

- Location: carat/domain/syntax_cache.rb:159, :83 (sweep, quality).
- Why: row == 0 ? 0 : ends[row - 1] copies start_of.
- Fix outline: start = start_of(row).
- Category: editor
- Added: 2026-11-17
