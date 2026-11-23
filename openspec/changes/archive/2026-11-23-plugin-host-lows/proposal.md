# Proposal

## Why

Four Low security findings from an untrusted repository sit in the plugin host and the finder: a program a plugin runs is looked up through every `PATH` entry, a relative or empty one being the project's own directory, so a project's `git` or `ruby-lsp` runs; the grep picker reads every listed file, up to 262,144 bytes each, on the editor thread, and a listing of files of empty lines stores no line, so nothing bounds the reads; the finder shows a listed path raw in its rows and the preview title, where U+202E reorders the text; and a float span or syntax token whose start is far above any line is kept unchecked. Five tidies of the same files (a hidden slot keeping a disabled plugin's view, `close_scratch` missing that view, locals named `e`, two option lookups) ride along.

## What Changes

- Change the process runner's `capture` and `spawn`: the program is resolved against the absolute directories of `PATH` only, an executable regular file, and started by that absolute path; a relative or empty entry and an unresolved name start nothing.
- Change the grep picker's `load`: it stops once the files read hold `READ_BUDGET` (16 MiB) bytes, marking the store cut as the line cap does.
- Add `Finder::SafeText`, the one sanitizer (moved out of `Grep`), and use it for the file finder's rows and the preview title.
- Change `style_float` to refuse a span starting past `SyntaxLine::LONGEST_SPAN`, and `PluginSyntax#copied_tokens` to drop a token starting past it and cut a length to it; the constant moves to `Domain::SyntaxLine`.
- Fix a hidden slot keeping a plugin's view: `TabList#drop_kept` lets go of the slot windows over a buffer; the registry calls it before removing a disabled plugin's buffer, and `close_scratch` calls it when no leaf shows the view.
- Refactor: the locals `e` of the plugin host files become `entry`, `found`, `registered`, and `edit`; `PluginRegistry#option_value` is the one option lookup of `PluginHost` and `UiRequests`.

Assumptions: with `PATH` unset a bare name starts nothing; the language-server spawn takes the same resolution (a configured command that is a bare name); the read budget of 16 MiB is about the 400,000-line cap at 40 bytes a line; the two findings the brief names only by location (`plugin_router.rb:44`, `manifest_check.rb:32`) are recorded in the findings file, not changed.

## Capabilities

### New Capabilities

### Modified Capabilities

- `plugin-host`: a program runs only from an absolute `PATH` directory; a span start is bounded; a hidden slot's view is let go.
- `file-finder`: the file finder shows paths safely; the grep reads are bounded by bytes.

## Impact

- Code: `carat/drivers/process_runner.rb`, `carat/plugins/finder/` (`grep.rb`, `plugin.rb`, new `safe_text.rb`), `carat/domain/syntax_line.rb`, `carat/domain/tab_list.rb`, `carat/use_cases/plugins/` (`window_requests.rb`, `plugin_syntax.rb`, `plugin_registry.rb`, `plugin_host.rb`, `ui_requests.rb`, `plugin_events.rb`, `plugin_router.rb`, `buffer_requests.rb`).
- Tests: `test/drivers_process_runner.rb`, `test/editor_finder.rb`, `test/editor_finder_grep.rb`, `test/editor_floats.rb`, `test/use_cases_plugin_syntax.rb`, `test/editor_plugins.rb`.
- Docs: `docs/codebase-map.md` (the new file and the changed entries), `docs/plugins.md`.
- README.md: unchanged, no user-visible feature or command changed.
- docs/architecture.md: unchanged, no layer, port, or rule changed.
- No edit of `tools/rules.sh`.
