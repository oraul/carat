# Tasks

## 1. One no-name word

- [x] 1.1 `carat/domain/messages.rb` holds `NO_NAME`; `StatusBar`, `Winbar`, `TabBar`, `ListBuffers`, and `Messages.unsaved_buffer` read it (proved by `test/adapters_status_bar.rb` and `test/adapters_tab_bar.rb`, `test/use_cases_ex.rb` unchanged)

## 2. The status bar's frame rows

- [x] 2.1 `test/adapters_status_bar.rb`: the bar's row in carat-dark, carat-light, and `option.icons ascii` (proved by the tests' labels)

## 3. Docs

- [x] 3.1 `docs/codebase-map.md` lists `NO_NAME` (proved by `make docs-lint`)

## 4. Review advisories

- [x] 4.1 Tests build the no-name rows from `Messages::NO_NAME`, assert the status bar groups once outside the theme loop, and the comment is narrowed; `NO_NAME` moved before `E16` and the module comment widened (proved by `test/adapters_status_bar.rb` and `test/adapters_tab_bar.rb`)
