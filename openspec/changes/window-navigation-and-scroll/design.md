# Design

## Context

See proposal.md for the report and the reproduction. The key path at e375e4c: `InputController#handle` feeds each decoded key to `HandleKey#call`; a key that leaves the pending keys a prefix returns `:pending`, and the controller sets a deadline of `timeoutlen` from now. When a read returns nothing after the deadline, the controller sends `Key::TIMEOUT`, and `HandleKey#timeout` dispatches the pending keys' own binding when there is one, or else cancels the grammar and drops them (inserting them as text in insert and command-line modes). `<C-w>` is a pure prefix in the normal keymap, so a pause of more than 500 ms (the shipped `timeoutlen`) between `<C-w>` and `l` drops the `<C-w>`, and `l` then runs alone. In the tree, `l` and `h` are the tree's own open and collapse keys, which is why the user could not leave the tree. The window focus use case, the layout neighbours, and the tree's keymap fall-through are correct; the existing rows of `test/editor_windows.rb` and `test/editor_explorer.rb` pass because the harness types keys with no clock time between them.

Scrolling: a window's first shown line is `Window#top`, its text rows `Window#height`, both set before every key by `ArrangeView`, which also scrolls each window to its cursor with `scrolloff` through `Window#scroll_to_row`, clamping `top` to `0..line_count - height`. Nothing else moves `top`.

## Goals / Non-Goals

**Goals:**

- A lone prefix in a grammar mode waits for its next key with no deadline; nothing else about the wait changes.
- The scroll commands of the scrolling spec, as one use case with variants, with no allocation per key beyond what a window command already costs.

**Non-Goals:**

- Scrolling past the end of the buffer, horizontal scrolling, and `<C-w>` in other modes (proposal, out of scope).

## Decisions

### HandleKey decides whether a pending prefix has a deadline

`HandleKey#step` returns a new result, `:waiting`, when the pending keys are a pure prefix (`KeymapMatch` kind `:prefix`) and the mode is a grammar mode; `:pending` stays for `:match_prefix` in any mode and for `:prefix` in insert and command-line modes. `InputController#handle` sets the deadline on `:pending` and clears it on `:waiting` (a `bool` instance variable, `@deadline`); `pump` sends `Key::TIMEOUT` only when a deadline is set and passed, and `next_timeout` returns the idle timeout while waiting without one, so the loop keeps polling for signals.

The use case decides because it knows the mode and the match kind; the controller only keeps the clock. Alternatives: give `TIMEOUT` handling the choice (the controller would then send `TIMEOUT` every poll and `HandleKey#timeout` would keep the keys, a busy loop at a 0 s select timeout); mark built-in bindings as non-timing in the keymap (the configuration format has no such flag, and a user mapping that is a pure prefix is better served by waiting than by being dropped after a delay, which is exactly the reported bug).

### One ScrollWindow use case with a ScrollRequest

`UseCases::ScrollWindow#call(state, request)` with `ScrollRequest < Data.define(:target, :count)` (`:page_down`, `:page_up`, `:half_down`, `:half_up`, `:line_down`, `:line_up`, `:cursor_top`, `:cursor_middle`, `:cursor_bottom`), as `FocusWindow` takes a `FocusRequest` (architecture section 5, variants through one `call`). `ScrollHandler` (kind `:action`, so the grammar completes it at once with its count, in normal and visual modes alike; in insert mode it is dispatched as a plain command) registers the nine `scroll.*` names, each with its variant, and calls the use case. The use case lives in `use_cases/windows/` beside `FocusWindow`, map area 11.

The use case computes a new `top`, clamped to `0..max(0, line_count - height)` as `scroll_to_row` clamps, then moves the cursor row into the rows the window shows, honoring `scrolloff` capped at `(height - 1) / 2`, with no lower margin while `top` is 0 and no upper margin while `top` is the last possible top, which is exactly the range in which `ArrangeView`'s `scroll_to_row` leaves `top` alone, so the arrangement after the key keeps the view the command chose. The column comes from the wanted column through `Motions.wanted_col`, so the visual and insert modes get their own end-of-line rule and `want_col` survives. Before the first render (`height` 0) every scroll command does nothing.

Per variant, with `h` the text rows: page, `top += count * max(1, h - 2)` (or minus), then the cursor is kept in view; `<C-f>` with `top` already at its maximum moves the cursor to the last line. Half page, `amount = scroll > 0 ? scroll : h / 2`, a count first setting `options.scroll`; `top` and the cursor row move by `amount`, clamped. Line, `top += count` (or minus), cursor kept in view. `zt`, `zz`, `zb`, a count first moving the cursor to that line, then `top = row - off`, `row - (h - 1) / 2`, or `row - h + 1 + off`, clamped.

Alternatives: methods on `Window` (the record would need the options and the mode-dependent column rule, which live in the state and `Motions`); one use case per command (nine files for one clamp-and-keep rule).

### The scroll option

`Options` gains a pinned `scroll` member (default 0), `KINDS` a `"scroll" => "integer"` entry, and `apply` its branch; `config/default.caratrc` gains `option.scroll 0` and the mirror is regenerated. `:set` lists `scroll` and `scr` with the options it does not handle yet.

### Bindings

`keymap.normal`, `keymap.visual`, `keymap.visual_line`, and `keymap.visual_block` bind `<C-f> <PageDown> <C-b> <PageUp> <C-d> <C-u> <C-e> <C-y> zt zz zb`; `keymap.insert` binds `<PageDown>` and `<PageUp>`. Operator-pending mode binds none: none of these is a motion in Neovim. Insert-mode `<C-e>` and `<C-y>` are Neovim's insert-the-character-below and -above commands, not scrolls, so they stay unbound there.

## Risks / Trade-offs

- [A user mapping in normal mode that is a pure prefix, such as `<leader>a` with nothing on `<leader>` alone, now waits instead of being dropped after `timeoutlen`] → Escape or any other key drops it, as in Neovim's built-in commands; the shorter-binding timeout of `:match_prefix` is unchanged.
- [`z` becomes a prefix, so `3zl` drops both keys where it moved the cursor before] → Neovim's `zl` is a scroll, not `l`; the tests' unbound key moves to `Q`.
- [Visual-mode scrolling moves the cursor end of the selection] → that is Neovim's behavior.
- [Allocations per key] → the use case creates no objects but the request; `bench-budget` and the `metrics` stage check it.
