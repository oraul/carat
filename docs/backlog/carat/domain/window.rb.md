# Backlog: carat/domain/window.rb

## Every window allocates a jump list, floats and splits included

- Where: `carat/domain/window.rb:39`; the float windows of the completion popup, hover, signature, key hints, and palette, built per show; the split's `Window.new` followed by `copy_from`. Quality advisory of `jump-list`.
- Why it matters: each window now allocates a `JumpList` and three arrays, so every float shown and every split allocates them, and a split builds them in `Window.new` and then dups them again in `copy_from`.
- Fix outline: check the figures with `make bench` and `make metrics-compare`; if they grow, give float windows no list of their own or copy the list in the split's constructor. Queue item `run-budgets-tidy`.
- Category: editor
- Added: 2026-11-10

## Window#winbar reads as the Winbar adapter rather than a flag

- Location: carat/domain/window.rb:23
- Source: quality advisory, winbar-outline
- Why: the bool member winbar reads as the Winbar adapter rather than a flag (Window#winbar beside FramePresenter#winbar, which is the adapter).
- Fix outline: name it after what it records, for example winbar_shown, in the record, ArrangeView, FramePresenter, the test, and the map.
- Category: editor
- Added: 2026-11-15
