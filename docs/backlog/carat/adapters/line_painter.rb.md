# Backlog: carat/adapters/line_painter.rb

### bidirectional marks and zero-width code points in a file at carat/adapters/line_painter.rb:48 (sprint-30 sweep security Low (3), note 3)

- Location: carat/adapters/line_painter.rb:48
- Why: bidirectional marks and zero-width code points in a file the editor opens are written raw to the terminal, so a planted U+202E reorders the shown text (Trojan Source) while the finder already marks them with Finder::SafeText
- Fix: paint U+200B-200F, U+202A-202E, U+2066-2069 as a marked hex form like the C1 controls, with a test
- Category: security
- Added: 2026-11-23
