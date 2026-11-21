# Tasks

## 1. One rule for a line and for :set

- [x] 1.1 `Options` (`carat/domain/options.rb`): split `apply` into `problem` and `assign`, add `value_of` and `Options.shipped`; every existing line rule keeps its message (proved by `test/domain_options_config.rb`, all rows, and its new `value_of` and `problem` rows)

## 2. :set for the pending options

- [x] 2.1 `SetCommandHandler`: the `NAMES` table, argument splitting with escapes, the number forms (`=`, `+=`, `-=`, `^=`, `?`, bare), E521 and E474 (proved by `test/editor_set_options.rb`, "Number options are set with set" scenarios)
- [x] 2.2 The flag forms for every flag, E474 for a value and for a flag prefix on another kind (proved by `test/editor_set_options.rb`, "Flag options take Vim's boolean forms" scenarios, and `test/editor_search.rb` rows kept)
- [x] 2.3 The word options, the backslash escapes, E474, and Not implemented for `+=` on a word (proved by `test/editor_set_options.rb`, "Word options are set with set" scenarios)
- [x] 2.4 `name&` from the shipped options (proved by "Resetting an option")
- [x] 2.5 Bare `:set` and `:set all` (proved by "A bare set lists the changed options" and "Set all lists every option")
- [x] 2.6 Live effect: `undolevels` reaches the feed, `startscreen` answers Not implemented live (proved by "The number column follows set number", "A tab is drawn at the new tabstop", "Fewer undo levels", "startscreen is read only at startup")
- [x] 2.7 `EditorAssembly` passes the shipped options and the feed; `theme` and `background` keep Not implemented (proved by `test/editor_syntax.rb`, "An option set does not handle yet")

## 3. Docs

- [x] 3.1 `docs/compatibility.md` (`:set` rows per kind, every Difference and Options sentence that said `:set` does not handle an option), README options section, `docs/architecture.md` item 9, `docs/codebase-map.md`, `config/default.caratrc` comments and `make gen-config`

## Quality review

- [x] Q.1 README and the `config/default.caratrc` comment listed the options `:set` leaves out without `jumptab` and `gt`, which answer E518; added (fixed)
- [x] Q.2 The Options section of `docs/compatibility.md` counted `startscreen` among the options `:set` sets at once; it now says only at startup (fixed)
- [x] Q.3 `SetCommandHandler#set_word` tested `filetype` and `syntax` against the flag kind, which `Options::KINDS` never gives them; the redundant test is gone (fixed)
- [x] Q.4 A `no` prefix on `filetype` changed from E518 to E474 with no test; `test/editor_set_options.rb` row "a flag prefix on filetype is E474" proves it (fixed)
- [x] Q.5 The queue entry's backlog headings on `wrap` and `clipboard` and on `:set jumptab` are only partly answered by this change; recorded in `docs/findings/set-options.md` (recorded)

Edge-case checklist: `:set` takes no range or buffer text, so the empty range, CRLF, trailing blanks, last line, and empty buffer do not arise; multi-byte values (`listchars` of `→`, `·`, `␣`) are split by bytes at ASCII blanks and backslashes only, proved by the shipped value's `lcs&` row; the existing helpers `RcValue.valid?`, `RcValue.number?`, and the option rules of `Options` are reused.
