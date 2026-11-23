# Tasks

## 1. Security

- [x] 1.1 Resolve a program against the absolute `PATH` directories in the process runner's `capture` and `spawn` (`carat/drivers/process_runner.rb`); proved by `test/drivers_process_runner.rb`
- [x] 1.2 Bound the grep picker's reads by `READ_BUDGET` bytes (`carat/plugins/finder/grep.rb`); proved by `test/editor_finder_grep.rb`
- [x] 1.3 Add `Finder::SafeText` and show file finder rows and the preview title through it (`carat/plugins/finder/`); proved by `test/editor_finder.rb`
- [x] 1.4 Bound a span's start with `SyntaxLine::LONGEST_SPAN` in `style_float` and `copied_tokens`; proved by `test/editor_floats.rb` and `test/use_cases_plugin_syntax.rb`

## 2. Tidies

- [x] 2.1 Let go of a hidden slot's view when its plugin is disabled and in `close_scratch` (`TabList#drop_kept`); proved by `test/editor_plugins.rb`
- [x] 2.2 Rename the locals `e` of the plugin host files and share one option lookup (`PluginRegistry#option`)

## 3. Docs

- [x] 3.1 Update `docs/codebase-map.md` and `docs/plugins.md`
