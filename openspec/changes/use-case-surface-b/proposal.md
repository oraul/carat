# Proposal

## Why

Part a (#244) gave the use cases a public surface of `call` alone in one area, `carat/use_cases/discovery/`, with `test/adapters_assembly.rb` reading what each readerless holder was handed from the `WiringLedger` `EditorAssembly` fills. The windows area still keeps 20 public readers whose only reader is that guard, and part a's late review left seven advisories in the ledger, the lint rule that keeps it true, two tests, and section 8 of the architecture.

This is part b of 4 of the user-requested use-case-surface tidy-up: one area, `carat/use_cases/windows/` (map area 11), and part a's late findings 22 to 28. It changes how the core is wired and checked, not what the editor does.

## What Changes

- Edge-case tests first, in their own commit: a split, Ctrl-W c, and Ctrl-W o from the last line, and a split, `:close`, and `:new` with Ctrl-W o over an empty buffer (`test/editor_windows.rb`); `:tabclose`, `:tabonly`, and `:tabn` back to a tab page left on its last line, and `:tabnew` with `:tabclose` and `:tabclose N` over an empty buffer (`test/editor_tabs.rb`).
- The windows area without readers: `CloseFloat`, `CloseOtherTabs`, `CloseOtherWindows`, `CloseTab`, `CloseWindow`, `OpenFloat`, `OpenSideWindow`, `OpenTab`, `SplitWindow`, `SwitchTab`, and `ToggleSlot` replace their 20 readers with `# @rbs @name: Type` lines; none is read by production code, none includes a concern, and every method already reads the instance variables. `EditorAssembly` records each of those 20 objects in the ledger right after its holder's construction, `test/adapters_assembly.rb` reads them with `w.held` by `equal?`, and `READERLESS_DIRS` gains `carat/use_cases/windows/`.
- Finding 22: `holder_problems` in `test/lint.rb` calls `readerless_keyword_problems` (a readerless holder, by its signature) or `rbs_keyword_problems` (any other, by its `# @rbs` lines), its comment shortened to what it still does.
- Finding 23: one `ledger_records(holder, assembly)` reads a holder's `@wiring.record` lines as slot and object pairs, and one `passes?(built, keyword, value)` checks that the construction passes the object for the keyword; a record whose slot the construction does not pass and a record of another object than it passes are now one check with one message, in the record loop, and `ledger_problem` only asks for a record the test reads.
- Finding 24: the local `wiring` of the holder pass is renamed `assembly_text`.
- Finding 25 (listed as `carat/adapters/wiring_ledger.rb:262`, the branch at :24 to :31, the same item as the queue's `wiring_ledger.rb:24`): `WiringLedger#record` drops its replace-on-second-record branch, which no caller used, and the guard drops the probe row that covered it, keeping the check that a pair never recorded is a stranger.
- Finding 26: in `test/editor_key_hints.rb` and `test/editor_palette.rb`, `session` and the empty-buffer case call one `session_on` builder that takes the file's text, and `empty_session` goes.
- Finding 27: `reader_problems` refuses a public `attr_accessor` in a readerless directory as it does an `attr_reader`, with a self-test row.
- Finding 28: `docs/architecture.md` section 8 says the assembly keeps a reader for each shared object and records in its `WiringLedger` what each readerless holder was handed.
- Docs: `docs/examples.md` (the golden `SplitWindow` is now readerless), `docs/codebase-map.md` (area 4's guard and the lint entry's rule wording).

## Capabilities

### New Capabilities

None: the change alters how the core is wired and checked, no behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Out of scope

- The other areas' readers, the production reads, and the `call` signatures that return no `Outcome`: parts c and d, by part a's mapping. The windows area's `call`s already return an `Outcome`.
- Every finding 22 to 28 is fixed here, so none is left for the backlog.
- No `tools/rules.sh` edit; no file of the feature lane.

## Impact

- README.md: unchanged, it describes neither the use cases' readers nor the shared-instance guard.
- CLAUDE.md: unchanged, its sentence that every shared object is kept in a reader of `EditorAssembly` for the guard stays true.
- docs/architecture.md: section 8's composition root sentence (finding 28), its other clauses shortened so the file stays within its docs-lint budget; sections 5 and 10 already describe the readerless directories in general terms and stay.
- docs/codebase-map.md: area 4's guard sentence and the lint entry; area 11's entries name no reader and stay.
- docs/examples.md: the golden use case paragraph.
- Performance: no hot path changes (the ledger is written once at start); the pull request compares analysis time, rounds, binary size, and time per key with main's.
