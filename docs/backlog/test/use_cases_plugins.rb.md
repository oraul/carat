# Backlog: test/use_cases_plugins.rb

## The version refusal tests hard-code the host version

- Where: `test/use_cases_plugins.rb` lines 178, 179, 185, and 189, at b76b722. Periodic quality. Queue item `slots-tidy`.
- Why it matters: four strings name 2.4 and must be edited at every minor bump.
- Fix outline: interpolate `Carat::PluginApi::VERSION` into the expected messages.
- Category: plugins
- Added: 2026-11-09

### run_program path test rewrites the message before comparing
- Location: test/use_cases_plugins.rb:389
- Why: the assertion rewrites the message with .sub("/usr/bin/git", "./git") before comparing, which hides what is asserted.
- Fix: assert the literal "/usr/bin/git: the program must be a name on the PATH".
- Category: plugins
- Added: 2026-11-16

### focus_window refusal of the completion popup is untested
- Location: test/use_cases_plugins.rb:411 (the plugin-windows requirement on focus_window, openspec/specs/plugin-windows/spec.md)
- Why: the requirement names the completion popup among the floats focus_window refuses, but only another plugin's float is tested, so a regression letting a plugin focus the popup would pass the suite.
- Fix: open the completion popup in the test rig and assert focus_window on its float id answers No window N.
- Also: openspec/specs/plugin-windows/spec.md
- Category: plugins
- Added: 2026-11-18

### make test-one does not compile test/use_cases_plugins.rb
- Location: test/use_cases_plugins.rb through carat/use_cases/history/list_undo.rb:27 and carat/use_cases/history/walk_history.rb:168
- Why: `make test-one T=test/use_cases_plugins.rb` still fails at 25604e0ec359 with "void value not ignored as it ought to be" in the generated C, so the plugin host's main test runs only inside the full runner; a contributor iterating on the plugin host waits about three minutes per change instead of one.
- Fix: make `ListUndo#call` and `WalkHistory#finish` return a typed value on every path (or not use the void result), then confirm test-one compiles the file on its own.
- Also: carat/use_cases/history/list_undo.rb, carat/use_cases/history/walk_history.rb
- Category: plugins
- Added: 2026-11-18

### test/use_cases_plugins.rb did not compile alone at 95bf2e04c258
- Location: `test/use_cases_plugins.rb`, `make test-one T=test/use_cases_plugins.rb` (git-signs-transport retro note 7).
- Why: the plugin host's own test file could not be run alone on the base, so a plugin host change is checked only through the whole runner; the contributor reported it and nothing recorded it.
- Fix: make the file compile alone in `make test-one`; accepted when `make test-one T=test/use_cases_plugins.rb` passes on main.
- Category: plugins
- Added: 2026-11-18

### make test-one does not compile test/use_cases_plugins.rb at 95bf2e04c258 (git-signs-transport retro)
- Location: `test/use_cases_plugins.rb`, `make test-one`
- Why: git-signs-transport's contributor found `make test-one T=test/use_cases_plugins.rb` failing to compile at main 95bf2e04c258 while the full runner passes, so the one-file path a contributor uses to iterate is broken for the plugin host's largest test (retro note 7).
- Fix: find what the file relies on that only the whole runner supplies and make it self-contained; accepted when `make test-one T=test/use_cases_plugins.rb` passes at main.
- Category: plugins
- Added: 2026-11-18
