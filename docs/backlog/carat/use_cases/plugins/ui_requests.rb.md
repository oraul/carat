# Backlog: carat/use_cases/plugins/ui_requests.rb

## The plugin prompt request names a local e

- Where: `carat/use_cases/plugins/ui_requests.rb` line 92 at 38628bb (periodic quality). Queued in `discoverability-tidy`.
- Why it matters: the naming rule forbids unclear abbreviations.
- Fix outline: rename it entry.
- Category: plugins
- Added: 2026-11-09

## Plugin host requests answer shared strings and stale comments

- Where: `carat/use_cases/plugins/ui_requests.rb` line 78 (`icon` answers the shared glyph) and 107 (`run_ex` answers the message uncopied); `window_requests.rb` line 90 (`open_scratch` keeps the plugin's title string); unused requires in `carat/adapters/status_bar.rb` line 1 and `plugin_syntax.rb` line 1, `plugin_events.rb` line 6 requires `buffer_feed` for `BufferNotice`; stale comments at `carat/adapters/sgr_table.rb` line 8, `plugin_syntax.rb` line 69, `ui_requests.rb` line 81; `plugin_registry.rb` line 175 repeats `cause`; `plugin_events.rb` line 142 queues a resize no plugin wants. Periodic quality at 8d8832f, queued in item 37.
- Why it matters: CLAUDE.md copies strings both ways at the plugin API, so a plugin appending to an answer changes the editor's icons or a buffer title.
- Fix outline: copy each answered and stored string, with rows; fix the requires and comments; return early when no plugin wants the event.
- Also: carat/adapters/status_bar.rb, carat/adapters/sgr_table.rb, CLAUDE.md
- Category: plugins
- Added: 2026-11-10

## Plugin keymap errors are recorded by two copies of one loop

- Where: `carat/use_cases/plugins/ui_requests.rb` line 84 and `WindowRequests#open_scratch` in `carat/use_cases/plugins/window_requests.rb` line 94, each recording a keymap error as `plugin NAME: binding ERROR`. Quality review of `file-finder`.
- Why it matters: a change to the message or the parsing has to be made twice.
- Fix outline: one shared helper, for example on `PluginRegistry`, that builds a plugin's keymap from its lines and records the errors, called from both.
- Also: carat/use_cases/plugins/window_requests.rb
- Category: plugins
- Added: 2026-11-10

### and carat/use_cases/plugins/ui_requests.rb:83 duplicate building a plugin keymap from lines at carat/use_cases/plugins/window_requests.rb:101 (sprint-26 sweep quality, note 33)

- Location: carat/use_cases/plugins/window_requests.rb:101
- Why: and carat/use_cases/plugins/ui_requests.rb:83 duplicate building a plugin keymap from lines and recording each error; open_scratch passes the plugin's bindings uncopied while live_prompt copies them through Boundary.copied_lines, against the strings-copied rule
- Fix: one helper (for example PluginRegistry#keymap_for(name, lines)) that copies, builds, and records, used by both
- Also: carat/use_cases/plugins/window_requests.rb
- Category: plugins
- Added: 2026-11-22
