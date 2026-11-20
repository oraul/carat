# Tasks

## 1. The project file opened without following a link

- [x] 1.1 `carat/ports/file_port.rb`, `carat/drivers/disk_files.rb`, `carat/doubles/memory_files.rb`: `read_no_link` (proved by "a link is refused by the open" in `test/drivers_disk_files.rb`)
- [x] 1.2 `carat/adapters/rc_config_gateway.rb` reads the project file with `read_no_link` (proved by "a project file swapped for a link after the check is not read" in `test/adapters_config_gateway.rb`)

## 2. Project bindings to a write, a quit, or the command line

- [x] 2.1 `carat/domain/config.rb` `binding?` refuses `PROJECT_REFUSED` and `cmdline.` actions in every mode (proved by the rows of `test/domain_rc_parser.rb` and "a project file cannot bind a write, a quit, or the command line" in `test/adapters_config_gateway.rb`; `test/use_cases_actions.rb` checks every listed name is registered)

## 3. Options

- [x] 3.1 `carat/domain/options.rb` `bounded` and `named` replace `width_problem`, `range_problem`, and the known-name branches (proved by the unchanged rows of `test/domain_options_config.rb`)
- [x] 3.2 `carat/domain/options.rb` bounds scroll, scrolloff, timeoutlen, undolevels (proved by "numbers past the limits" and "the limits themselves" in `test/domain_options_config.rb`)

## 4. Docs

- [x] 4.1 `docs/architecture.md`, `README.md`, `docs/compatibility.md`, `docs/codebase-map.md` (proved by `make lint` and `make docs-lint`)

## 5. Review fixes

- [x] 5.1 `carat/domain/config.rb` `binding?` refuses a project file's `keymap.leader` line, so the `<leader>` write and quit bindings stay on the defaults' or the user's leader (proved by "a project leader leaves <leader>fs and <leader>qw on the user's leader" and "a project leader leaves the default leader" in `test/adapters_config_gateway.rb` and the leader row of `test/domain_rc_parser.rb`; delta spec "A project file cannot set the leader")
- [x] 5.2 `test/use_cases_actions.rb` asserts the command line has refused actions instead of pinning their number at 4
- [x] 5.3 `test/adapters_config_gateway.rb` drops "a user file read through a link is still read", which repeated the "a linked user file is read" row
- [x] 5.4 `docs/architecture.md` section 7 again says the problems name their files and that the project file still binds other action names and `none`
- [x] 5.5 `carat/domain/options.rb` passes the word to `bounded` as `named` gets it
