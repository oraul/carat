# Backlog: test/adapters_screen_presenter.rb

## The screen presenter's first painted row test accepts two outputs

- Where: `test/adapters_screen_presenter.rb` (line 318 at `theme-tokens`), whose assertion joins two expected sequences with `||`.
- Why it matters: the test does not pin what the presenter writes for the first painted row, so a regression to the other sequence passes.
- Fix outline: assert the one exact sequence the snapshot shows.
- Category: code-quality
- Added: 2026-11-05
