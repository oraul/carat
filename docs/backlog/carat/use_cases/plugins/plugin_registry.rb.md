# Backlog: carat/use_cases/plugins/plugin_registry.rb

## A disabled plugin's view kept by a hidden slot stays held

- Where: `close_scratch_windows` in `carat/use_cases/plugins/plugin_registry.rb` line 350, at b76b722. Periodic quality. Queue item `slots-tidy`.
- Why it matters: it walks only layout leaves, so a removed buffer stays held by the slot (`TabList#shown?` still true) until a later toggle clears it.
- Fix outline: in `clean_up` clear each slot of every tab page that keeps one of the plugin's buffers, with a row in `test/use_cases_plugin_hardening.rb`.
- Also: test/use_cases_plugin_hardening.rb
- Category: plugins
- Added: 2026-11-09
