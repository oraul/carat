# Tasks

## 1. Formatter setting

- [x] 1.1 Answer a formatter line as not supported yet in `carat/domain/config.rb` (`PLANNED_SETTINGS`), proven by "a language setting not supported yet" in `test/domain_rc_parser.rb`
- [x] 1.2 Remove the shipped formatter line from `config/default.caratrc` and regenerate `carat/domain/default_config.rb` with `make gen-config`, proven by `test/config_sync.rb` ("The defaults ship no formatter")
- [x] 1.3 Update README.md and `docs/architecture.md` section 7

## 2. Ex descriptions with their registration

- [ ] 2.1 Make `ExTable#register` take the description and drop `DESCRIPTIONS` (`carat/use_cases/ex/ex_table.rb`), proven by a table test in `test/use_cases_actions.rb`
- [ ] 2.2 Pass each description from the sixteen `carat/use_cases/ex/*_command_handler.rb` families, proven by "every ex command has a description of 1 to 32 characters"
- [ ] 2.3 Make the `new-ex-command` generator (`tools/new.sh`) write a description, proven by `tools/tools_test.sh`; update `docs/examples.md` and the map where they name the ex wiring

## 3. Dead code

- [ ] 3.1 Remove `of_char`, `tabstop_of`, `operator_pending?`, `counted?`, and `input?` and their code-map entries, proven by `test/lint.rb`
- [ ] 3.2 Document `PluginApi::Command#args?` and `PluginApi::Edit#insertion?` in `docs/plugins.md`

## 4. Close

- [ ] 4.1 Run `make gates` and `make spec-validate`
