# Tasks

## 1. Real-path containment for rename and delete

- [ ] 1.1 Add `ResolveInside` in `carat/use_cases/files/resolve_inside.rb` with `make new-use-case`, move `MakePath#resolved_inside?` into its `call`, give `MakePath` a required `resolve_inside:` keyword, and build it once in `PluginHost`; verify the create rows of `test/use_cases_plugin_files.rb` and `test/drivers_disk_files.rb` still pass
- [ ] 1.2 Check the entry's directory with `ResolveInside` in `RenamePath` and `DeletePath` after the existence check; verify hostile rows (below a link leading out, below a link staying inside, a linked root, the link itself) in `test/use_cases_plugin_files.rb` and rename and delete rows over real links in `test/drivers_disk_files.rb`
- [ ] 1.3 Check in `test/adapters_assembly.rb` that the three use cases share one `ResolveInside` holding the shared file port; verify with `make test-one T=test/adapters_assembly.rb`
- [ ] 1.4 Update the map (area 12 and the tests line), `docs/architecture.md` section 5.2, and remove the backlog entry "Plugin rename and delete follow symlinked directories out of the tree root"; verify with `make docs-lint` and `make lint`

## 2. Bounded binding length

- [ ] 2.1 Refuse more than `MAX_KEYS` (64) keys in `Keymap#bind_text` with `more than 64 keys`; verify rows in `test/domain_keymap.rb` for 65 keys from the configuration (reported, unbound), 64 keys (bound), and a plugin's 65-key line (an error) with its 64-key line removed by `remove_owner`

## 3. Linear problem report

- [ ] 3.1 Replace the insertion sort of `Config#report` with a stable merge of the ascending runs; verify the existing order test and a new row in `test/domain_rc_parser.rb` with 20,000 interleaved problems from two readers reported in line order

## 4. Bookkeeping

- [ ] 4.1 Add the delivered-changes line for `untrusted-config-limits` (#37) to `docs/codebase-map.md`; verify with `make docs-lint`
- [ ] 4.2 Record in `docs/backlog.md` the periodic findings at 389c118 not fixed here (run_state `set` of `review.*`, read-only agents with unrestricted Bash, the duplicate checks in `options.rb`, `OpenFile`'s double existence query, its responses in `docs/architecture.md`, the long comment in `memory_files.rb` folded into the wrap-width entry, the 64 MiB test strings, the four stats in `disk_files.rb`) and drop the stale `config.rb` half of the `Carat::Json` entry; verify with `make docs-lint`
- [ ] 4.3 Run `make gates`, and confirm every scenario of the delta specs has code and a test

## Workflow follow-up

- Check, review, benchmark, archive, pull request, CI, and merge through `/deliver`.
