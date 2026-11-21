# Backlog: carat/adapters/tab_bar.rb

## The [No Name] text is defined in both bars

- Where: `NO_NAME` in `carat/adapters/tab_bar.rb` (line 23 at `bars`) and again in `carat/adapters/status_bar.rb` (line 46); at 7711421 also `carat/adapters/winbar.rb` line 17, `carat/use_cases/buffers/list_buffers.rb` line 20, and `carat/domain/messages.rb` line 16 (periodic quality note 33). Quality advisory of `bars`, raised twice.
- Why it matters: one user-visible text has two owners that can drift apart.
- Fix outline: keep one constant, for example beside `Buffer#display_name`, and reference it from both bars.
- Also: carat/adapters/status_bar.rb, carat/adapters/winbar.rb, carat/use_cases/buffers/list_buffers.rb, carat/domain/messages.rb
- Category: editor
- Added: 2026-11-05

## TabBar#icon_group scans every group name on each frame

- Where: `icon_group` in `carat/adapters/tab_bar.rb` (line 136 at `bars`) calls `Highlight.token_id` over every syntax and icon name each time it draws the selected tab, while the `bars` design says the group is resolved once per name. Quality advisory of `bars`.
- Why it matters: a linear scan per frame for a value that changes only with the buffer's icon, and the design text no longer matches the code.
- Fix outline: resolve the group once per icon name (a small Hash, or an id kept beside `Buffer#icon`), or correct the design text, with the tab bar test rows unchanged.
- Category: editor
- Added: 2026-11-05

### Quality: the tab bar's modified-mark fallback cannot trigger, carat/adapters/tab_bar.rb:137

- Why: speculative generality; the `mark(set)` fallback to the ASCII mark cannot trigger, since every shipped set's modified glyph is one cell and the sets are constants, yet it measures the glyph for each modified tab on every frame.
- Fix: drop the fallback and add a test that each set's modified glyph measures one cell, or test the fallback through a wide glyph.
- Category: editor
- Added: 2026-11-14

### carat/adapters/tab_bar.rb:22: NO_NAME "[No Name]" is also defined in carat/adapters/winbar.rb:18, carat/adapters/status_bar.rb:47 (sprint-22 sweep quality)

- Location: `carat/adapters/tab_bar.rb:22`
- Why: NO_NAME "[No Name]" is also defined in carat/adapters/winbar.rb:18, carat/adapters/status_bar.rb:47, carat/use_cases/buffers/list_buffers.rb:22, and written out in carat/domain/messages.rb:22
- Fix: one Domain::Messages::NO_NAME constant that the other four use
- Also: carat/adapters/winbar.rb, carat/adapters/status_bar.rb, carat/use_cases/buffers/list_buffers.rb, carat/domain/messages.rb
- Category: editor
- Added: 2026-11-20

### Comment lines left unwrapped in three files (sprint-24 sweep quality)

- Location: `carat/adapters/tab_bar.rb:19`, `carat/use_cases/plugins/plugin_router.rb:60`, `carat/use_cases/plugins/file_requests.rb:28`
- Why: unwrapped lines amid wrapped prose.
- Fix: rewrap to the surrounding width.
- Also: carat/use_cases/plugins/plugin_router.rb, carat/use_cases/plugins/file_requests.rb
- Category: editor
- Added: 2026-11-21
