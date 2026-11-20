### The ascii gem and the ascii modified mark are both `*`
- Location: carat/adapters/tab_bar.rb (ASCII_GEM) and the ascii `modified` icon in carat/domain/icons.rb
- Why: under option.icons ascii a tab reads `* . a.txt * |` when it is both selected and modified, the two marks differing only by position, so the selection reads less clearly than with the unicode set.
- Fix: choose another ascii gem (for example `>`) or an ascii modified mark such as `+`, with the tests of both rows, once the user picks the glyph.
### The winbar has no direct unit test of its own
- Location: test/editor_breadcrumbs.rb
- Why: the winbar's groups and the no-name word are proved only through the whole editor rig; a frame-level test with a held SymbolRequest would pin the unnamed-buffer row and the ascii separator without a language server double.
- Fix: add test/adapters_winbar.rb (make new-test) with a Window, a SymbolRequest holding names, and rows for the unnamed buffer, the ascii separator, and the accent group.
