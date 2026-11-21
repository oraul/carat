# Backlog: carat/adapters/status_bar.rb

## StatusBar requires the plugin API it does not use

- Where: `require_relative "../plugin_api"` on line 1 of `carat/adapters/status_bar.rb`. Quality advisory of `bars`.
- Why it matters: `StatusBar` names no `PluginApi` constant, so the require is dead and suggests a dependency the adapter does not have.
- Fix outline: drop the require and rebuild with `make dev-build`.
- Category: editor
- Added: 2026-11-05

## StatusBar names a Symbol state and plugin indexes owners

- Where: the `state` parameter of `lsp_group` in `carat/adapters/status_bar.rb` (line 122 at `bars`), beside methods whose `state` is the `EditorState`, and `@owners` (line 55), which holds plugin indexes while `PluginUi#owners` holds names. Quality advisory of `bars`.
- Why it matters: one name for two kinds of value in one file misleads the reader.
- Fix outline: rename them `lsp_state` and `@plugin_indexes`.
- Category: editor
- Added: 2026-11-05

## Bar and frame findings of the periodic review at 186ddfb

- Where: `carat/adapters/status_bar.rb` line 1 requires `../plugin_api` and names none of it; `carat/adapters/frame_presenter.rb` line 299 `display_col` and `display_width` are public but used only inside; `NO_NAME` is defined in `status_bar.rb` line 47, `tab_bar.rb` line 23, and `winbar.rb` line 214. Periodic quality at 186ddfb, queued in `bars-tidy`, the `NO_NAME` triplicate in `top-rows` (the notice border folded into `float-frame`, which drew both boxes through one painter).
- Why it matters: a dead require, a wide public surface, and three constants to keep in step.
- Fix outline: drop the require; move `display_width` below `private` and drop `display_col` (update the area 13 entry); one `[No Name]` on `Domain::Buffer`.
- Also: carat/adapters/frame_presenter.rb
- Category: editor
- Added: 2026-11-10

## Quality: the icon set name "ascii" is a string literal in four places, carat/adapters/status_bar.rb:254

- Location: carat/adapters/status_bar.rb:254, carat/adapters/frame_presenter.rb:217, :266, and :859, beside carat/adapters/options.rb:156 (found reviewing carat-glyphs).
- Why: the set name is compared as a string literal at each site, so a rename or a new set has to find them all.
- Fix: add an Options#ascii_icons? predicate (or an Icons::ASCII_SET constant) and use it at each site so the set name lives in one place.
- Also: carat/adapters/frame_presenter.rb
- Category: editor
- Added: 2026-11-15

### StatusBar requires plugin_api without using it
- Location: carat/adapters/status_bar.rb:1
- Why: the only adapter requiring it, naming no PluginApi constant. Folded into ui-code-tidy.
- Fix: remove the require.
- Category: editor
- Added: 2026-11-17

### Three bars define [No Name]

- Location: carat/adapters/status_bar.rb:47, tab_bar.rb:22, winbar.rb:18 (sweep, quality).
- Why: three copies of one constant.
- Fix outline: one domain constant the three read.
- Category: editor
- Added: 2026-11-17

### The No Name label is spelled in five files (sprint-16 sweep quality)

- Location: carat/adapters/status_bar.rb:47, tab_bar.rb:22, winbar.rb:18, carat/use_cases/buffers/list_buffers.rb:22, carat/domain/messages.rb:22.
- Why: architecture section 5 puts a constant several files need in the domain.
- Fix outline: one Domain::Messages::NO_NAME read by all five.
- Also: carat/use_cases/buffers/list_buffers.rb, carat/domain/messages.rb
- Category: editor
- Added: 2026-11-18
