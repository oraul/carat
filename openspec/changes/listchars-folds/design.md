# Design

## Context

See proposal.md, Why. A file row is painted by `FramePresenter#paint_row`: `paint_text` puts the decoded line's code points in `Normal` and blanks every other cell, a tab's cells included; then the syntax tokens, the indent guides (`IndentGuides`), the search matches, the pair, and the selection regroup or overwrite cells. A row segment is repainted only when its record differs; settings that change every row (the tabstop, the guides' stamp) sit in the frame's geometry key, whose change invalidates every record. `Options` holds the typed options read from `option.*` lines.

## Goals / Non-Goals

**Goals:**
- The marks cost nothing with `option.list` off (the default): one boolean test per row, so `lh` and `j` keep their allocations and rounds.
- No allocation per row with the marks on: the mark code points are read once per frame into integers.

**Non-Goals:**
- The closed fold's `Folded` look (queued as `folded-row`), the other `listchars` keys, window-local `list`, and `:set list`.

## Decisions

- An adapter of its own, `WhitespaceMarks`, beside `IndentGuides`: `configure(options)` reads the five mark code points (tab first, middle, last; trail; nbsp) through `Options#listchar_code`, the ascii form applied there, and returns a stamp for the geometry key, 0 when off; `paint` walks the decoded line once. Folding the code into `FramePresenter` was the alternative; it would grow the largest adapter and mix a second walk into `paint_text`, whose plain path is the hot one.
- The stamp is a serial bumped when any code point changes, not a product of the code points: five 21-bit values do not fit one integer, and a hash could collide and keep a stale row.
- The marks overwrite cells after `paint_tokens` and before the guides, so a guide keeps its cell, and the matches and the selection, which regroup cells without changing their characters, color a mark as they color text.
- `Options#listchar_code(key, slot)` reads the `listchars` string at configure time (once a frame), keeping `listchars` a plain string member as Neovim shows it; `Options.listchars?` checks a value with the same per-character rule as the guide character (`guide_char?`: one column, not a control). A later item of a key wins, found by scanning to the last one.
- `Whitespace` takes the `GUIDE` role in `Themes::GROUPS` instead of `FAINT`: the group had no user, Neovim draws `listchars` in it, and the user decided the guides' tone; the theme test treats it as a guide group in the receding palettes.
- Plugin windows (`buffer.scratch?`) and closed fold rows are skipped, as the guides skip them: a fold row's text is the fold label, not the buffer's characters.

## Risks / Trade-offs

- [`→` and `·` are East Asian ambiguous width, two cells in some CJK terminals] → `DisplayWidth` counts them as one, as it does for the shipped `┊`; `option.icons ascii` or a custom `listchars` avoids them.
- [The middle mark of the shipped tab is a blank, so a tab shows one mark] → it is Neovim's own default shape; `tab:→-` or a third character shows the full width.
