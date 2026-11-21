# Backlog: carat/use_cases/discovery/hide_key_hints.rb

## Three discovery comments are stale or break their wrap

- Where: the class comment of `carat/use_cases/discovery/hide_key_hints.rb` (line 8), the class comment of `carat/use_cases/discovery/show_key_hints.rb` (line 23, longer than its neighbors), and the comment at `carat/use_cases/handle_key.rb` line 66 (breaks after "While the"), at d828abb. Quality advisories in `discoverability`. Raised again at 38628bb (periodic quality). Queued in `menu-hints`.
- Why it matters: the first says a binding resolved by `timeoutlen` closes the hints, but `timeout` never calls `HideKeyHints` and the hints never show over a `:pending` key; the others are style only.
- Fix outline: drop the clause from the `HideKeyHints` comment and rewrap the other two to the width of the lines around them.
- Also: carat/use_cases/discovery/show_key_hints.rb, carat/use_cases/handle_key.rb
- Category: editor
- Added: 2026-11-09

## menu-hints quality advisory at carat/use_cases/discovery/hide_key_hints.rb:7

Location: `carat/use_cases/discovery/hide_key_hints.rb:7`. Why: docs currency; the class comment says `HandleKey` calls it only while the hints show, but `ShowKeyHints#call` now calls it unconditionally before every show. Fix outline: name both callers and say it does nothing while no hints show.
- Category: editor
- Added: 2026-11-14
