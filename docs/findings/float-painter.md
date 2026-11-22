### The float key's layout is read in two classes at carat/adapters/frame_presenter.rb
- Location: `carat/adapters/frame_presenter.rb` `forget_rows`, `compare_boxes`, `covers?` (walking by `FloatPainter::STRIDE`), and `carat/adapters/float_painter.rb` `build_float_key`, `add_notice_boxes`.
- Why: the presenter reads the box rows and columns at offsets 0 to 3 of each `STRIDE` group the float painter writes, so a change of the key's layout must be made in both files.
- Fix: give `FloatPainter` the box queries over a key (`covers?`, and a row range per box the presenter iterates for `forget_rows` and `compare_boxes`), so only it knows the offsets.
