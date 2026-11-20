# Design

## Context

Part a (#244) set the design: a use case's public surface is `call`, its collaborators are read as instance variables, and `test/adapters_assembly.rb` reads what each holder of a readerless directory was handed from the `WiringLedger` `EditorAssembly` fills, `lint`'s shared-holder rule keeping each record true to the construction and read by the test. `carat/use_cases/discovery/` is the one readerless directory. This part moves the windows area and fixes part a's late findings 22 to 28.

## Goals / Non-Goals

Goals: `carat/use_cases/windows/` with no public reader, its holders checked through the ledger with `equal?`, the seven late findings fixed, and the measurements compared with main's.

Non-goals: the other areas and the `call` signatures (parts c and d).

## Decisions

### The area: windows

`carat/use_cases/windows/` (map area 11) holds 20 readers in 11 use cases: `CloseFloat` 1, `CloseOtherTabs` 2, `CloseOtherWindows` 2, `CloseTab` 2, `CloseWindow` 2, `OpenFloat` 1, `OpenSideWindow` 2, `OpenTab` 3, `SplitWindow` 3, `SwitchTab` 1, `ToggleSlot` 1. A search of `carat/`, `bin/`, `test/`, `bench/`, and `tools/` for each holder followed by `.tabs`, `.buffers`, or `.open_file` finds only `test/adapters_assembly.rb`, no windows use case includes a concern, and every method already reads `@tabs`, `@buffers`, and `@open_file`, so dropping the readers changes no line of behavior. The other files of the directory (`ChangeFolds`, `FocusWindow`, `ScrollWindow`, and the three request records) hold no reader. All 11 holders are kept in an assembly reader, so the shared-holder rule reads each from its `initialize` signature once the directory is in `READERLESS_DIRS`.

### The lint rule's shape (findings 22 to 24)

`holder_problems` keeps its six parameters, since each is an input the rule reads (the holder's name and text, the shared types, the test's text, the assembly's text, whether it is readerless), and becomes three steps: the record loop, the keyword pass of its kind, and the reader pass. `readerless_keyword_problems` and `rbs_keyword_problems` are the two keyword passes, each with the keyword list `holder_problems` reads from `def initialize`.

`ledger_records(holder, assembly)` returns the holder's records in order as `[slot, object]` pairs; `passes?(built, keyword, value)` is the one text check of a construction passing a value for a keyword. The record loop checks each record with `passes?`, so a record of a slot the construction does not pass and a record of an object it does not pass for that slot are one check, reported once as `holder has a ledger record of slot as object, which its construction does not pass`; part a's two messages of that kind go. `ledger_problem` then answers only whether a shared keyword has a record and whether the test reads it, since the record's object is checked by the loop. Alternative: keep both checks and give them the helper; rejected, since the second check could only repeat the first's verdict.

### The replace branch (finding 25)

`record` appends and points the pair's index at the new place; no caller records a pair twice, so the branch that overwrote in place goes, as does the probe row of the guard that existed only to cover it. A later record of a pair would answer `held` in place of the first, which the comment says. Alternative: have `lint` refuse a second record of a pair; rejected as a new rule for a mistake nothing makes.

### The two key-hints and palette helpers (finding 26)

Each file gains one builder, `session_on`, taking the file's text before `session`'s parameters; `session` calls it with the three-line text its many callers expect, the empty-buffer case calls it with an empty text, and `empty_session` goes. Giving `session` itself the text was the other option, rejected since it would change every one of its callers (29 in the palette test) for one empty-buffer case.

### Accessors (finding 27)

`reader_problems` refuses a public `attr_accessor` as it does an `attr_reader`, with the same message; `attr_writer` is no reader and stays outside the rule.

## Edge cases

The windows use cases move windows, tab pages, and cursors and read no line's text, so CRLF, multi-byte text, and trailing blanks do not reach them (the tests say so in a comment); the tests added first cover the last line and an empty buffer for the split, close, only, tab close, tab only, and tab switch paths. An empty range does not arise: their counts are window rows or tab page numbers, whose zero and out-of-range cases the existing tables cover (`E16`, `E475`, `E784`, `E444`).

## Risks / Trade-offs

- The ledger now holds 39 records; it is written once per editor, at start.
- Merging the two passed-object checks changes the wording of a lint message no tool parses.

## Measurements

Main at 8a99bdd against the branch, on one machine, `make build`, `dev-build`, `test-build`, `bench-budget`, and `metrics` on each side, main in a detached worktree, each side run with no other build beside it:

- Re-narrowing rounds: 2 and 2 for `bin/carat.rb` and for the test runner on both sides.
- Analysis time: `bin/carat.rb` 43.4 s on main and 42.1 s on the branch; the test runner 107.0 s on main and 96.8 s on the branch, one run each, so the gap is within the machine's spread rather than a gain.
- Release binary: 7,004,576 bytes on main, 7,006,736 on the branch (2,160 more, 0.03 percent: the 20 records, less the replace branch and the 20 readers).
- Allocations per key: equal in all eight scenarios (lh 25, j 26, insert 25, ddp 57, undo 51, dot-ciw 65, lh-ruby 25, open-ruby 23).
- Time per key, main then branch, in microseconds: lh 102.1 and 106.8, j 537.8 and 543.4, insert 124.9 and 127.7, ddp 940.0 and 911.3, undo 118.0 and 119.0, dot-ciw 114.6 and 115.7, lh-ruby 129.4 and 127.7, open-ruby 166.4 and 218.1; no key path changed (the ledger is written once at start), and open-ruby, which opens a file and starts a fake language server per key, showed the same spread in part a (156.8 and 226.2).
