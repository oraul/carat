## Context

Carat draws one buffer line per window row, and `Motions.vertical`, `Window#scroll_to_row`, `FramePresenter#paint_window`, and its cursor placement all assume it. Neovim keeps manual folds per window and adjusts them on every line change (`foldMarkAdjust`), and its `j`, `k`, operators, and drawing treat a closed fold as one line.

## Goals / Non-Goals

**Goals:** manual folds per window with `zf`, `zo`, `zc`, `za`, `zd`, `zE`; a closed fold drawn as one row; `j` and `k` and linewise operators treating it as one line; folds following the buffer's edits; no added allocation or round on the `lh` and `j` benches.

**Non-Goals:** part b's keys and commands; other fold methods, fold options, and the `Folded` group; the screen motions and scroll keys counting folds.

## Decisions

- `Domain::Folds`, a Struct record held by each `Window`, keeps the folds as three parallel arrays (`starts`, `ends`, `closed`) sorted by start and, at one start, the outer fold first, so a walk meets the folds containing a row from the outermost in. Nesting is containment; a new fold crossing another grows until it contains it, so the folds always nest. The closed region at a row is the first closed fold containing it. Parallel integer and bool arrays keep the per-row lookups allocation-free, and an empty record costs one length check on the hot paths.
- The edits reach the folds through the buffer: `Buffer#splice`, the one place the line array changes, calls `Folds#shift` for each fold record in its `fold_lists`. A record joins its buffer's list when it gains its first fold and leaves it when it loses its last or the window shows another buffer, so a buffer without folds pays one empty loop. The shift treats the first `min(removed, inserted)` lines as changed in place, then deletes or inserts the rest, so typing on a fold's first line leaves the fold where it is, a line opened inside it extends it, and deleting all its lines removes it. The alternative, a hook in every use case that edits, would miss plugin and undo edits.
- `zf{motion}` is a pending operator (`OperatorKind::FOLD`, `fold.create`) carried out by `Operate`, which already resolves motions, text objects, and searches into a range; its other keys and the visual `zf` are `ChangeFolds` targets behind one `FoldHandler`, whose kind is `:operator` for `fold.create` and `:action` for the rest, and which never repeats with `.`.
- `Operate` widens a linewise range to the closed folds at its two ends, and the doubled operator counts a closed fold as one line, as Neovim's `do_pending_operator` does with `hasFolding`.
- The presenter walks buffer rows apart from screen rows only in a window with a closed fold; the scroll-copy optimization and the indent guides are off in such a window, whose rows no longer map one to one. The fold text is built once per fold and width and kept in the record until the next shift or fold change, so a redraw allocates nothing new.
- `Window#scroll_to_row` and the cursor placement count screen rows through `Folds` when the window has a closed fold and keep their old arithmetic otherwise.

## Risks / Trade-offs

- A closed window's fold record stays in its buffer's list until the buffer drops it; the shift of an unseen record is cheap and correct, so this is a small leak, not a fault.
- `H`, `M`, `L`, the scroll keys, and relative numbers still count buffer lines in a folded window; part b or a follow-up fixes them.
