feat(set): set every option the editor has with :set

## Summary

Lets `:set` change every option the editor has while it runs, by its full and short name and in Neovim's forms, instead of answering `Not implemented: :set name` for all but filetype, syntax, the search options, and cursorline. Options could be changed only by editing a `.caratrc` file and restarting. Each value goes through the same check as its `option.*` configuration line, so `:set` never stores a value the configuration would refuse.

---

## Changes

- Add `:set` for the number options `tabstop`, `shiftwidth`, `scroll`, `scrolloff`, `timeoutlen`, `undolevels`, and `showtabline` with `=`, `+=`, `-=`, `^=`, `?`, and the bare name, refusing a non-number with `E521` and a value out of range with `E474` while keeping the old value
- Add Vim's boolean forms for the flags `number`, `relativenumber`, `expandtab`, `autoindent`, `list`, `reducedmotion`, and `startscreen` beside the search options and `cursorline`, and the words `listchars`, `winborder`, `icons`, and `breadcrumbs` as `name=value` and `name?`, a backslash keeping a blank in the value
- Add `name&` to reset an option to its shipped default, a bare `:set` listing the options changed from their defaults, and `:set all` listing every option `:set` takes
- Change the effect of a set to show at once, the frame and the window's view reading the new value and `undolevels` reaching the buffers' undo records, while `startscreen`, read only at startup, answers `Not implemented: :set startscreen live`
- Refactor `Options` so one `problem` check serves both the configuration lines and `:set`, with `value_of` and the shipped options for showing, listing, and resetting
- Change the refusals so a `no` or `inv` prefix, a value, or `!` on an option that is not a flag is `E474`, while `theme` and `background` still answer `Not implemented: :set name` and Carat's own options outside the list answer `E518`
- Add the `set-command` spec, change the syntax-highlighting `:set` requirement, and remove the config-files requirement that said `:set showtabline` is not implemented
- Add `test/editor_set_options.rb`, a table-driven test of every option kind and form, and rows for `value_of` and `problem` in `test/domain_options_config.rb`
- Document the forms in the `:set` rows of `docs/compatibility.md` split per kind and in its Differences and Options sentences, the README options section, the roadmap line of `docs/architecture.md`, the code map, and the comments of `config/default.caratrc` with its generated mirror

---

## Testing

- Run the security review of the committed diff, passed with no finding (high 0, medium 0, low 0)
- Run the checker's stages at the implementation head (dev-build, test-build, diagnose, test-run, gates, docs-lint, tools-test, bench-budget, metrics), every stage passes
- Run the benchmark review, passed: `lh` 25.0, `j` 26.0, and `insert` 25.0 allocations, as on main
- Run `make spec-validate` after the archive, all 56 items pass

---

## Notes

The planner split the brief in three: this part delivers `:set` for the existing options, while the `hidden` option and `:colorscheme` with `:set theme=` and `:set background=` follow as the separate Sprint 26 items hidden-option and colorscheme-command. Every option stays global, with no `:setlocal`, `:set all&`, or the comma-list forms of a word option. The queue entry's notes on `wrap`, `clipboard`, and `:set jumptab` are only partly answered here and are recorded in the change's findings file.
