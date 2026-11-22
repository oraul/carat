# Tasks

## 1. The allowlist and the held keys

- [x] 1.1 Replace `PROJECT_REFUSED` and `COMMAND_LINE` with `PROJECT_BINDABLE` and `Config.project_bindable?` in `carat/domain/config.rb`; prove it in `test/adapters_config_gateway.rb` ("a project file cannot bind a write, a quit, or the command line", "a project file cannot bind a plugin's file action") and `test/use_cases_actions.rb` (every entry names a registered action; the refused registered actions are the writes, quits, `cmdline.*`, and `plugin.*`)
- [x] 1.2 Add `held_keys` and refuse a project line, `none` included, on a held key in `carat/domain/config.rb`; prove it in `test/adapters_config_gateway.rb` ("a project file cannot unbind the command line", "a project file cannot take the user's quit or the leader's save", "a key the user freed is the project's to bind") and in an editor test that `:` still opens the command line

## 2. Problem methods and the shared words

- [x] 2.1 Turn `language?` and `binding?` into `language_problem` and `binding_problem`, noted by `add`, in `carat/domain/config.rb`; the existing language and binding tests of `test/adapters_config_gateway.rb` and `test/domain_rc_parser.rb` prove the messages unchanged
- [x] 2.2 Name `NONE`, `GROUP`, `LEADER`, and `DEFAULT_LEADER` once in `Config`, move the leader rule to `Config#leader` and `Config.leader_problem`, and use them from `carat/domain/keymap.rb`; prove it in `test/domain_keymap.rb` ("the leader is the last good leader line", "the config names the keymap words once")

## 3. Docs

- [x] 3.1 Update README.md, `docs/architecture.md` section 7, and `docs/codebase-map.md` for the allowlist and the held keys

## Quality review

- [x] 4.1 The parse-error note of `Config#add` and the note of `refuse` built the line's problem text and order by hand beside `RcLine#problem` and `#order`: `RcLine.problem_at` and `RcLine.order_at` hold both, in `carat/domain/rc_line.rb`; the parse-error and refusal tests of `test/domain_rc_parser.rb` and `test/adapters_config_gateway.rb` prove the text unchanged
- [x] 4.2 `carat/domain/rc_line.rb` named `RcParse` without requiring it, so `make diagnose-one` of the file warned: it requires `rc_parse`
- [x] 4.3 A plugin manifest's bindings are not read by `Config`, so a key only a manifest binds is not held: recorded in `docs/findings/config-guards-b.md`, since no shipped manifest binds a write, a quit, or the command line and holding them needs the plugin registry at read time

## 5. Review fixes

- [x] 5.1 A project binding of keys that start with a held key, such as `:w`, or begin one, such as `<Space>q`, made the held key a prefix: `binding_problem` refuses it by `held_overlap` in `carat/domain/config.rb`, `none` still kept; proved in `test/adapters_config_gateway.rb` ("a project file cannot bind keys that start with or begin a held key")
- [x] 5.2 A project could bind `mode.cmdline` or `palette.open` to insert-mode `<CR>`, turning the next line typed into a command: `Config.project_bindable_in?` allows `PROMPT_ACTIONS` only in `PROMPT_MODES`, in `binding_problem` and `held_keys`; proved in `test/adapters_config_gateway.rb` ("a project file binds the command line and the palette only in normal and visual modes")
- [x] 5.3 Update README.md, `docs/architecture.md` section 7, and `docs/codebase-map.md` for both
