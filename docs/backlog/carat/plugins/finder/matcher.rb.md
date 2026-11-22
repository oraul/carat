# Backlog: carat/plugins/finder/matcher.rb

## The finder's sort key relies on the host's file cap

- Where: `carat/plugins/finder/matcher.rb` line 25, `INDEX_BITS` 20 (1,048,575 indexes), and `MAX_FILES` of 100,000 in `carat/use_cases/plugins/file_requests.rb` line 20. Quality review of `file-finder`.
- Why it matters: a cap above `INDEX_ROOM` would silently corrupt the packed keys.
- Fix outline: say so beside `INDEX_ROOM`, or skip indexes above `INDEX_ROOM` in `Plugin#filter`.
- Also: carat/use_cases/plugins/file_requests.rb
- Category: plugins
- Added: 2026-11-10

## Small tidy-ups in the finder and the plugin host

- Where: `carat/plugins/finder/matcher.rb` line 1 requires `plugin_api.rb` but uses nothing from it; `carat/plugins/finder/plugin.rb` line 29, `OPEN`, names one action used once in `on_action` while the manifest and the other branches spell action names as literals; `carat/use_cases/plugins/plugin_host.rb` line 194, `follow_prompt`, dups the text into `prompt_seen` and `PluginRouter#follow_prompt` dups it again. Quality review of `file-finder`.
- Why it matters: a dead require, an inconsistent naming of actions, and a second string copy per prompt key.
- Fix outline: drop the require; drop `OPEN` and compare against the literal (or name every action the same way); dup once, in the router where the value crosses to the plugin.
- Also: carat/plugins/finder/plugin.rb, carat/use_cases/plugins/plugin_host.rb
- Category: plugins
- Added: 2026-11-10

### word_at counts every non-ASCII character as a word character
- Location: carat/plugins/finder/matcher.rb `word_byte?` (bytes of 0x80 or more), used by `word_at`.
- Why: a typographic quote, a non-breaking space, or CJK punctuation next to a word joins it, so Space f w can put the punctuation on the prompt; the grep picker's whole-word match shares the rule, so changing one alone would make them disagree.
- Fix: classify code points by Unicode letter and number classes through a table in Matcher for both word_at and the whole-word match, with rows for each class.
- Category: plugins
- Added: 2026-11-22
