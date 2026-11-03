# Proposal

## Why

A cloned repository is untrusted input, and the periodic security review at 389c118 found three ways it still reaches past the limits `untrusted-config-limits` (#37) set. The explorer's rename and delete check containment lexically only, so in a tree with a link such as `docs` pointing to the home directory, renaming or deleting `docs/x` changes a file outside the project (Low (5), `carat/use_cases/files/rename_path.rb:35`, `delete_path.rb:33`); #37 fixed only the create half. A project `.caratrc` binding of unbounded length builds a keymap trie as deep as the binding is long, and the recursive walk that removes a disabled plugin's bindings then overflows the stack and crashes the editor with unsaved work (Low (4), `carat/domain/keymap.rb:245`). And the configuration problems are insertion-sorted, so a 1 MiB project file of interleaved bad option and keymap lines makes startup quadratic (Low (3), `carat/domain/config.rb:117`). Security fixes go first, so this change is outside the roadmap order; it is queue item 1 (`docs/queue.md`).

## What Changes

- A plugin's rename or delete request is refused with `Outside the tree root: path` and no change on disk when the directory holding the entry, with every symbolic link resolved, is neither the root with its links resolved nor inside it; the target of a rename lies in the same directory, so one check covers both. A link that stays inside the root, a root that is itself a link, and the link entry itself (renamed or unlinked, never followed) still work.
- The real-path comparison `MakePath` keeps privately becomes one use case, `ResolveInside`, built by the plugin host and given to `MakePath`, `RenamePath`, and `DeletePath`.
- A keymap line whose keys are more than 64 keys long is reported as `file:line: more than 64 keys` and skipped, in the configuration and in a plugin's default bindings, so no trie is deeper than 64 nodes.
- `Config#report` merges the ascending runs in which the readers note problems instead of insertion-sorting them, so the report keeps exactly today's order (file, then line, then the order noted) in time linear in the problems for the readers' runs and never worse than n log n.
- Docs: the delivered-changes line for `untrusted-config-limits` (#37) in `docs/codebase-map.md`; the map, `docs/architecture.md` section 5.2, and `docs/backlog.md` updated for the new use case; the backlog entry this change fixes removed, the stale `config.rb` half of the `Carat::Json` entry dropped, and every periodic finding at 389c118 not fixed here recorded.

Out of scope: the findings recorded in the backlog (the run state's `review.*` keys, the agents' unrestricted Bash, the duplicate checks in `options.rb`, `OpenFile`'s double existence query, its E484 responses in `docs/architecture.md`, the long comment in `memory_files.rb`, the 64 MiB test strings, and the four stats per path in `disk_files.rb`), which queue items `agent-authority`, `file-access-tidy`, and the backlog item list take up; a cap on the number of problems; making `clear_owner` iterative, which the bound makes unnecessary; and a race in which the tree changes between the check and the rename or delete.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `plugin-host`: a rename or delete request through a symbolic link that leaves the root is refused.
- `keymap-config`: a binding of more than 64 keys is reported and skipped.
- `config-files`: any number of problems is reported in file and line order, in time that does not grow with the square of their count.

## Impact

- Code: `carat/use_cases/files/resolve_inside.rb` (new), `make_path.rb`, `rename_path.rb`, `delete_path.rb`, `carat/use_cases/plugins/plugin_host.rb`, `carat.rb`, `carat/domain/keymap.rb`, `carat/domain/config.rb`.
- Tests: hostile rows in `test/use_cases_plugin_files.rb` and `test/drivers_disk_files.rb` (real links on disk), `test/domain_keymap.rb`, `test/domain_rc_parser.rb`, and the shared-instance check in `test/adapters_assembly.rb`.
- Docs: `docs/codebase-map.md`, `docs/architecture.md`, `docs/backlog.md`.
- No new dependency. Nothing on the per-key path changes: the length check runs when bindings load, the report at startup, and the real-path checks on an explorer rename or delete, so allocations per key stay at the baseline.

Assumptions recorded here:

- The bound is 64 keys, a constant, far above any real binding (the defaults use at most three), with the message `more than 64 keys`.
- The real-path check runs after the existence check, as it does in `MakePath`, so a missing entry keeps its `No such file or directory` message.
- "Linear or capped": the report stays complete and in the same order, which a cap could not keep; the readers note in a fixed number of ascending runs, so merging runs is linear in practice.
- The stale `config.rb` backlog entry is the `carat/domain/config.rb` line 176 half of "Carat::Json and String#index on text that is not UTF-8" (periodic quality note at 389c118): the parser now refuses illegal bytes, so that `index` cannot see one. The `Carat::Json` half stays.
