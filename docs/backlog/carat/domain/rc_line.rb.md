# Backlog: carat/domain/rc_line.rb

### RcLine splits the key at a literal byte

- Location: carat/domain/rc_line.rb:224. Sprint-6 sweep, quality advisory. Queue item `input-core-tidy`.
- Why: magic number 46 where `RcParser::DOT` names it.
- Fix outline: require rc_parser and use the constant.
- Category: editor
- Added: 2026-11-15
