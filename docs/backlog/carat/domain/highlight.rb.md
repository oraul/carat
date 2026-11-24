# Backlog: carat/domain/highlight.rb

## The cursor line doubles the highlight group-id space

- Where: `LIMIT = COUNT * 2` in `carat/domain/highlight.rb` (line 107 at `cursor-shapes`), which doubles every theme array and `SgrTable` entry with it. Quality advisory of `cursor-shapes`.
- Why it matters: a one-off layer: a second overlay such as ColorColumn or CursorColumn would have to multiply the space again.
- Fix outline: when the next overlay arrives, generalize to `id = base + layer * COUNT` with a layer count, or record the limit in the design.
- Merged: ### The cursor line doubles the highlight group-id space
- Location: `carat/domain/highlight.rb` (`CURSOR_LINE_LAYER`, `FLOAT_LAYER`, `LIMIT`), `carat/domain/themes.rb` (`from_palette`), `carat/adapters/sgr_table.rb` (`from_theme`), `carat/domain/frame.rb` (`lift`); split off from syntax-tidy.
- Why: every group id has a cursor-line and a float copy, so each theme array and the SGR table hold three times `COUNT` entries and each new layer multiplies the space again; no frame id reaches `LIMIT` today, so no test fails, and shrinking it is a design change of how frames carry layers.
- Fix: carry the layer in the frame as its own small number beside the group id (or resolve only the groups a layer can reach), building the layered SGR sequences on demand, and keep `test/domain_theme.rb` and `test/adapters_screen_presenter.rb` rows on the layered colors.
None
- Also: carat/domain/themes.rb, carat/adapters/sgr_table.rb, carat/domain/frame.rb, test/domain_theme.rb, test/adapters_screen_presenter.rb
- Category: editor
- Added: 2026-11-05

## StatusLineNC is themed but painted by nothing

- Where: `STATUS_NC` in `carat/domain/highlight.rb` (line 18 at 22a5de0), its color in `carat/domain/themes.rb` (line 87), and the message of `test/adapters_screen_presenter.rb` (line 181) saying inactive status lines take it. Periodic quality at 22a5de0.
- Why it matters: `bars` removed the per-window status line, so the group, its theme row, and the test message describe a row that no longer exists.
- Fix outline: keep it as a name-only Neovim group with a comment saying so and reword the test message, or drop the group, its theme row, and the test row.
- Also: carat/domain/themes.rb, test/adapters_screen_presenter.rb
- Category: editor
- Added: 2026-11-05

## Markup groups widen the plugin API without a version

- Where: `token?` and `token_id` in `carat/domain/highlight.rb` line 163, reached by `Host#syntax_group` (`carat/use_cases/plugins/ui_requests.rb` line 85) and plugin tokens (`carat/use_cases/plugins/plugin_syntax.rb` line 79), at 3895e21; `docs/plugins.md` lines 87 and 116 and `carat/plugin_api.rb` line 713 still say syntax or file-icon groups only. Periodic quality. Queue item `hover-tidy`.
- Why it matters: plugins can now name the six markup groups while `PluginApi::VERSION` stays 2.4 and the docs deny it, an undocumented widening.
- Fix outline: bound both below the first markup group, or document it with a minor bump to 2.5 and a `use_cases_plugin_syntax` row.
- Also: carat/use_cases/plugins/ui_requests.rb, carat/use_cases/plugins/plugin_syntax.rb, docs/plugins.md, carat/plugin_api.rb
- Category: editor
- Added: 2026-11-09

## Two comments rewrapped unevenly

- Where: `carat/domain/highlight.rb:3` (lines 6-7 and 12-13 stop at 37 to 50 columns) and `carat/use_cases/ex/set_command_handler.rb:17` (about 95 columns). Periodic quality advisories at d0d783c.
- Why it matters: comment blocks wrap at 72 columns elsewhere.
- Fix outline: rewrap both paragraphs. Queue item: backlog batches, comment wraps.
- Also: carat/use_cases/ex/set_command_handler.rb
- Category: editor
- Added: 2026-11-11

### MESSAGE_WARNING (WarningMsg) is themed (themes.rb:134) but painted by nothing, the at carat/domain/highlight.rb:41 (sprint-32 sweep quality, note 40)
- Location: carat/domain/highlight.rb:41
- Why: MESSAGE_WARNING (WarningMsg) is themed (themes.rb:134) but painted by nothing, the state that got MoreMsg removed in #336
- Fix: remove it with its theme row and docs, or paint it
- Category: quality
