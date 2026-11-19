## 1. The preview

- [x] 1.1 Keep each file's first stored index in `Grep` (`@starts`), add `Grep#preview` (centred, clamped, marked, safe, no read) and `Grep#shown_path`, and keep printable ASCII as it is in `safe` (`carat/plugins/finder/grep.rb`); tests in `test/editor_finder_grep_preview.rb`
- [x] 1.2 Open the preview float for the grep picker in `Finder::Plugin#refresh` through `preview_lines` (`carat/plugins/finder/plugin.rb`); tests in `test/editor_finder_grep_preview.rb` (the threshold, following a move and a query, an empty result, safe text, the shared sizing) and the updated rows of `test/editor_finder_grep.rb`

## 2. Docs

- [x] 2.1 Update README.md, docs/plugins.md, and docs/codebase-map.md (the finder area and its tests line); make docs-lint
