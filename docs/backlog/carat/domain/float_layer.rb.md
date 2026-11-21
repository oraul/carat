# Backlog: carat/domain/float_layer.rb

## FloatLayer is a plain class among the mutable records

- Where: `carat/domain/float_layer.rb` line 10 at 803fe6e. Periodic quality advisory.
- Why it matters: `CLAUDE.md` makes mutable records `Struct` subclasses with pinned members; `TabPage`, `TabList`, `LastFind`, and `StatusSlots` follow it, `FloatLayer` does not.
- Fix outline: a `Struct` with `floats` and `focus` pinned, readers and `self.member =` writers, built with keywords in `TabPage`. Queued in `float-placement`.
- Also: CLAUDE.md
- Category: editor
- Added: 2026-11-07

### FloatLayer#close drops a float without dropping its folds. A zf in a (sprint-20 sweep quality, float_layer.rb:76)

- Location: `carat/domain/float_layer.rb:76`
- Why: FloatLayer#close drops a float without dropping its folds. A zf in a focused float (Operate#fold goes through state.window, which is the focused float) leaves a fold list the buffer keeps tracking and shifting after :q, float.close, or :tabclose. This breaks the windows spec rule that closing a window drops its folds
- Fix: call window.drop_folds on the float's window before delete_at in close (BufferList#close_tab should do the same for the page's floats), and add an editor_folds row that runs zf in a float, closes it, and expects fold_lists to be empty
- Category: editor
- Added: 2026-11-19
