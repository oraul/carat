# Tasks

## 1. incsearch clamp

- [x] 1.1 Clamp the preview cursor in `UseCases::PreviewSearch` with `EditorState#clamp_col`; proved by "incsearch on a match at the line end" in `test/editor_search.rb`

## 2. Pattern reading

- [x] 2.1 Read a `^` right after an anchoring one as a literal in `Domain::VimPattern`; proved by "A second caret is literal" in `test/editor_search.rb` and the `^^` rows of `test/domain_vim_pattern.rb`
- [x] 2.2 Share one collection scan between `VimPattern.pattern_end` and the compiler (`collection_close`, `posix_class_close`); proved by "An escaped bracket in a collection" in `test/editor_search.rb` and the pattern end rows of `test/domain_vim_pattern.rb`
- [x] 2.3 Add `VimPattern.compile_search` and pass the last substitute's string from `FindMatch`, `PreviewSearch`, `GlobalCommand`, and `LastSearch#recompile` (through `SetCommandHandler`), wired in `EditorAssembly`; proved by "Tilde after a substitute" and "Tilde with no substitute" in `test/editor_search.rb` and the tilde rows of `test/domain_vim_pattern.rb`

## 3. One cut

- [ ] 3.1 Add `DelimitedPattern.typed` and `SearchPrompt.prefix_of` and use them in `FindMatch` and `PreviewSearch`; proved by the search and offset rows of `test/editor_search.rb` staying green

## 4. Docs and checks

- [ ] 4.1 Update `docs/compatibility.md` (patterns, substitute differences) and `docs/codebase-map.md` (area 6 and the `DelimitedPattern` entry); `make gates`, `make spec-validate`, `make lint`, `make docs-lint`, and the touched tests pass
