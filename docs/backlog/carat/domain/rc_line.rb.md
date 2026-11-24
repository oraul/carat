# Backlog: carat/domain/rc_line.rb

### RcLine splits the key at a literal byte

- Location: carat/domain/rc_line.rb:224. Sprint-6 sweep, quality advisory. Queue item `input-core-tidy`.
- Why: magic number 46 where `RcParser::DOT` names it.
- Fix outline: require rc_parser and use the constant.
- Category: editor
- Added: 2026-11-15

### compares with the literal byte 46 although RcParser::DOT names it at carat/domain/rc_line.rb:250 (sprint-32 sweep quality, note 57)
- Location: carat/domain/rc_line.rb:250
- Why: compares with the literal byte 46 although RcParser::DOT names it; options.rb:234, 495, and 504 use 44 and 58 for comma and colon, and rc_value.rb:10 defines ZERO and NINE again beside RcParser's
- Fix: name each byte once (RcParser::DOT, and COMMA and COLON constants) and use those names
- Category: quality
