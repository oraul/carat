# Backlog: carat/domain/layout.rb

## A refused panel still regroups the root row

- Where: `panel_target` in `carat/domain/layout.rb` line 385 at edaf2c2. Quality advisory in `layout-slots`.
- Why it matters: the root row's middle children are grouped into a new row before `attach` checks the room, so a panel refused with E36 still leaves the layout restructured with a nested row.
- Fix outline: check the content's height against the size plus its minimum before grouping, or group only once `attach` would succeed.
- Category: editor
- Added: 2026-11-09

## Layout#fixed_width? has no production caller

- Where: `carat/domain/layout.rb` line 297, called only by `test/domain_layout.rb` line 265 and named in `docs/codebase-map.md`, at edaf2c2. Quality advisory in `layout-slots`, raised twice. Raised again at ce6abdb (line 299; periodic quality), queue item `slots-tidy`.
- Why it matters: close, equalize, and fit use `fixed?`, so the wrapper of `fixed?(id, true)` is dead code kept alive by its test.
- Fix outline: drop it, test `fixed?(id, true)` instead, and update the layout line of the map.
- Also: test/domain_layout.rb, docs/codebase-map.md
- Category: editor
- Added: 2026-11-09

## Layout's split and attach copy the inner-split block

- Where: `carat/domain/layout.rb` lines 153 to 168 (`split`) and 351 to 368 (`attach`), at 7711421. Periodic quality. Queue item `top-rows`.
- Why it matters: allocating the split, copying size and rectangle, replacing the target, and reparenting are written twice.
- Fix outline: one private helper returning the inner id, called by both.
- Category: editor
- Added: 2026-11-09

## The left and right window keys ignore the gutter and display columns

- Where: `neighbour` in `carat/domain/layout.rb` line 250 takes the cursor column as `window.col + cursor.col - window.left`. Periodic quality at e49f63d.
- Why it matters: it mixes a code point index with the display-column scroll and leaves out the gutter, so `<C-w>j` and `<C-w>k` beside vertical splits pick the wrong window with numbers, signs, tabs, or wide characters, unlike Neovim.
- Fix outline: pass the gutter width and the cursor's display column into the neighbour search, with a row over a numbered window. Queue item: `slots-tidy`.
- Category: editor
- Added: 2026-11-10

### Layout#close frees a window without untracking its folds
- Location: carat/domain/layout.rb:229
- Why: performance; every later edit of the buffer shifts the dead fold record of the closed window (the design accepts the leak).
- Fix: drop the window's folds where a window is closed, as Window#show does.
- Category: editor
- Added: 2026-11-17
