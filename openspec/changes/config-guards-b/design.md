# Design

## Context

`Config#read` checks each line of a file as it reads it; an untrusted file's keymap lines went through `binding?`, which refused a leader, a key sequence, and a value in `PROJECT_REFUSED` or under `cmdline.`, and returned true for `none` before any check. `Keymap#add_checked` applies the kept lines later, with the leader `Keymap.leader_from` reads.

## Decisions

- Allowlist by family. `PROJECT_BINDABLE` lists entries ending in a dot as families and the rest as single actions, so `window.quit` stays out while the other window actions are named one by one. A family a later change adds, and every `plugin.*` action, is refused until it is named: plugin actions are opaque to the configuration and can delete or write files. A mark on the action table was the other option; the configuration is read before the action table exists and lives in the domain, so the list is the one place that can decide at read time. `test/use_cases_actions.rb` keeps the list honest: every entry names a registered action, and the refused registered actions are exactly the writes, quits, `cmdline.*`, and `plugin.*`.
- Held keys. Before an untrusted file's lines, `held_keys` walks the lines kept so far (the defaults and the user file) and records, per keymap line name and key codes, the binding in effect when it is one the project could not make (outside the allowlist, a key sequence) or `mode.cmdline`; a later `none` or bindable action frees the key. A project line, `none` or an action, on a held key is refused. Rebinding is refused with `none` because it takes the key away just the same. The table is built once per file, so a hostile file of many lines costs one parse and one lookup per line.
- Keys compare as codes. `KeyNotation.parse` under the leader in effect spells `<leader>fs` and `<Space>fs` the same, so a project line cannot slip past by writing the leader out. The project cannot set the leader, so the leader read before its lines is the one the keymap uses.
- The leader rule moves to `Config` (`leader`, `leader_problem`), since `Config` needs it and `keymap.rb` requires `config.rb`, not the reverse; `Keymap.leader_from` delegates, so its callers stay.
- Problem methods. `language_problem` and `binding_problem` return the text or `""`, and `add` notes a non-empty one, the shape `Keymap#apply` already has; no predicate notes.

## Risks

- A test that set a project binding of a plugin action, or rebound a held key, through `FixedConfig.with` now sees it refused; those tests use the user file (`with_user`) instead, which is what the binding means.
