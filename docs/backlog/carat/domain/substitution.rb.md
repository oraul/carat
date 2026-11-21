# Backlog: carat/domain/substitution.rb

## A substitute expands a replacement before charging the budget

- Where: `carat/domain/substitution.rb` line 44, and its comment at line 12, which says each character of replacement text is charged where line 45 charges `piece.bytesize`. Periodic security Low (6) and quality advisory at f31f4e8.
- Why it matters: `:s/.*/&&&&&&&&/`, or a replacement grown by `~` to 1 MiB of `&`, on a long line of an untrusted file (up to 64 MiB) builds replacement bytes times match length in one piece before the budget stops it, which can exhaust memory and lose unsaved buffers, against the comment's output bound.
- Fix outline: charge each group's and literal's bytes as the expansion grows and stop once the budget runs out, with a `test/domain_substitute.rb` row for a large `&` count on a long line, and say bytes in the comment. Queued in `substitute-tidy`.
- Also: test/domain_substitute.rb
- Category: security
- Added: 2026-11-04
