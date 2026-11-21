# Backlog: carat/plugin_api.rb

## The plugin API cannot read or set the visual selection

- Where: `Carat::PluginApi::Host` and `BufferView` in `carat/plugin_api.rb`, and the requests in `carat/use_cases/plugins/buffer_requests.rb`; `docs/architecture.md` section 9.1 lists reading the selection and setting one among the requests a plugin can make.
- Why it matters: the visual modes keep each window's selection (its anchor, the cursor, and the kind from the mode, plus the last selection for `gv`), but a plugin cannot see it, so a plugin action bound in a visual map (a formatter, a comment toggle, a finder seeded with the selected text) has no way to know what was selected. The `visual-modes` change left the API at 1.1, because the plugin API was outside its scope.
- Fix outline: add the selection to `BufferView` (kind, anchor row and column, cursor row and column, `""` kind outside visual mode) and a `set_selection(kind, from_row, from_col, to_row, to_col)` request validated like `move_cursor`, bump the minor of `PluginApi::VERSION`, and document both in `docs/plugins.md`.
- Also: carat/use_cases/plugins/buffer_requests.rb, docs/architecture.md, docs/plugins.md
- Category: plugins
- Added: 2026-10-31

## Plugins cannot highlight ranges or add virtual text

- Where: the plugin API in `carat/plugin_api.rb` and the frame presenter in `carat/adapters/frame_presenter.rb`; `syntax-highlighting` gave plugins tokenizers for whole filetypes and `Host#syntax_group`, but no request to color an arbitrary range of a buffer or to show text that is not in it.
- Why it matters: the explorer's marked line, search matches from a finder, diagnostics underlines, and git blame all need a range highlight or virtual text that is not part of the language's tokens; section 9.1 of `docs/architecture.md` lists them.
- Fix outline: add `add_highlight(buffer, row, from_col, to_col, group)` and `clear_highlights(buffer)` per plugin, kept in a per-buffer layer moved by the splice like the sign layers, and painted by the frame presenter after the tokens; a virtual text layer of the same shape after it; bump the API minor.
- Also: carat/adapters/frame_presenter.rb, docs/architecture.md
- Category: plugins
- Added: 2026-11-03

## Two open_scratch comments are not rewrapped

- Where: the `open_scratch` comments in `carat/plugin_api.rb` line 480 (111 characters) and `carat/use_cases/plugins/window_requests.rb` line 69, at edaf2c2. Quality advisory in `layout-slots`.
- Why it matters: they break their files' wrap width.
- Fix outline: rewrap both at the file's width.
- Also: carat/use_cases/plugins/window_requests.rb
- Category: plugins
- Added: 2026-11-09

## No test pins the port bases that answer failure values

- Where: `Host#stat` (`carat/plugin_api.rb:622`), `Host#icon` (`carat/plugin_api.rb:630`), and `FilePort#stat` (`carat/ports/file_port.rb:45`), changed by `spinel-bump` from raising to answering a missing or failed value as the f34005bf workaround. Quality advisory at spinel-bump.
- Why it matters: nothing asserts the new base answers, so the workaround is invisible to a reader of the tests and could be reverted, or kept past the fix, by accident.
- Fix outline: add an assertion that a bare base answers missing or failed (or a lint exemption list naming the three methods), removed deliberately in the bump that clears the f34005bf entry.
- Also: carat/ports/file_port.rb
- Category: plugins
- Added: 2026-11-10

## Docs drift at #96

- Where: `carat/plugin_api.rb:448` (Host comment says every method raises, stale since `stat` and `icon` answer values); `docs/codebase-map.md:89`, `:93`, `:197` omit `Config#count`, three `RcParser` helpers, and `LastSearch#touch`; CLAUDE.md and `docs/codebase-map.md:649` state the override rule without the `-> void` exception `docs/spinel-notes.md:39` allows.
- Why it matters: readers and agents follow stale rules and an incomplete map.
- Fix outline: correct the comment, add the names, state the exception. Queue item `docs-index`.
- Also: docs/codebase-map.md, CLAUDE.md, docs/spinel-notes.md
- Category: plugins
- Added: 2026-11-10

### The plugin API file mixes four concerns (architecture-review M3)

Location: `carat/plugin_api.rb` (888 lines): request and response values, the `Host` and `Plugin` bases, `Paths`, and `FileIcons`. Why: it is the one file a plugin author reads, and the API reference is buried among path functions and an icon table. Fix outline: keep `carat/plugin_api.rb` as the one file a plugin requires, requiring one file per concern from a `plugin_api` directory beside it (values, host, plugin, paths, file icons), and widen the lint's plugin rule to that directory.
- Category: plugins
- Added: 2026-11-15

### PluginApi::FileIcons.group_of has no caller
- Location: carat/plugin_api.rb:478; carat/plugins/explorer/file_icons.rb:12, plugin.rb:451-455
- Why: the explorer reads GROUPS through its own alias while the map calls group_of shared. Folded into architecture-docs.
- Fix: have Explorer#icon_groups call group_of and drop the alias, or remove group_of.
- Also: carat/plugins/explorer/file_icons.rb
- Category: plugins
- Added: 2026-11-17

### Command#args? and Edit#insertion? have no caller
- Location: carat/plugin_api.rb:125, :142
- Why: no plugin, host code, or test calls them. Folded into architecture-docs.
- Fix: cover them in test/use_cases_plugins.rb as API, or remove them with a minor version note.
- Also: test/use_cases_plugins.rb
- Category: plugins
- Added: 2026-11-17
