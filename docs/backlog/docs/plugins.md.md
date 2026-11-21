# Backlog: docs/plugins.md

### Plugin docs, SyntaxCache, and comment layout

- Location: docs/plugins.md:70, carat/domain/syntax_cache.rb:42, carat/use_cases/plugins/buffer_requests.rb:49 (sprint-4 sweep, quality).
- Why: the segment priority list omits progress 35; SyntaxCache calls super() then assigns, unlike LineCache; comments mis-indented or past the wrap width (also window_requests.rb:69, status_bar.rb:16, tab_bar.rb:15, frame.rb:15 and :31).
- Fix: add the priority, pass members to super by keyword, rewrap.
- Also: carat/domain/syntax_cache.rb, carat/use_cases/plugins/buffer_requests.rb
- Category: plugins
- Added: 2026-11-14

### plugins.md names the wrong run_program message for non-UTF-8 output
- Location: docs/plugins.md:79
- Why: the run_program row says it fails with "cannot run git" for non-UTF-8 output, but the message is "git answered bytes that are not UTF-8".
- Fix: name both messages.
- Category: plugins
- Added: 2026-11-16
