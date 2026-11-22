# Design

## Context

The float layer of `FramePresenter` runs from `build_float_key` to `paint_title` (about 300 lines) and reads `@float_key`, `@notice_from`, `@notices`, `@cache`, `@plain`, `@border`, `@ascii`, and `@repainted`; it calls the window path's `paint_text` and `paint_tokens` for a float's text rows. `StatusBar`, `TabBar`, and `Winbar` are collaborators built in `EditorAssembly` and handed to the presenter, which calls their `paint`.

## Decisions

- `FloatPainter` owns what only the floats and notifications read: the key array, `@notice_from`, the notifications, the border glyphs and the ASCII flag (set each frame by `configure(options)`, as `@border` and `@ascii` were), and the plain flag (`plain=`). `build_key(floats, rows, cols, tabline)` fills the key; `paint(frame, floats, repainted, tabstop, rows, cols, full)` paints the floats then the notifications. `boxes?(floats)` answers whether any float or notification is there to paint.
- The presenter keeps the frame side: the repainted rows (written by the window, header, winbar, and bar painters), `forget_rows`, `compare_boxes`, `under_float?`, `covers?`, and `clear_repainted`, reading the key through `float_painter.key`, the same array every frame, so no allocation is added. The stride of a key is `FloatPainter::STRIDE`.
- `paint_text`, `paint_plain`, `hex_digit`, and `paint_tokens` move to a stateless `LinePainter`; the presenter and the float painter each build one in their constructors, as the presenter builds `IndentGuides`, since it holds no state to share.
- `EditorAssembly` builds `FloatPainter.new(cache: @cache, notices: @notices)` beside the other collaborators; `test/adapters_assembly.rb` checks the cache and the notifications it holds are the shared ones.
- No delta specs: the frames are the same, which every snapshot proves.

## Risks

- A missed reader or a changed order of the per-frame settings would change a frame: every frame snapshot (`test/adapters_frame_presenter.rb`, `test/editor_floats.rb`, `test/editor_messages.rb`, and the rest) is run unchanged.
- The window path gains a call through a collaborator per painted row: `lh` and `lh-float` are measured by the benchmark phase.
