# Backlog: carat/plugins/ruby/tokenizer.rb

### The ruby tokenizer declares constants among private methods

- Location: carat/plugins/ruby/tokenizer.rb:805, :877 (sweep, quality).
- Why: JUMPS and OPERATOR_NAMES sit apart from the constant block at :25 to :31.
- Fix outline: move both to the top block.
- Category: plugins
- Added: 2026-11-17
