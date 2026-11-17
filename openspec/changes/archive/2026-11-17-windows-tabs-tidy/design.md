# Design

## Context

Four small fixes in the windows and scroll area and a comment rewrap. None changes a key's effect; the offset fix makes the plugin windows spec's bound hold at the integer minimum.

## Decisions

### The offset bound without abs

`offset_refusal(row, col)` keeps its order (the row first) and its message, testing `value < -OFFSET_MAX || value > OFFSET_MAX` through a private-in-spirit class predicate `outside?(value)`. Comparisons cannot overflow, where `abs` at the integer minimum has no positive result. The test table gains a row at the integer minimum, built as `-4_611_686_018_427_387_903 - 1` beside the existing near-maximum row.

### breaks_insert? as an overridden predicate

The base `ActionHandler` defines `breaks_insert?` returning false with `# @rbs skip`, and `ScrollHandler` overrides it returning true, the shape of `ExHandler#ranged?`. The alternative, a `breaks_insert:` keyword on the base constructor, would touch all 28 `super(kind:, repeat:)` calls for one handler that differs. The dispatcher reads `handler.breaks_insert?`; the call allocates nothing.

### One name per half-page target

`ScrollRequest` targets `:half_page_down` and `:half_page_up`, read by `ScrollWindow#call`, so the action name less its `scroll.` prefix is the target for every scroll action.

### The previous window never names the current one

`BufferList#close_window` reassigns `tab.current` to the first leaf of the window that took the closed one's space; when that is the previous window, `tab.previous` named the current one. The clear becomes `tab.previous = -1 if tab.previous == id || tab.previous == tab.current`. Leaf ids are stable (`Layout#collapse` moves the only child, never renumbers it), so after `CloseOtherWindows` closes every other leaf through `close_window`, `tab.previous` is -1 already and its own clear goes.

### The comment rewrap

A line is past its file's wrap when it is longer than every other comment line of the file within 80 columns. Each such line and the rest of its paragraph is refilled to that width, the lines above kept, so the diff stays at the paragraph's tail.

## Risks

- A plugin relying on a focused previous window equal to the current one after a close: `window_requests.rb:207` reads `previous?` only to choose a window to show a buffer in, which with previous equal to current was the current window anyway.
