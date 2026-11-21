# Backlog: test/domain_grammar.rb

### test/domain_grammar.rb:15 two forms of reading a table element

- Quality advisory, one clear way: DomainGrammarTest wraps Carat::Json.element as at while about thirty other test files call Carat::Json.element inline, and the tests use a JSON reader as a general untyped-array reader.
- Fix: pick one form, either a named element reader in Carat::Testing used by every test or the inline call everywhere with at dropped.
- Category: code-quality
- Added: 2026-11-15
