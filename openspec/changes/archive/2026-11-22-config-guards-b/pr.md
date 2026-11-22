fix(config): refuse project bindings outside an allowlist and held keys

## Summary

A project's `.caratrc` may now bind keys only to an allowlist of action families, and it can no longer unbind, rebind, or build around the keys that reach a write, a quit, the command line, or a plugin action. A cloned repository's configuration is untrusted, yet a denylist of four actions left every plugin file action such as `plugin.explorer.delete` bindable, and a project `none` could take away `:` and every quit.

---

## Changes

- Replace the `PROJECT_REFUSED` denylist with the `PROJECT_BINDABLE` allowlist in `carat/domain/config.rb`, refusing every other action, every `plugin.*` action included, as a file and line message naming the action
- Refuse a project keymap line, `none` included, on a key held by the defaults and the user file (a write, a quit, a command-line action, a plugin action, a key sequence, or `mode.cmdline` on `:`), comparing keys by the codes they spell under the leader
- Refuse a project binding whose keys start with a held key, such as `:w`, or begin one, such as the leader followed by `q`, so a held key never becomes a prefix
- Allow a project to bind `mode.cmdline` and `palette.open` only in the normal and visual modes, so insert-mode Enter cannot turn the next typed line into a command
- Change the predicates `language?` and `binding?` of `Config` into `language_problem` and `binding_problem`, noted by `add`, and name the keymap words `none`, `group`, and `leader` and the leader rule once in `Config`, used by `Keymap`
- Move the formatting of a line's problem text and order into `RcLine.problem_at` and `RcLine.order_at`, and require `rc_parse` from `rc_line.rb`
- Add gateway, parser, keymap, actions, and editor tests for the allowlist, the held keys, the keys around them, the prompt modes, and `:` still opening the command line
- Update the `config-files` spec, the README's configuration paragraph, `docs/architecture.md` section 7, and the `config.rb` and `keymap.rb` lines of `docs/codebase-map.md`
- Record the planned queue, the metrics row, and the review findings this change leaves open in `docs/findings/config-guards-b.md`

---

## Testing

- Run the security review of the committed diff, passed with no High or Medium finding and three Lows, none blocking, recorded as findings
- Run the check stages docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics at the reviewed head, all pass
- Run the benchmark review, passed with no blocking finding
- Run make spec-validate after the archive, all 56 items pass

---

## Notes

This is the first part of the queue entry `config-guards-b`, split by the planner: the options, `:set` pending list, gateway, input controller, and gen-config tidies are queued as `config-guards-c`. A key that only a plugin manifest binds is not held yet, since `Config` does not read manifest bindings and no shipped manifest binds a write, a quit, or the command line; it is recorded in the findings file with the other open Lows.
