### Lint misreports a typed readerless keyword behind a parenthesized type
- Location: test/lint.rb:941
- Why: a keyword the signature does type, but behind a type holding a parenthesis before `) ->` (the self-test's `^(Integer) -> void` row), is reported as one the signature does not type, sending the reader to fix a signature that is correct.
- Fix: word the message as a keyword lint cannot read from the one-line `#:` signature directly above `def initialize`, and say how to make the signature readable.

### Lint passes a readerless holder whose initialize parameters span lines
- Location: test/lint.rb:932
- Why: a `def initialize` whose parameters span lines yields no keywords, so a readerless holder with such a def and a signature that `signature_keywords` cannot read still passes unchecked; none exists in `READERLESS_DIRS` today, so the check is silently vacuous for that shape.
- Fix: report a readerless holder whose `def initialize(` line does not close its parameter list on that line, with a self-test row.
