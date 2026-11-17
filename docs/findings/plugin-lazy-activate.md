### make test-one does not compile test/use_cases_plugins.rb
- Location: test/use_cases_plugins.rb through carat/use_cases/history/list_undo.rb:27 and carat/use_cases/history/walk_history.rb:168
- Why: `make test-one T=test/use_cases_plugins.rb` still fails at 25604e0ec359 with "void value not ignored as it ought to be" in the generated C, so the plugin host's main test runs only inside the full runner; a contributor iterating on the plugin host waits about three minutes per change instead of one.
- Fix: make `ListUndo#call` and `WalkHistory#finish` return a typed value on every path (or not use the void result), then confirm test-one compiles the file on its own.
