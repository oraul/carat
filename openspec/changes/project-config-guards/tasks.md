# Tasks

## 1. The project file opened without following a link

- [x] 1.1 `carat/ports/file_port.rb`, `carat/drivers/disk_files.rb`, `carat/doubles/memory_files.rb`: `read_no_link` (proved by "a link is refused by the open" in `test/drivers_disk_files.rb`)
- [x] 1.2 `carat/adapters/rc_config_gateway.rb` reads the project file with `read_no_link` (proved by "a project file swapped for a link after the check is not read" in `test/adapters_config_gateway.rb`)

## 2. Project bindings to a write, a quit, or the command line

- [x] 2.1 `carat/domain/config.rb` `binding?` refuses `PROJECT_REFUSED` and `cmdline.` actions in every mode (proved by the rows of `test/domain_rc_parser.rb` and "a project file cannot bind a write, a quit, or the command line" in `test/adapters_config_gateway.rb`; `test/use_cases_actions.rb` checks every listed name is registered)

## 3. Options

- [x] 3.1 `carat/domain/options.rb` `bounded` and `named` replace `width_problem`, `range_problem`, and the known-name branches (proved by the unchanged rows of `test/domain_options_config.rb`)
- [ ] 3.2 `carat/domain/options.rb` bounds scroll, scrolloff, timeoutlen, undolevels (proved by "numbers past the limits" and "the limits themselves" in `test/domain_options_config.rb`)

## 4. Docs

- [ ] 4.1 `docs/architecture.md`, `README.md`, `docs/compatibility.md`, `docs/codebase-map.md` (proved by `make lint` and `make docs-lint`)
