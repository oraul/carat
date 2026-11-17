## 1. The label at the narrowest width

- [ ] 1.1 `Carat::UseCases::FollowPalette` adds `keyed?`, gives the label the whole row and leaves the key out below 24 cells in `rows` and `label_room`, proved by `test/editor_palette.rb` "A palette at the smallest screen shows a label" and the existing "A narrow palette leaves the name out" and "The label first, the key in caret notation on the right"
- [ ] 1.2 `Carat::UseCases::FollowPalette#styles` drops its unused `cut` parameter and `#pad` pads in one step, proved by `test/editor_palette.rb` "A cut description is marked", "An ascii cut mark", and "A 29-character name is whole"

## 2. Docs and checks

- [ ] 2.1 Correct the `follow_palette.rb` entry of `docs/codebase-map.md` and the palette line of README.md, checked by `make docs-lint` and `make lint`; append the handed findings to `docs/findings/palette-narrow.md`
- [ ] 2.2 Run `make gates`, `make spec-validate`, and `make test-one T=test/editor_palette.rb`; hold the recorded allocations with `make bench`
