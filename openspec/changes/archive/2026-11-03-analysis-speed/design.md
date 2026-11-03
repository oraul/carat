# Design

## Context

See proposal.md for the motivation. Spinel infers types across the whole program and types each method's parameters once for that program; an inline RBS signature seeds a parameter but does not stop an `untyped` argument at a call site from widening it, and a pinned `Data` member (`ChangeRecord @inserted: Array[String]`) widens the same way when an `untyped` value is stored in it. Every test program under `test/` (except `json.rb`, `lint.rb`, and the smoke test) requires `carat.rb`, so each is a whole-program analysis of the library plus its own code, and the call sites in the test are part of that program. `Carat::Testing#table` yields each row's input from an array literal of mixed values, so a row's values are `untyped`.

`SP_TIMING=1` (the same as `spinel --timing`) makes Spinel print each phase's milliseconds to standard error, and `rounds=` for `analysis_fixpoint` and `analysis_renarrow`. `spinel --emit-rbs` writes the inferred signatures with `# spinel: widened to untyped (slow path)` on each widened entry; `make types` prints it for `bin/carat.rb`.

## Goals / Non-Goals

**Goals:**

- The analysis of each test program costs what the library costs and no more: no library signature widens in a test program that is not widened in `bin/carat.rb` because of the test's own call sites.
- A widening that slows the analysis fails `make check` and CI visibly, cheaply, and the same way on every machine.

**Non-Goals:**

- Reducing the cost of analysing the library itself, or the number of compile roots; the measurements below show that is where most of the test time goes, and it is recorded in the backlog.
- Changing any code under `carat/`, `bin/`, or `bench/`, or any snapshot.

## Reproduction at 80314d8

Measured with `SP_TIMING=1 spinel ROOT --strict-require -I ROOT_DIR -c` on a four-core machine with nothing else running, two runs per root interleaved with this change, then once more with the C compile at `-O1` (the level `spin test` uses) for `cc_total`:

| Phase | `bin/carat.rb` before | after | `test/domain_buffer.rb` before | after |
| --- | --- | --- | --- | --- |
| `analysis` | 22.8, 24.0, 24.4 s | 23.9, 25.2, 22.3 s | 39.7, 36.8, 36.3 s | 24.5, 22.0, 23.2 s |
| `analysis_fixpoint` | 11.6 to 13.1 s, 4 rounds | 10.7 to 13.4 s, 4 rounds | 25.6 to 28.8 s, 4 rounds | 10.9 to 12.6 s, 4 rounds |
| `analysis_renarrow` | 1.5 to 1.9 s, 2 rounds | 1.3 to 1.8 s, 2 rounds | 5.9 to 6.6 s, 5 rounds | 1.6 s, 2 rounds |
| `an_cls_facts` | 6.7 to 7.1 s | 6.7 to 7.2 s | 6.4 s | 6.5 to 6.9 s |
| `codegen_program` | 24.6 to 26.1 s | 24.1 to 27.0 s | 38.0 to 41.6 s | 23.8 to 26.4 s |
| `cc_total` at `-O1` | 14.0 s | 14.1 s | 21.1 s | 20.6 s |

`bin/carat.rb` is the same program before and after (no file it compiles changed; its emitted signatures are identical), so its rows show the run-to-run spread, about 10 percent. The rounds do not vary between runs.

`spinel --emit-rbs` of `bin/carat.rb` at 80314d8 has 316 widened entries; `ChangeRecord`, `Transaction#record_at`, `Buffer#splice`, `Buffer#set_lines`, and `LineSplice` are typed in it (`splice: (Integer, Integer, Array[String]) -> nil`). The same output for `test/domain_buffer.rb` adds, in the library:

- `ChangeRecord @inserted: untyped`
- `Buffer#initialize: (untyped, String, String)`, `Buffer#set_lines: (Integer, Integer, untyped)`, `Buffer#splice: (Integer, Integer, untyped)`
- `LineSplice.apply`, `grow`, and `spread` with an `untyped` source array
- `Position @row: untyped`, `@col: untyped`, `Position#to_a: () -> Array[untyped]`
- `UndoTree#note_line: (Transaction) -> untyped`

Each traces to a call in the test: `D::Buffer.new(input[0], ...)`, `b.set_lines(input[1], input[2], input[3])`, `b.set_lines(0, 2, [])` (an empty literal, typed `Array[Integer]`, which merged with `Array[String]` is `untyped`), and `pos(input[1], input[2])`. With this change the program's emitted library signatures equal `bin/carat.rb`'s; its 321 widened entries are the 316 of the library plus the test's own top-level functions and `Carat::Testing`.

A survey of every compile root at 80314d8 (analysis under three parallel jobs, then the emitted signatures of each compared with `bin/carat.rb`'s) found the pattern in four more programs, all fixed here:

| Program | Library entries widened by the test | Rounds before | After |
| --- | --- | --- | --- |
| `test/domain_selection.rb` | `Buffer#initialize`, `Position @row` and `@col`, `UndoTree#note_line` | fixpoint 5, re-narrowing 2 | 4, 2 |
| `test/domain_grammar.rb` | `CommandGrammar#accept`, `accept_visual`, and `remember` taking `untyped` codes | fixpoint 4, re-narrowing 3 | 4, 2 |
| `test/adapters_frame_presenter.rb` | `Buffer#initialize` | fixpoint 5, re-narrowing 2 | 4, 2 |
| `test/use_cases_actions.rb` | `ExCommand @name` | 4, 2 | 4, 2 |

After the change all five analyse in 22 to 26 seconds with 4 fixpoint and 2 re-narrowing rounds, like every other program. The other programs analysed in 24 to 29 seconds under that load; three that first looked slow (`domain_plugin_manifest`, `domain_registers`, `domain_line_cache`, 31 to 38 seconds) took 22.6 to 23.5 seconds when measured again without other work running, with 2 rounds, so their first numbers were load.

## Decisions

### The widening is fixed where it starts, in the tests

The request expected the change records' `Array[untyped]` list to be the source, and proposed a records class or parallel typed arrays. The measurements rule that out: the list is read through `Transaction#record_at`, which declares `ChangeRecord`, and in `bin/carat.rb`, where no caller passes an `untyped` line array, the records, the splice, and `LineSplice` are all typed. The `untyped` comes into the program at the test's calls, so that is where it is stopped: table values are copied or converted before they reach the library, with the same `strings` helper `test/domain_edits.rb` already uses for `LineSplice.apply` (and an `ints` sibling for key codes), `to_i` for rows and columns, and `to_s` for names and single lines. The assertions and their output do not change, so the snapshots stay as they are.

Alternatives considered:

- Typed copies at the library's boundary (`Buffer#set_lines` and `Buffer#initialize` copying into a fresh `Array[String]`): it would protect the splice from any caller, but it costs a copy on every linewise edit and of every file's lines on open in the editor, which has no `untyped` caller, to pay for the tests'; and the boundary method's own parameter would still widen. Rejected.
- A records class for the change records: changes nothing the analysis sees, since the accessor already declares the type. Not done.

### The return-type widenings of the library are left alone

`bin/carat.rb` has 316 widened entries of its own, nearly all return types of procedures that end in a loop or return a mixed value (`UndoTree#push`, `trim`, `drop`, `compact`, `Buffer#revert`, `reapply`, `begin_history`, `shift_signs`, `Dispatcher#call`, `split`, `measure`, `MainLoop#run`, the frame and screen presenters' painters, the plugin host's procedures), the port methods whose doubles return other types, and the JSON and configuration readers, which are `untyped` by nature. They are as old as the code, they cost no extra round (`bin/carat.rb` needs 2), and an experiment ending the `UndoTree`, `Buffer`, and `Dispatcher` ones in `nil` measured 25.1 seconds against 26.9 for the unchanged tree in back-to-back runs, inside the 10 percent spread. They are listed here and left.

### The budget counts re-narrowing rounds, on two roots

`make analysis-budget` runs `tools/analysis_budget.sh` with `ANALYSIS_ROUNDS` (default 2), `ANALYSIS_MS` (default 45000), and `ANALYSIS_ROOTS` (default `bin/carat.rb test/domain_buffer.rb`). The script compiles each root with `spinel $(spin flags) ROOT -c -o build/analysis/NAME.c` and `SP_TIMING=1`, in parallel, reads `analysis ms=`, `analysis_fixpoint rounds=`, and `analysis_renarrow rounds=` from each report, prints them, fails when a root's re-narrowing rounds exceed the budget or the root does not compile, and warns above the milliseconds.

- Rounds, not time, fail the target: for the same sources and compiler the round counts are the same on every run and every machine, while the time moved by 10 percent between runs here and will differ more on a CI runner. The regression this change fixes moved re-narrowing from 2 rounds to 5 (and the grammar test's widening to 3), so a budget of 2, the value of every root after this change, catches both. Time still warns above 45 seconds, about twice the fixed value, where the regression sat at 36 to 40 seconds locally and a slower runner would put it higher.
- Two roots, not one: `bin/carat.rb` needed 2 rounds before the fix too, so a budget on it alone would not have caught the regression; `test/domain_buffer.rb` covers the whole library and is where the regression showed. Compiled in parallel, the two cost about 27 seconds of wall time on four cores (measured: 27.2 s for `make analysis-budget`), under the minute the request allows. Compiling every root would catch a widening in any test program, but costs as much as the analysis half of `make test`; the convention in `CLAUDE.md` covers the other programs.
- `-c` stops after writing C, so no C compiler time is spent; the C files go to `build/analysis/`, which git ignores.
- The script is plain POSIX `sh` beside `tools/noruby/ruby`, so the `Makefile` stays a map that calls it, as `bench/run.sh` is called for the allocation budget.

Running the script on the 80314d8 sources with `test/domain_grammar.rb` added reported `bin/carat.rb` at 2 rounds, `test/domain_buffer.rb` at 5, and `test/domain_grammar.rb` at 3, and exited 1; on this change's sources it reports 2 for both default roots and exits 0.

## Benchmark

No file `bench/keys.rb` compiles changed, and the benchmark built from 80314d8 and from this change are byte-identical binaries, so any difference is the machine. `bench/run.sh` (the script behind `make bench`) ran the scenarios on both, interleaved and pinned to one core: three rounds of all five, then five more of `insert` and `dd`, whose spread was widest. Medians of the key handling and rendering time per key:

| Scenario | 80314d8 | This change | Difference | Allocations per key, both |
| --- | --- | --- | --- | --- |
| `lh` (3 runs) | 26.4 us | 24.2 us | -8 percent | 26.0 |
| `j` (3 runs) | 135.7 us | 137.3 us | +1 percent | 27.0 |
| `insert` (8 runs) | 28.0 us | 29.9 us | +7 percent | 34.0 |
| `dd` (8 runs) | 72.6 us | 67.7 us | -7 percent | 35.0 |
| `undo` (3 runs) | 43.4 us | 42.5 us | -2 percent | 51.0 |

Every scenario is within 10 percent; single runs of the same binary ranged from 27.1 to 34.8 us for `insert` and from 45.9 to 84.4 us for `dd`. The cursor scenario allocates 26 objects per key, under the budget of 100.

## Risks / Trade-offs

- [A test program other than `test/domain_buffer.rb` starts widening the library] → The budget does not see it; the convention in `CLAUDE.md` and `docs/architecture.md` section 10 states the rule, and the backlog's entry on compile roots would bring every test under one budget once the programs are fewer.
- [A legitimate change raises the rounds to 3] → The target fails, which asks the author to compare `spinel --emit-rbs` of the root with `main`; if the extra round is not a widening, `ANALYSIS_ROUNDS` is raised in that change with the reason recorded.
- [Spinel's report format changes with a compiler bump] → The script fails with "the report has no re-narrowing rounds" rather than passing silently, and the bump's pull request updates it.

## Migration Plan

None: no data, configuration, or editor behavior changes. Rolling back is reverting the squash commit.
