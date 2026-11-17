# Tasks

## 1. Explorer

- [x] 1.1 In `carat/plugins/explorer/plugin.rb` `open_path`, look at `editing_window` before the `:tab` branch so `t` with no file window opens the file as `l` does, and correct the `open_entry` comment; proven by `test/editor_tab_flows.rb` ("t from a lone tree opens a file window", "t from a lone tree under tab pages opens a file window").

## 2. Finder

- [x] 2.1 In `carat/plugins/finder/plugin.rb` `open_path`, send `<C-t>` to `open_as_tab` when a window shows a file and to `open_file` as `<CR>` when none does; update the `open_tab` description and the header comment; proven by `test/editor_finder.rb` ("Ctrl-T opens a buffer tab", "Ctrl-T opens it in a tab page") and `test/editor_tab_flows.rb` ("Ctrl-T from a lone tree" under both values, "Ctrl-T opens a buffer tab beside the explorer", "Ctrl-T opens it in a tab page beside the explorer").

## 3. Docs

- [x] 3.1 Update the finder's `open_tab` row in `docs/actions.md` and the `open_as_tab` row of `docs/plugins.md`; proven by the snapshot run of every test (the actions table comparison included) and `make docs-lint`.

## 4. Gates

- [x] 4.1 Run `make lint`, `make gates`, `make spec-validate`, and `make diagnose-one` on the touched test roots, all clean.
