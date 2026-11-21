# Backlog: carat/domain/palette.rb

## Palette resets its members in two places

- Where: `carat/domain/palette.rb` lines 31 and 55 at 38628bb (periodic quality). Queued in `menu-hints`.
- Why it matters: `initialize` and `start` reset the same members, so a new member must be reset twice.
- Fix outline: one private reset called by both.
- Category: editor
- Added: 2026-11-09

### Palette#start repeats initialize's resets

- Location: carat/domain/palette.rb:58; CommandGrammar#initialize and #reset at command_grammar.rb:37 to :53 alike. Sprint-6 sweep, quality advisory. Queue item `input-core-tidy`.
- Why: a new member has to be reset in two places.
- Fix outline: initialize calls start, then sets the two members start keeps.
- Category: editor
- Added: 2026-11-15
