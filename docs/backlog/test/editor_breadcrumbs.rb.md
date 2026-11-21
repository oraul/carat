# Backlog: test/editor_breadcrumbs.rb

## Scratch split under breadcrumbs auto is untested

- Location: test/editor_breadcrumbs.rb:209
- Source: quality advisory, winbar-outline
- Why: the requirement says a scratch split gets exactly the counted rows under every breadcrumbs mode and the design names the auto case beside two file windows as fixed, but only always is tested.
- Fix outline: add a row with option.breadcrumbs auto and two file windows splitting 5<C-w>s from the scratch window, expecting 5 text rows and no winbar.
- Category: code-quality
- Added: 2026-11-15

### The winbar has no direct unit test of its own
- Location: test/editor_breadcrumbs.rb
- Why: the winbar's groups and the no-name word are proved only through the whole editor rig; a frame-level test with a held SymbolRequest would pin the unnamed-buffer row and the ascii separator without a language server double.
- Fix: add test/adapters_winbar.rb (make new-test) with a Window, a SymbolRequest holding names, and rows for the unnamed buffer, the ascii separator, and the accent group.
- Category: code-quality
- Added: 2026-11-21
