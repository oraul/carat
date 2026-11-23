# Proposal

## Why

`docs/design.md` says the active tab takes the editor's background and carries no type icon, the tab-page numbers are bold or dim with no fill, and the focused winbar name is bright, not filled. Today a sapphire fill marks the current tab, the current tab-page number, the focused window's winbar name, and the shown view of a sidebar or panel header, and every tab carries a file icon, so four surfaces compete for the one accent.

## What Changes

- Draw `TabLineSel` as the palette's text on its background, bold, at every depth: the selected buffer tab is the editor's own background in bold, no accent fill.
- Add the group `TabLineName` (id 69, the syntax groups move up one): bold text on the tab row's own background (a new color role, `TAB_NAME`, each palette's text color and black at 16 colors), no accent fill. The winbar name of the current window, the current tab-page number, and the shown view of a slot header use it; the other page numbers and view names stay in `TabLine`.
- Remove the file icon and the space after it from each tab: a tab is two spaces, the name, a space, the one-cell modified mark, and a space.
- Under 16 colors and NO_COLOR the tab row has no fill: the selected tab and the current page number stay bold, every other name and count is in `Normal`.
- Document in `docs/compatibility.md` that `gt` moves between buffer tabs and the tab pages are the numbers at the right.

Assumptions: "no-fill" is read as no accent fill, so `TabLineName` keeps the bar's own panel background (an unpainted cell would show the terminal's background inside the bar); its text is a role of its own because the editor's text color does not read on the basic light gray of that background at 16 colors, and the panel's text color does not in `light_plus`. NO_COLOR keeps the terminal colors elsewhere, so it takes the 16-color row here only through the new `TabBar#bare=`, set from `FramePresenter#plain=` and `#basic_colors=`. The winbar and header rows keep their `TabLineFill` bar at every depth. The `Highlight` constants for syntax, icon, and markup groups move up by one, which no test or document names by number but `test/domain_theme.rb`. The requirement "The editor's own highlights are groups too" of `color-themes` already lists a stale count of groups and is left alone; the new group is recorded in the findings file.

## Capabilities

### New Capabilities

### Modified Capabilities
- `buffer-tabs`: a tab has no icon, the selected tab and current page number are bold, no accent fill, plain at 16 colors and NO_COLOR.
- `color-themes`: the selected tab is bold in Normal's colors, `TabLineName` is bold.
- `breadcrumbs`: the current window's winbar name is bold in `TabLineName`.

## Impact

- Code: `carat/domain/highlight.rb`, `carat/domain/themes.rb`, `carat/adapters/tab_bar.rb`, `carat/adapters/winbar.rb`, `carat/adapters/frame_presenter.rb`.
- Tests: `test/adapters_tab_bar.rb`, `test/adapters_screen_presenter.rb`, `test/adapters_frame_presenter.rb`, `test/editor_tabs.rb`, `test/editor_breadcrumbs.rb`, `test/editor_plugins.rb`, `test/editor_slots.rb`, `test/domain_theme.rb` and their snapshots.
- Docs: `docs/compatibility.md`, `docs/codebase-map.md`, `docs/design.md` (the closed drift rows).
- README.md: unchanged, it names no tab icon, accent fill, or tab group.
- docs/architecture.md: unchanged, it names no tab group or tab layout.
