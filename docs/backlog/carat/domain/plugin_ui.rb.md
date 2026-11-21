# Backlog: carat/domain/plugin_ui.rb

## PluginUi keeps each segment in three structures

- Where: the `segments` Hash of `carat/domain/plugin_ui.rb` (lines 12 to 25 and `text_at`, line 61 at `bars`), keyed by the names `owners` already holds in order, beside `priorities`. Quality advisory of `bars`, raised twice.
- Why it matters: the text is read only as `segments[owners[i]]`, so `remove_segment` has to keep three structures in step for one ordered list.
- Fix outline: keep the texts in an array parallel to `owners` and `priorities`, drop the Hash, and update the tests that compare `segments`.
- Category: plugins
- Added: 2026-11-05

## Four comments of bars break their file's wrap width

- Where: `carat/domain/plugin_ui.rb` (line 7, 92 characters) and `carat/use_cases/plugins/ui_requests.rb` (line 15, 91 characters) run past the width; `carat/adapters/frame_presenter.rb` (line 63) and `carat/domain/highlight.rb` (line 6) end ragged. Quality advisory of `bars`.
- Why it matters: style only; the rest of each file wraps comments at the surrounding width.
- Fix outline: rewrap the four comments to the width of the lines around them, together with the nine-comment entry above.
- Also: carat/use_cases/plugins/ui_requests.rb, carat/adapters/frame_presenter.rb, carat/domain/highlight.rb
- Category: plugins
- Added: 2026-11-05
