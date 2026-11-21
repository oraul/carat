# Backlog: carat/use_cases/search/substitute_lines.rb

### Substitute's count range repeats ExRange#counted (sprint-16 sweep quality)

- Location: carat/use_cases/search/substitute_lines.rb:65, against ExRange#counted (ex_range.rb:112).
- Why: the same Vim count rule is computed twice, the line commands using counted.
- Fix outline: pass or build an ExRange and call counted.
- Category: editor
- Added: 2026-11-18
