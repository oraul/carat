# Tasks

## 1. Explorer

- [ ] 1.1 In `carat/plugins/explorer/plugin.rb` `open_path`, look at `editing_window` before the `:tab` branch so `t` with no file window opens the file as `l` does, and correct the `open_entry` comment; proven by `test/editor_tab_flows.rb` ("t from a lone tree opens a file window", "t from a lone tree under tab pages opens a file window").

## 2. Finder

- [ ] 2.1 In `carat/plugins/finder/plugin.rb` `open_path`, send `<C-t>` to `open_as_tab` when a window shows a file and to `open_file` as `<CR>` when none does; update the `open_tab` description and the header comment; proven by `test/editor_finder.rb` ("Ctrl-T opens a buffer tab", "Ctrl-T opens it in a tab page") and `test/editor_tab_flows.rb` ("Ctrl-T from a lone tree", "Ctrl-T opens a buffer tab", "Ctrl-T opens it in a tab page").

## 3. Docs

- [ ] 3.1 Update the finder's `open_tab` row in `docs/actions.md` and the `open_as_tab` row of `docs/plugins.md`; proven by `make test-one T=test/docs_actions.rb` or the test comparing the actions table, and `make docs-lint`.

## 4. Gates

- [ ] 4.1 Run `make lint`, `make gates`, `make spec-validate`, and `make diagnose-one` on the touched plugins, all clean.
