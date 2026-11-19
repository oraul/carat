## 1. The preview

- [x] 1.1 Keep each file's first stored index in `Grep` (`@starts`), add `Grep#preview` (centred, clamped, marked, safe, no read) and `Grep#shown_path`, and keep printable ASCII as it is in `safe` (`carat/plugins/finder/grep.rb`); tests in `test/editor_finder_grep_preview.rb`
- [x] 1.2 Open the preview float for the grep picker in `Finder::Plugin#refresh` through `preview_lines` (`carat/plugins/finder/plugin.rb`); tests in `test/editor_finder_grep_preview.rb` (the threshold, following a move and a query, an empty result, safe text, the shared sizing) and the updated rows of `test/editor_finder_grep.rb`

## 2. Docs

- [x] 2.1 Update README.md, docs/plugins.md, and docs/codebase-map.md (the finder area and its tests line); make docs-lint

## 3. Review round

- [x] 3.1 Test that the preview is built from the stored text: a row opens the picker, changes a file on the disk, moves the highlight, and sees the stored lines (`test/editor_finder_grep_preview.rb`); the delta spec gains the scenario The preview is built from the stored text
- [x] 3.2 Name the preview's title `preview_title` in `Finder::Plugin#refresh`, and write `Grep#shown_path` through `path_at`
- [x] 3.3 Correct the proposal's Impact line: the requirement The grep list uses the whole width is removed and replaced by The grep list is sized as the file finder's list
- [x] 3.4 Extract `second_float` in `test/editor_finder_grep_preview.rb` and call it from `preview_text` and the stored-text row, so the second-float pick is written once
