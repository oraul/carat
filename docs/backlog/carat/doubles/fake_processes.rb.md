# Backlog: carat/doubles/fake_processes.rb

### carat/doubles/fake_processes.rb:69 methods_sent reads the method field twice

- Quality advisory, duplication: methods_sent reads Json.field(value, "method") twice in one expression.
- Fix: name = Json.field(value, "method"), then name.is_a?(String) ? name.to_s : "result".
- Category: editor
- Added: 2026-11-15
