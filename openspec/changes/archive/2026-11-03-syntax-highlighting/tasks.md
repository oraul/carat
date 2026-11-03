# Tasks

## 1. Domain: groups, filetypes, themes, color depth

- [x] 1.1 Extend `carat/domain/highlight.rb` with `SIGN_COLUMN`, the thirty syntax groups from `SYNTAX_FIRST`, `NAMES`, `COUNT`, `syntax_id(name)`, and `syntax?(id)`, and use `SIGN_COLUMN` for the sign column in `carat/adapters/frame_presenter.rb`; verify the table in `test/domain_theme.rb` and the sign column in `test/adapters_frame_presenter.rb`
- [x] 1.2 Add `carat/domain/filetype.rb` (`Filetype.detect(path, first_line)`: extensions, names, shebang) and verify every row of the table in `test/domain_filetype.rb`
- [x] 1.3 Add `carat/domain/theme.rb` and `carat/domain/themes.rb` (`carat-dark`, `carat-light`, `find`, `known?`) and `carat/domain/color_depth.rb` (`detect(colorterm, term)`); verify in `test/domain_theme.rb`
- [x] 1.4 Add `theme` and `syntax_on` to `carat/domain/options.rb`, `theme` read from the top-level configuration key; verify in `test/domain_theme.rb`

## 2. Domain: the syntax cache on the buffer

- [x] 2.1 Add `carat/domain/syntax_line.rb`, `carat/domain/syntax_table.rb`, and `carat/domain/syntax_cache.rb` (`prepare`, `drop`, `start_of`, `find`, `store`, `advance` with the settle rule, `shift`, `lookup`) and verify identity hits, generations, invalidation from a change until the state settles, deletions, and truncation at the frontier in `test/domain_syntax_cache.rb`
- [x] 2.2 Give `carat/domain/buffer.rb` `filetype`, `syntax`, and `syntax_cache`, detected in `initialize` and `rename`, with every splice and `revert_to` shifting the cache; verify in `test/domain_syntax_cache.rb` (undo re-invalidates the restored rows) and keep `test/domain_buffer.rb` and `test/domain_edits.rb` green

## 3. Plugin API 1.3 and the host

- [x] 3.1 Bump `carat/plugin_api.rb` to 1.3: `Manifest#filetypes`, `Plugin#tokenize`, `Host#syntax_group`; pass the new member in every manifest of `carat/plugins/` and `test/`; check filetypes in `carat/domain/manifest_check.rb`; verify with `test/domain_plugin_manifest.rb` and the version tests of `test/use_cases_plugins.rb`
- [x] 3.2 Add `filetypes` to `carat/use_cases/plugins/plugin_entry.rb`, `syntax_group` to `ui_requests.rb` and `plugin_link.rb`, and `carat/use_cases/plugins/plugin_syntax.rb` (provider lookup, the guarded tokenize with a reused text and token array, validated token copies) with a reader on `PluginHost`; verify the request, the validation, the first-registered rule, and a missing tokenizer in `test/use_cases_plugin_syntax.rb` and a raising one in `test/editor_syntax.rb`; `test/lint.rb` stays green (PluginLink coverage)

## 4. Highlighting the view

- [x] 4.1 Add `carat/use_cases/syntax/highlight_view.rb` and run it in `EditorAssembly#render` after `ArrangeView`; verify that opening 100,000 lines tokenizes one screen, `G` twice tokenizes once, and typing in a heredoc or a multi-line string tokenizes one row in `test/editor_syntax.rb`, and the shared instances in `test/adapters_assembly.rb`
- [x] 4.2 Paint tokens in `carat/adapters/frame_presenter.rb` and record the painted `SyntaxLine` in `painted_rows.rb`; verify the highlight array of a Ruby buffer, a selection over it, repaint after an opened string, and undo in `test/editor_syntax.rb`
- [x] 4.3 Add `carat/use_cases/ex/syntax_command_handler.rb` and `set_command_handler.rb`, registered in `editor_assembly.rb`; add their rows to `docs/compatibility.md`; verify every spelling in `test/use_cases_ex.rb` and `:syntax off`, `:set ft=ruby`, `:set syntax=OFF` in `test/editor_syntax.rb`

## 5. Colors

- [x] 5.1 Add `TerminalPort#colors`, the `AnsiTerminal` environment read, the `FakeTerminal` value, and the benchmark terminal's; verify with `make build`, the depth table in `test/domain_theme.rb`, and the colored session of `test/smoke_editor.rb`
- [x] 5.2 Add `carat/adapters/sgr_table.rb` and build `ScreenPresenter` with the theme and depth; verify truecolor, 256, and 16-color output and the status line colors in `test/adapters_screen_presenter.rb` and review its snapshot diff

## 6. The ruby plugin

- [x] 6.1 Add `carat/plugins/ruby/` (`plugin.rb`, `tokenizer.rb`, `line_state.rb`, `keywords.rb`) with comments, `=begin`, `__END__`, Todo, keywords, definitions, names, numbers, symbols, labels, characters, strings with escapes and nested interpolation, percent literals, heredocs, regular expressions versus division, and the state encoding; verify every construct and end state in `test/plugins_ruby.rb`
- [x] 6.2 List the plugin in `config/plugins.json` and `config/default.json`, run `make gen-config`, and verify `test/config_sync.rb`; verify in `test/editor_syntax.rb` that the shipped registry highlights `a.rb` and that disabling the plugin in the configuration leaves it plain
- [x] 6.3 Open a `.rb` file in `test/smoke_editor.rb` and check that the output carries color sequences

## 7. Benchmark and documentation

- [x] 7.1 Add the Ruby scenarios, the plugin choice, the open time, and the rows tokenized per key to `bench/keys.rb` and `bench/run.sh`; run `make bench` for the Ruby and plain scenarios and record the numbers against the targets
- [x] 7.2 Document the tokenizer API in `docs/plugins.md`, the design in `docs/architecture.md`, the section in the README, the status and layout in `CLAUDE.md`, and the items left out in `docs/backlog.md`; verify the action table test still matches `docs/actions.md`
- [x] 7.3 Run `make check` and `make bench-budget`; both pass (after merging main: `make check` 110 s with 56 of 56 tests, the runner at 2 re-narrowing rounds, and `spinel-doctor` clean on every root; `make bench-budget` 27 allocations per key for `lh`, under 100)

## Workflow follow-up

- Run the security review on the committed branch diff, archive the change with its specs, open the pull request, wait for CI, and squash-merge.
