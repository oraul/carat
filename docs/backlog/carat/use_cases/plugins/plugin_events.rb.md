# Backlog: carat/use_cases/plugins/plugin_events.rb

## A plugin's resize event is built with no subscriber

- Where: `resized` in `carat/use_cases/plugins/plugin_events.rb` line 142 at 847851d; `queue` (line 200) skips unwanted events. Periodic quality. Queue item: backlog items, plugin host classes.
- Why it matters: an event is built for nobody on every resize.
- Fix outline: update the last size, then return unless a plugin wants `resize`.
- Also listed in "Plugin, grammar, and generator findings at df4654c" (periodic quality): `carat/use_cases/plugins/plugin_events.rb` line 142 (a resize event built with no subscriber); fix: return unless `wanted?("resize")`.
- Category: plugins
- Added: 2026-11-09

## Plugin entries and edits are named e

- Where: `carat/use_cases/plugins/plugin_events.rb` lines 213 and 227, `plugin_host.rb` lines 95 and 141, `buffer_requests.rb` line 61 at 847851d, beside the queued `ui_requests.rb` line 92. Periodic quality. Queue item: backlog items, plugin host classes.
- Why it matters: CLAUDE.md naming forbids unclear abbreviations.
- Fix outline: rename them `entry` and `edit` with the `ui_requests` fix.
- Also: CLAUDE.md
- Category: plugins
- Added: 2026-11-09

## A feed notice builds an event no plugin subscribes to

- Where: `carat/use_cases/plugins/plugin_events.rb:188` (`enqueue`).
- Why it matters: every closed transaction builds an Event, a PendingEvent, and two string copies though no shipped plugin subscribes, against the comment's promise; `ddp` and `dot-ciw` pay it.
- Fix outline: return early unless the event is wanted, keeping the open and close bookkeeping; confirm with `make bench`. Queue item `insert-copy`.
- Category: plugins
- Added: 2026-11-10
