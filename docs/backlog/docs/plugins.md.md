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

### the api_version history stops at 2.15 while Carat::PluginApi::VERSION is at docs/plugins.md:23 (sprint-30 sweep quality, note 35)

- Location: docs/plugins.md:23
- Why: the api_version history stops at 2.15 while Carat::PluginApi::VERSION is 2.16 (float_prompt, #314), so the one place a plugin author reads what each minor added misses the newest
- Fix: append Version 2.16 adds float_prompt, which attaches the open prompt to one of the plugin's floats
- Category: plugins
- Added: 2026-11-23

### the grep picker paragraph says each preview line and at docs/plugins.md:134 (sprint-30 sweep quality, note 36)

- Location: docs/plugins.md:134
- Why: the grep picker paragraph says each preview line and the title go through safe and the matched line carries the list's '> ' prefix, but the sanitizer is now Finder::SafeText.of and the finder's MARK is the bar '▎ ' (plugin.rb:46; PROMPT is '> ')
- Fix: name SafeText.of and the bar mark
- Category: plugins
- Added: 2026-11-23

### version history skips 2.16 (float_prompt, which the request table at at docs/plugins.md:23 (sprint-32 sweep quality, note 65)
- Location: docs/plugins.md:23
- Why: version history skips 2.16 (float_prompt, which the request table at line 111 dates 2.16) between 2.15 and 2.17
- Fix: add a Version 2.16 sentence naming float_prompt
- Category: quality
