# Backlog: test/adapters_server_completions.rb

## The server completions test copies EditorHarness

- Where: `test/adapters_server_completions.rb` line 17 at cd87445 (the `Rig` class copies `type`, `wait`, and `pump` because `carat/doubles/editor_harness.rb` line 38 hard-wires `FixedCompletions`), and its `CompletionRequest` record table (lines 154 to 173). Periodic quality at cd87445. At c1b3a12 there are three rig copies: `test/adapters_signature.rb` line 17, `test/adapters_hover.rb`, and `test/adapters_server_completions.rb` (periodic quality); at 7711421 four, with `test/editor_breadcrumbs.rb` line 24 (note 34). At 2ccf124 seven test files declare `class Rig`, `test/adapters_pathless_language.rb` line 17 among them (quality advisory in `docs-nil-path`).
- Why it matters: two harnesses drift, and a domain record is tested in an adapter test.
- Fix outline: let the harness take any completion port and drive the test through it; move the record table to a domain test. Queued in `completion-tidy`.
- Also: carat/doubles/editor_harness.rb, test/adapters_signature.rb, test/adapters_hover.rb, test/editor_breadcrumbs.rb, test/adapters_pathless_language.rb
- Category: ide
- Added: 2026-11-07

## The resolve cases repeat their setup three times

- Where: `test/adapters_server_completions.rb` line 384 at e1a647c: the two cancellation cases repeat the resolve case's setup (a rig with `resolveProvider`, type `ifi`, answer three described items, `<C-n><C-n>`, wait for `completionItem/resolve`). Quality advisory in `completion-docs`.
- Why it matters: a change to the resolve flow has to be made three times in the test.
- Fix outline: extract a helper such as `resolving(r)` returning the rig with a resolve in flight, beside `completing`. Queued in `completion-docs-tidy`.
- Category: ide
- Added: 2026-11-07
