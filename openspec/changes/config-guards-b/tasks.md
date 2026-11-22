# Tasks

## 1. The allowlist and the held keys

- [x] 1.1 Replace `PROJECT_REFUSED` and `COMMAND_LINE` with `PROJECT_BINDABLE` and `Config.project_bindable?` in `carat/domain/config.rb`; prove it in `test/adapters_config_gateway.rb` ("a project file cannot bind a write, a quit, or the command line", "a project file cannot bind a plugin's file action") and `test/use_cases_actions.rb` (every entry names a registered action; the refused registered actions are the writes, quits, `cmdline.*`, and `plugin.*`)
- [x] 1.2 Add `held_keys` and refuse a project line, `none` included, on a held key in `carat/domain/config.rb`; prove it in `test/adapters_config_gateway.rb` ("a project file cannot unbind the command line", "a project file cannot take the user's quit or the leader's save", "a key the user freed is the project's to bind") and in an editor test that `:` still opens the command line

## 2. Problem methods and the shared words

- [x] 2.1 Turn `language?` and `binding?` into `language_problem` and `binding_problem`, noted by `add`, in `carat/domain/config.rb`; the existing language and binding tests of `test/adapters_config_gateway.rb` and `test/domain_rc_parser.rb` prove the messages unchanged
- [x] 2.2 Name `NONE`, `GROUP`, `LEADER`, and `DEFAULT_LEADER` once in `Config`, move the leader rule to `Config#leader` and `Config.leader_problem`, and use them from `carat/domain/keymap.rb`; prove it in `test/domain_keymap.rb` ("the leader is the last good leader line", "the config names the keymap words once")

## 3. Docs

- [x] 3.1 Update README.md, `docs/architecture.md` section 7, and `docs/codebase-map.md` for the allowlist and the held keys
