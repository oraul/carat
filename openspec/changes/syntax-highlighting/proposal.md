# Proposal

## Why

Carat shows every buffer in one color, while `docs/architecture.md` names syntax highlighting as one of the IDE goals with Ruby as the first language. The user asked for syntax highlighting with Ruby first, the language part living in a plugin, and agreed the design: the engine is core and each language is a plugin. This change delivers roadmap item 8, `syntax-highlighting` (tokenizer interface, Ruby tokenizer, themes, color output), taken now at the user's request after the core-quality queue.

## What Changes

- Every buffer gets a filetype detected from its name, its extension, or a shebang on its first line (`ruby` for `.rb`, `.rake`, `.gemspec`, `.ru`, `Gemfile`, `Rakefile`, `config.ru`, and a `ruby` interpreter after `#!`), and a syntax name that follows the filetype.
- Highlight groups become a fixed table with Neovim's standard names (`Comment`, `Constant`, `String`, ... `Todo`, `Error`) beside the editor's own groups (`LineNr`, `StatusLine`, `Visual`, the tab line, the message, and a new `SignColumn`), each an integer id, so a frame stays three flat integer arrays.
- A syntax cache per buffer keeps the end-of-line state of every row tokenized so far and the tokens of the visible lines keyed by line identity. It is invalidated by the edits themselves, from the first changed row until a re-tokenized row ends in the state it had before; only the visible rows and the rows above them are ever tokenized, so opening a large file tokenizes one screen.
- The frame presenter paints each token's group into the frame's highlight array; the screen presenter writes the groups as SGR color sequences from a theme: truecolor when `COLORTERM` is `truecolor` or `24bit`, 256 colors otherwise, 16 colors when `TERM` names a 16-color terminal, read once by the terminal driver at start through a new `TerminalPort#colors`.
- Themes `carat-dark` (the default) and `carat-light` map every group, the editor's included, to a foreground, a background, and bold, italic, underline, and reverse; the `theme` key already in `config/default.json` selects one.
- **BREAKING** for plugin source: plugin API 1.3 adds a tenth `Manifest` member, `filetypes`, the filetypes a plugin tokenizes; `Plugin#tokenize(filetype, text, state, tokens)`, which appends (start column, length, group id) triples to an integer array and returns the end state as an integer; and `Host#syntax_group(name)`, which resolves a group name to its id once. A tokenizer call is guarded like every plugin call, and one that raises disables its plugin and leaves the buffer plain. Every manifest in the repository passes the new member.
- A built-in compiled plugin `ruby` in `carat/plugins/ruby/`, listed in `config/plugins.json` and enabled in `config/default.json`, tokenizes Ruby 4 source line by line with every multi-line construct (strings, interpolation nesting, percent literals, heredocs, regular expressions, `=begin` blocks, `__END__`) carried in an integer state whose encoding is documented.
- Ex commands `:sy[ntax] on`, `:syntax enable`, `:syntax off`, and a `:se[t]` limited to `filetype` (`ft`) and `syntax` (`syn`) with `=value`, `?`, and the bare name.
- `make bench` gains scenarios on a generated 10,000-line Ruby file with the ruby plugin, an open of 100,000 lines, `G` on 100,000 lines, and typing in a heredoc and a multi-line string, and reports the rows tokenized per key.
- Documentation: `docs/architecture.md` (entities, plugins, adapters, roadmap), `docs/plugins.md` (the tokenizer API), `docs/compatibility.md`, the README (a Syntax highlighting section), `CLAUDE.md` (Status, Layout), and `docs/backlog.md`.

## Capabilities

### New Capabilities

- `syntax-highlighting`: filetype detection, highlighting the visible rows of a buffer from the tokenizer its filetype names, incremental re-highlighting after edits and undo, plain text without a tokenizer or with `:syntax off`, and `:set filetype` and `:set syntax`.
- `color-themes`: the highlight groups, the shipped themes, the theme option, and the color depth of the output.
- `ruby-syntax`: what the built-in Ruby tokenizer highlights and how its state carries multi-line constructs.

### Modified Capabilities

- `plugin-host`: the API version becomes 1.3, and a plugin declares the filetypes it tokenizes, resolves group names, and is called per line, guarded.

## Impact

- Code: new `carat/domain/filetype.rb`, `color_depth.rb`, `theme.rb`, `themes.rb`, `syntax_line.rb`, `syntax_table.rb`, `syntax_cache.rb`; `highlight.rb` (the group table), `buffer.rb` (filetype, syntax, the cache moved by every splice), `options.rb` (`theme`, the syntax switch), `manifest_check.rb`; `carat/plugin_api.rb`; new `carat/use_cases/syntax/highlight_view.rb`, `carat/use_cases/plugins/plugin_syntax.rb`, `carat/use_cases/ex/syntax_command_handler.rb`, `set_command_handler.rb`; the plugin host, registry, entry, link, and UI requests; `carat/adapters/frame_presenter.rb`, `painted_rows.rb`, `screen_presenter.rb`, new `sgr_table.rb`, `editor_assembly.rb`; `carat/ports/terminal_port.rb`, `carat/drivers/ansi_terminal.rb`, `carat/doubles/fake_terminal.rb`; new `carat/plugins/ruby/`; `config/plugins.json`, `config/default.json` and the generated mirror and registry; `bench/keys.rb`, `bench/run.sh`.
- Tests: tokenizer table, syntax cache, filetype, theme and color output, editor highlighting, `:syntax off`, a raising tokenizer, the ex commands, the smoke test on a `.rb` file; the screen presenter snapshot changes because the editor groups now take their colors from the theme, and the version refusal tests move to 1.3.
- No new dependency. Roadmap item 8.

Assumptions recorded here:

- A plugin resolves group names to ids once, in `activate`, through `Host#syntax_group`; ids of groups it did not resolve, or out of the syntax range, are drawn as normal text.
- Token columns are code point columns, as every other column of the API, and the text a tokenizer receives is a copy the host reuses, valid during the call only.
- The syntax switch of `:syntax on` and `:syntax off` is global and starts on, as Neovim's default; it is not a configuration option yet (that arrives with `options-and-config`). `:set syntax=OFF` turns highlighting off for one buffer and `:set syntax=ON` goes back to its filetype.
- Following vim-ruby, constants and the names after `class` and `module` are `Type`, symbols and hash labels `Constant`, variables `Identifier`, and quotes are part of the `String` token; only `and`, `or`, and `not` are `Operator`.
- `Normal` keeps the terminal's own foreground and background in both themes, so a theme never paints the empty screen; `carat-light` is meant for a light terminal background.
- A tenth positional `Manifest` member breaks the source of plugins built against 1.2; all compiled plugins live in this repository and move with it, and no process plugin exists yet.

Out of scope, recorded in `docs/backlog.md`: highlight ranges and virtual text for plugins in general (the explorer's marked line), other languages, `:set` beyond `filetype` and `syntax`, `:setlocal`, user theme files (with `options-and-config`), `:colorscheme`, semantic highlighting from the language server, a heredoc or string nested more deeply than the state encodes, and `:syntax` subcommands other than `on`, `enable`, and `off`.
