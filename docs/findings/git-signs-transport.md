### focus_window refusal of the completion popup is untested
- Location: test/use_cases_plugins.rb:411 (the plugin-windows requirement on focus_window, openspec/specs/plugin-windows/spec.md)
- Why: the requirement names the completion popup among the floats focus_window refuses, but only another plugin's float is tested, so a regression letting a plugin focus the popup would pass the suite.
- Fix: open the completion popup in the test rig and assert focus_window on its float id answers No window N.
