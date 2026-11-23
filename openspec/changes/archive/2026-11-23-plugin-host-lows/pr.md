fix(plugins): bound program lookup, grep reads, paths, and spans

## Summary

Bounds four plugin-host and finder weaknesses reachable from an untrusted repository: a program run through the host, the grep picker's reads, paths shown by the file finder, and span starts of floats and syntax tokens. Each is a Low security finding, and a hidden slot kept a disabled plugin's view alive, so the change also lets that view go and tidies the plugin host files it touches.

---

## Changes

- Change the process runner so a program is resolved only against the absolute directories of PATH, an executable regular file, and started by its absolute path, so a project's own git or ruby-lsp no longer runs from a relative or empty PATH entry.
- Change the grep picker to stop reading once the files read hold 16 MiB, marking the store as cut as the line cap does.
- Add Finder::SafeText as the one sanitizer, moved out of Grep, and use it for the file finder's rows and preview title so a listed path with U+202E no longer reorders the text.
- Change style_float and PluginSyntax copied_tokens to refuse or drop a span starting past SyntaxLine::LONGEST_SPAN and to cut a length to it, moving the constant to Domain::SyntaxLine.
- Fix a hidden slot keeping a plugin's view by adding TabList drop_kept, called when a disabled plugin's buffer is removed and by close_scratch when no leaf shows the view.
- Refactor the locals named e in the plugin host files and make PluginRegistry option_value the one option lookup of PluginHost and UiRequests.
- Add tests for each security heading and the view release in the process runner, finder, grep, floats, plugin syntax, and plugin tests, with delta specs for plugin-host and file-finder.
- Document the change in docs/plugins.md and docs/codebase-map.md and record the findings left open in the findings file.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low findings
- Run the fast check stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics) at the implementation commit, all pass
- Run the benchmark review against main's recorded figures, pass with no blocking finding
- Run make spec-validate after the archive, all 56 items pass

---

## Notes

The plugin_router.rb on_action guard and manifest_check.rb shapes entries are named only by location in the brief and are recorded in the findings file, not changed. The grep reads stay synchronous on the editor thread, now bounded by the byte budget, and streaming them is recorded as a follow-up. tools/rules.sh is not edited.
