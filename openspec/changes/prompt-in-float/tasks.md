# Tasks

## 1. The attachment

- [x] 1.1 Add `PluginUi#prompt_float`, `Host#float_prompt` (API 2.16), `PluginLink#float_prompt`, `UiRequests#float_prompt`, `WindowRequests#holds_float?`; prove it in `test/use_cases_plugin_files.rb` (Scenario: The cursor stands in the float, Scenario: A refused attachment, Scenario: The attachment ends with the prompt)
- [x] 1.2 Bump the version lines of `test/use_cases_plugins.rb`, `test/domain_plugin_manifest.rb`, and `test/editor_floats.rb` (the plugin-host scenarios naming the host version)

## 2. The presenter

- [x] 2.1 Find the prompt's float, leave the command-line row blank, and place the cursor in the float (`carat/adapters/frame_presenter.rb`); prove it in `test/editor_palette.rb`, `test/editor_finder.rb`, `test/use_cases_plugin_files.rb`

## 3. The palette and the finder

- [x] 3.1 Add the query row and the `Commands N/M` title to the palette's float (`carat/use_cases/discovery/follow_palette.rb`, `Domain::Palette::PROMPT`); prove it in `test/editor_palette.rb` (Scenario: The query is the float's first row (the palette), Scenario: A screen with no room for a list row)
- [x] 3.2 Add the query row to the finder's list float and attach the prompt (`carat/plugins/finder/plugin.rb`); prove it in `test/editor_finder.rb`, `test/editor_finder_grep.rb` (Scenario: The query is the list float's first row (the finder), Scenario: The query row is above the highlight, Scenario: Enter with no match keeps the query in the float, Scenario: The prompt leaves the float when the finder closes)
- [x] 3.3 Update the tests the moved rows touch (`test/editor_cmdline_edit.rb`, `test/editor_cmdline_complete.rb`) and `make snapshots`, the diff read

## 4. Docs

- [x] 4.1 Update `docs/plugins.md`, `docs/codebase-map.md`, `docs/compatibility.md`, `docs/actions.md`, `docs/design.md`, and README.md (`docs/architecture.md` stays at its size budget, unchanged)
- [x] 5.1 A wide character before the cursor had no test of its cells; add it to `test/editor_finder.rb`, fixed
- [x] 5.2 A query wider than the float had no test of the cursor's clamp; add it to `test/editor_finder.rb`, fixed
- [x] 5.3 A query wider than its float is cut, not scrolled; recorded in `docs/findings/prompt-in-float.md`
- [x] 5.4 The grep picker's title keeps its two-count form; recorded in `docs/findings/prompt-in-float.md`
