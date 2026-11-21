# Backlog: carat/use_cases/history/walk_history.rb

## WalkHistory keeps one walk's counts in instance variables

- Where: `@gone`, `@back`, and `@empty_before` in `carat/use_cases/history/walk_history.rb` lines 32, 80, and 109 at b0dd342. Periodic quality. Queued in `editing-counts`. Raised again at ce6abdb (line 32; periodic quality): a returned tally value.
- Why it matters: the use case is built once in `EditorAssembly`, so state carries between calls and a nested or interrupted walk reads stale counts, the side channel already listed for `Operate`'s notice.
- Fix outline: return the counts from the step or hold them in a record made per call, passed to the finish.
- Category: editor
- Added: 2026-11-07

### WalkHistory keeps per-call counters as instance state (sprint-16 sweep quality)

- Location: carat/use_cases/history/walk_history.rb:20 (@gone, @back, @empty_before).
- Why: a use case built once and shared holds per-call state reset in start, which a re-entrant call would mix.
- Fix outline: return the counts from step into locals of call, or a small Struct record, and drop the three variables.
- Category: editor
- Added: 2026-11-18

### Design (sprint-20 sweep quality, walk_history.rb:32)

- Location: `carat/use_cases/history/walk_history.rb:32`
- Why: design: per-call scratch counters @gone, @back, @empty_before live on the one shared WalkHistory instance, reset in start and read in finish, so a nested or reentrant walk would corrupt them
- Fix: keep them in a small Struct record built in call and passed to step and finish
- Category: editor
- Added: 2026-11-19
