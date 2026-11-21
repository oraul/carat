# Backlog: carat/use_cases/plugins/plugin_link.rb

## PluginLink#float_frame's refusal branch is untested (float-placement, quality advisory)

- Where: `carat/use_cases/plugins/plugin_link.rb:276`.
- Why it matters: tests beside behavior: the refusal branch (a disabled plugin answering FloatFrame.failure) is untested; `test/editor_floats.rb` calls WindowRequests#float_frame directly.
- Fix outline: add an assertion through the link for an enabled and a disabled plugin.
- Also: test/editor_floats.rb
- Category: plugins
- Added: 2026-11-14
