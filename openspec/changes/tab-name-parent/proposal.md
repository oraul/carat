# Proposal

## Why

Two open files with one name, such as `a/x.rb` and `b/x.rb`, show two identical tabs, so the row cannot tell them apart. Neighbouring tabs also stand three blank cells apart, where the buffer-tabs design calls for two: a tab writes a trailing space after its mark, and the next tab writes two leading spaces. `Buffer#icon` is set on every path change and read by nothing since the tabs lost their icons.

## What Changes

- `TabBar` writes the folder holding the file, with its slash, before the name of a tab while another listed file tab has the same last segment: dim (`MsgDim` on the selected tab, `TabLine` on the others, the tab's own group under 16 colors and NO_COLOR), the name in the tab's group as before. `tab_width` counts those cells, so the overflow counts and the shown run stay right.
- A tab drops its trailing space: `FRAME_CELLS` is 3, so two tabs stand two blank cells apart after the mark.
- `Buffer#parent_start` names the byte where the folder starts, beside `name_start`, so the tab bar allocates nothing for it.
- Remove the `icon` member of `Buffer`, `Buffer.icon_of`, and their two writes; nothing read them.
- Extra, named: the `buffer-tabs` spec Purpose still said the tabs list the buffers "with their icons"; it now says "modified marks". The explorer is the one reader of `PluginApi::FileIcons`, so its comment and the code map no longer name the buffer tabs.

Out of scope: a stale scenario text of the `buffer-tabs` spec (the first-tab scenarios under `option.showtabline 2` still read a `•` before the name) is recorded in the findings file, not fixed here.

Roadmap: outside `docs/architecture.md` section 12 (a refinement of the delivered buffer tabs, queued in `docs/queue-feature.md`).

Assumptions: "share it" means another listed file tab with the same last segment, compared by bytes; an unlisted or scratch buffer has no tab and shares nothing. Only the last folder shows (`a/x.rb`, not `src/a/x.rb`); a file in the root shows `/`, and a file with no folder shows none. A tab's trailing blank is removed, not the mark's cell, so the mark keeps its one cell modified or not; the overflow counts " N> " then follow the last tab after one blank beside the mark.

## Capabilities

### New Capabilities

### Modified Capabilities
- `buffer-tabs`: the tab's cells, and the folder before a shared name.

## Impact

- Code: `carat/adapters/tab_bar.rb`, `carat/domain/buffer.rb`, a comment in `carat/plugin_api.rb`.
- Tests: `test/adapters_tab_bar.rb`, `test/domain_buffer.rb`, and the tab-row strings of `test/adapters_definitions.rb`, `test/adapters_frame_presenter.rb`, `test/editor_tabs.rb`, with the snapshots.
- Docs: README.md (the buffer tabs sentence), `docs/codebase-map.md` (the buffer, tab bar, and plugin API lines).
- docs/architecture.md: unchanged, it names the tab bar as a part and describes no tab layout.
