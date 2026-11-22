refactor(rendering): paint floats and notifications in a float painter

## Summary

Moves the painting of the floats and the notification boxes out of the frame presenter into a `FloatPainter` collaborator, as the status bar, the winbar, and the tab bar were moved before, with no change to what is drawn. The presenter had grown to one class of about 1470 lines and 60 methods, and the floats are the next surface the planned window-surfaces work restyles, so it gets a painter of its own first.

---

## Changes

- Add `FloatPainter` in `carat/adapters/float_painter.rb`, which builds the float key and paints every float row, border, title, mark, and notification box, the float and notice methods and constants moved unchanged from the presenter.
- Add `LinePainter` in `carat/adapters/line_painter.rb`, holding the text cell and token painting a window row and a float row share, which the presenter's window path and the float painter each call explicitly.
- Change `FramePresenter` to take `float_painter:` in place of `notices:`, keep only the frame bookkeeping of the boxes, read the float key from the painter, and pass its plain flag on to it, shrinking the file to 1121 lines.
- Change `EditorAssembly` to build the float painter with the shared line cache and notifications, and the tests that build a presenter to build one too.
- Add `test/adapters_float_painter.rb` with its snapshot, painting a bordered float with a title, a notification, and a plain ASCII box through the float painter alone, and check in `test/adapters_assembly.rb` that it holds the one cache and the one notifications.
- Document the two new files and the moved methods in area 13 of `docs/codebase-map.md` and name `FloatPainter` in section 8.2 of `docs/architecture.md`.
- Record the plan's feature queue, this lane's metrics row, and the findings left open in `docs/findings/float-painter.md`.

---

## Testing

- Run the security review of the committed diff, passed with no high, medium, or low finding
- Run the check stages at the implementation head (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics), all pass with every existing frame snapshot unchanged
- Run the benchmark comparison against main's recorded figures, passed with no blocking difference
- Run the quality review of the diff, two findings: one fixed in the new test, one recorded
- Run make spec-validate after the archive, 56 passed and 0 failed

---

## Notes

This is a refactor with no behavior change, archived with `--skip-specs`; README.md is unchanged because it describes what the floats show, not which class paints them. The presenter's `forget_rows`, `compare_boxes`, and `covers?` still walk the float key by `FloatPainter::STRIDE`, so the key's layout is known in two classes; moving that bookkeeping is a design step of its own and is recorded in `docs/findings/float-painter.md`. The window path, the headers, the winbars, and the message row stay in the presenter.
