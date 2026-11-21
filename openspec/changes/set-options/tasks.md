# Tasks

## 1. One rule for a line and for :set

- [ ] 1.1 `Options` (`carat/domain/options.rb`): split `apply` into `problem` and `assign`, add `value_of` and `Options.shipped`; every existing line rule keeps its message (proved by `test/domain_options_config.rb`, all rows, and its new `value_of` and `problem` rows)

## 2. :set for the pending options

- [ ] 2.1 `SetCommandHandler`: the `NAMES` table, argument splitting with escapes, the number forms (`=`, `+=`, `-=`, `^=`, `?`, bare), E521 and E474 (proved by `test/editor_set_options.rb`, "Number options are set with set" scenarios)
- [ ] 2.2 The flag forms for every flag, E474 for a value and for a flag prefix on another kind (proved by `test/editor_set_options.rb`, "Flag options take Vim's boolean forms" scenarios, and `test/editor_search.rb` rows kept)
- [ ] 2.3 The word options, the backslash escapes, E474, and Not implemented for `+=` on a word (proved by `test/editor_set_options.rb`, "Word options are set with set" scenarios)
- [ ] 2.4 `name&` from the shipped options (proved by "Resetting an option")
- [ ] 2.5 Bare `:set` and `:set all` (proved by "A bare set lists the changed options" and "Set all lists every option")
- [ ] 2.6 Live effect: `undolevels` reaches the feed, `startscreen` answers Not implemented live (proved by "The number column follows set number", "A tab is drawn at the new tabstop", "Fewer undo levels", "startscreen is read only at startup")
- [ ] 2.7 `EditorAssembly` passes the shipped options and the feed; `theme` and `background` keep Not implemented (proved by `test/editor_syntax.rb`, "An option set does not handle yet")

## 3. Docs

- [ ] 3.1 `docs/compatibility.md` (`:set` rows per kind, every Difference and Options sentence that said `:set` does not handle an option), README options section, `docs/architecture.md` item 9, `docs/codebase-map.md`, `config/default.caratrc` comments and `make gen-config`
