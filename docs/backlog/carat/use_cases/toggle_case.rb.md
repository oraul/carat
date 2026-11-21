# Backlog: carat/use_cases/toggle_case.rb

### carat/use_cases/toggle_case.rb:19: rebuilds the row by hand (line[0, col] + Operators.recase(...) (sprint-22 sweep quality)

- Location: `carat/use_cases/toggle_case.rb:19`
- Why: rebuilds the row by hand (line[0, col] + Operators.recase(...) + rest), duplicating Operators.recase_row added in c2fbbb4
- Fix: fresh = Domain::Operators.recase_row(line, col, col + count, :toggle, "")
- Category: editor
- Added: 2026-11-20
