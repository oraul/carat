### The bottom panel is not on the darker surface
- Location: `carat/adapters/frame_presenter.rb`, `paint_window` (the sidebar layer is chosen by `window.fixed_width`, which the bottom panel's window does not set)
- Why: `docs/design.md` section 1 lists the panels (row 0, sidebars, the bottom panel) as one surface level behind the status bar; the panel still draws on `Normal` with a separator row above it, so only the sidebars follow the Edges-by-background rule.
- Fix: give the panel window the sidebar layer (a `Window#fixed_height` test beside `fixed_width`), draw no row of `─` where the panel meets the editor unless `plain` or `basic_colors`, and extend the two screen-rendering scenarios.
none
