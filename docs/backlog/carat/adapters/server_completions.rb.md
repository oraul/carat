# Backlog: carat/adapters/server_completions.rb

## ServerCompletions#documentation records the pick inside a query

- Where: `documentation` in `carat/adapters/server_completions.rb` line 50 at 925d759, which sets `docs.pick` and which `ShowCompletionDocs` calls on every key. Quality advisory in `completion-docs`.
- Why it matters: a command hidden in a reader makes the port's contract misleading and the call order load-bearing.
- Fix outline: split it into a `pick(list, index)` command and a `documentation` query, or name it for both, and update `CompletionPort` and `FixedCompletions`. Queued in `completion-docs-tidy`.
- Category: ide
- Added: 2026-11-07
