# Backlog: carat/domain/config.rb

## Spinel drops appends to an empty array literal passed to a method

- Where: found in `Config#report` (`carat/domain/config.rb`), whose merge helper first appended to an array the caller created as `[]`; on the pinned Spinel the caller's array stayed empty, while one created as `[0]` kept the appends (`docs/spinel-notes.md`).
- Why it matters: any helper that fills an out-parameter starting empty silently loses its work, and only a test of the result catches it.
- Fix outline: reduce it with `spinel-reduce`, report it upstream with the probe, and when a fixed pin arrives let `merge_runs` append in place again; until then a filling helper returns the array and the caller assigns it. Rechecked at f34005bf: a reduced `merge_runs` keeps the appends at both pins, so only reverting `Config#report` decides it.
- Also: docs/spinel-notes.md
- Category: editor
- Added: 2026-11-03

## Config predicates note problems and repeat the none word

- Where: `language?` and `binding?` in `carat/domain/config.rb` lines 185 and 210 at b0dd342. Periodic quality. Queued in the backlog item batch.
- Why it matters: a predicate with a side effect breaks the naming rule, and `binding?` repeats `Keymap::NONE` and the action-name check.
- Fix outline: answer only, note at the caller, and name the none word once in a domain constant.
- Category: editor
- Added: 2026-11-07

## Config pins its settings as untyped

- Where: `carat/domain/config.rb:27`; `carat/domain/search_pattern.rb:9`. Periodic quality advisory.
- Fix outline: `Array[RcLine]` or a comment naming the Spinel limit; a comment for the dropped Regexp signature. Backlog batches (RBS pins).
- Also: carat/domain/search_pattern.rb
- Category: editor
- Added: 2026-11-10

### An untrusted project .caratrc may bind keys to destructive actions

- Location: carat/domain/config.rb:236 (sweep, security Low (4)).
- Why: a project .caratrc may bind any key in any mode to any action, such as quit.write_all or buffer.delete, so a cloned repository can turn common keys into writes or discards.
- Fix outline: read project keymap lines only under language.trusted_roots, or allow only non-destructive actions there.
- Category: security
- Added: 2026-11-17

### language.trusted_roots keeps a word that is not a root (sprint-14 sweep quality)

- Location: carat/domain/config.rb:204 and :219, :223.
- Why: trusted_roots returns before its words are checked, so ./proj, projects, or ~x is kept and trusts nothing silently while an lsp.root root is reported; two consecutive blocks test the same setting.
- Fix outline: report each word RootWord.root? refuses, with a row in test/domain_rc_parser.rb; merge the two blocks. Queued in `project-config-guards`.
- Also: test/domain_rc_parser.rb
- Category: editor
- Added: 2026-11-17

### Language? tests setting == ROOTED_SETTING twice in a row (sprint-20 sweep quality, config.rb:219)

- Location: `carat/domain/config.rb:219`
- Why: language? tests setting == ROOTED_SETTING twice in a row (lines 219 and 223)
- Fix: one if block checking the word count and then the root
- Category: editor
- Added: 2026-11-19

### A project .caratrc can bind a key to a plugin's file action
- Location: `carat/domain/config.rb` `binding?` (`PROJECT_REFUSED`, `COMMAND_LINE`); the explorer's file actions such as `plugin.explorer.delete` and `plugin.explorer.rename`.
- Why: the project file may no longer bind a write, a quit, or a command-line action, but it may still bind a key, in a mode the plugin reads, to a plugin action that deletes, renames, or creates a file, so a key the user types can change files they did not choose; the domain cannot ask the plugin host which actions touch files.
- Fix: let a plugin manifest mark an action as file-changing (a manifest flag the host reads), and have the plugin host refuse a project file's binding to a marked action, reported as the core refusals are, with a test per plugin action marked.
None
- Category: editor
- Added: 2026-11-21
