feat(ruby): mark an unclosed block opener without a language server

## Summary

Marks an unclosed `def`, `class`, `module`, `begin`, `case`, `for`, `do`, `if`, `unless`, `while`, or `until` in a Ruby buffer with the error sign on its row, with no language server needed. Before this a missing `end` showed nothing until a language server answered, and nothing at all without one, so it was found only when the file ran.

---

## Changes

- Add `Carat::Plugins::Ruby::Structure`, which runs the tokenizer over a buffer's lines and returns the row of the innermost opener left open
- Change the ruby tokenizer to count per line the openers it leaves open and the `end`s that close earlier ones, skipping modifier `if`, `unless`, `while`, and `until`, the `do` of a loop, an endless `def`, and words in strings, comments, heredocs, symbols, and labels
- Change the ruby plugin to check a Ruby buffer on open, after each change outside insert mode, and when insert mode ends, placing, moving, or clearing its error sign, and bump it to 1.1.0
- Add opener, modifier, closed-file, and literal table rows to `test/plugins_ruby.rb` and the editor test `test/editor_ruby_structure.rb` for the sign in the editor
- Document the structure sign in the README, `docs/plugins.md`, and the code map, and sync the `ruby-syntax` spec through the archived OpenSpec change

---

## Testing

- Run the security review of the committed diff, passed with no high, medium, or low findings
- Run the quality review, passed with no blocking finding and seven advisories recorded in the backlog
- Run the checker stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass
- Run the benchmark against main's figures, passed with `lh-ruby` at 26.0 and `open-ruby` at 24.0 allocations per key
- Run make spec-validate after the archive, all 52 items pass

---

## Notes

An extra `end` with no opener is not marked, and when several openers are left open the innermost is marked rather than guessed by indentation. While typing in insert, replace, or completion mode the sign waits for the mode to end so a keystroke never rescans the buffer. Follow-ups from the quality review, among them a stale sign after a rename and a whole-buffer rescan per normal-mode change, are recorded in the backlog.
