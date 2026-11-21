# Design

## Context

`BufferList#tab_row?(tab_count)` returns `tab_count > 1 || file_count > 1`. `ArrangeView#call` reads it to reserve row 0 and `FramePresenter#call` reads it to paint the row; both must agree or a window is laid out under a row that is not painted.

## Decisions

### The rule stays in `BufferList#tab_row?`

The method gains a second argument, the option's value: 0 returns false, 2 returns true, 1 keeps today's expression. Both callers already hold `options`. Alternative: a method on `Options` taking the counts; rejected, since the counts live in the buffer list and tab list, and `tab_row?` stays the one place the rule is read.

### An integer option, not words

`showtabline` is Neovim's number, so it goes through `bounded(0, 2)` like `tabstop`, with named constants `SHOWTABLINE_NEVER`, `SHOWTABLINE_ONLY`, `SHOWTABLINE_ALWAYS`. The message is the existing `takes a number from 0 to 2`.

### Two defaults, as for `tabstop`

`Options.new` keeps 1 (the former rule) like its `tabstop` of 8 against the shipped 2; the shipped file says 2. The test configuration is the shipped defaults followed by `option.showtabline 1` (`FixedConfig.defaults`), so no existing frame gains a row, and `FixedConfig.shipped` is the defaults alone for the one test that proves the shipped 2.

### `:set` stays pending

`SetCommandHandler` handles no numeric option, so `showtabline` and `stal` join `PENDING` and answer `Not implemented`, never `E518`; set-options adds the real handling.
