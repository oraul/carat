# Backlog: carat/plugins/ruby/line_state.rb

### The groom removed the Ruby nesting limit entry though the limits still stand
- Location: docs/backlog.md:101 (the removed heading 'Ruby constructs nested deeper than the state encodes'); carat/plugins/ruby/line_state.rb:19 and :28-30
- Why: line_state.rb still keeps MAX_HEREDOCS = 2, MAX_FRAMES = 2, MAX_TERMINATORS = 255 and its header still says a third frame or heredoc is dropped, so a still-open limit is dropped against none dropped.
- Fix: re-add the entry narrowed to the third string frame, the third heredoc, and the 256th terminator, in the next records change.
- Category: plugins
- Added: 2026-11-21
