## 1. Option

- [x] 1.1 Add the `hidden` flag to `Options` (member, default on, `KINDS`, `assign`, `value_of`), `option.hidden true` in `config/default.caratrc`, and regenerate `carat/domain/default_config.rb` with `make gen-config`
- [x] 1.2 Add `hidden` (`hid`) to the `:set` handler's names

## 2. Behavior

- [x] 2.1 `:e` of another file leaves a modified buffer hidden under `hidden`, keeping E37 for the reload of the current file and with `hidden` off
- [x] 2.2 `SwitchBuffer` leaves a modified buffer hidden under `hidden`, keeping E37 with it off

## 3. Tests

- [x] 3.1 Table-driven rows of `:e`, `:b N`, `:bn`, `:bp`, `:bN`, `:bfirst`, `:blast` with hidden on and off, `:qa` naming a hidden modified buffer, and `:set hid` in `test/editor_buffers.rb`, `test/use_cases_ex.rb`, `test/editor_set_options.rb`, `test/domain_options_config.rb`, `test/editor_jumps.rb`, and `test/editor_tabs.rb`
- [x] 3.2 Set `nohidden` in the tests that expect E37

## 4. Docs

- [x] 4.1 Update `docs/compatibility.md`, the README options section, `docs/architecture.md`, and `docs/codebase-map.md`

## Quality review

- [x] 5.1 The `:qa` assertion held before the fix too: check first that the window shows the other file, then that `:qa` names the hidden buffer
