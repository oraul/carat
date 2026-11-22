
### TOOLS_RE does not match bench/run.sh, which tools-test now reads
- Location: `tools/rules.sh:98` (`TOOLS_RE`), `tools/tools_test.sh` (the bench/run.sh section).
- Why: `tools-test` now runs `bench/run.sh` over a fake program, but a change to that file alone does not match `TOOLS_RE`, so the scoped check skips `tools-test` for it. The test finds the runner from the tools directory's parent without the `$here/../` spelling that the coverage test scans, since an edit of `tools/rules.sh` goes first and alone, so the gap is left open on purpose.
- Fix: add `bench/run[.]sh$` to `TOOLS_RE` in its own change, then spell the path in the test as `$here/../bench/run.sh` so the coverage test checks it.

### The lh maximum of 100 is four times its figure of 25.0
- Location: `Makefile:25` (`ALLOC_BUDGET`), `bench/run.sh --budget lh`.
- Why: the picker maxima fail a doubled figure, but the cursor scenario's maximum would pass one doubled twice (25.0 to 50.0, even to 99), so a regression of the cursor scenario's allocations goes unseen up to 4 times.
- Fix: lower `ALLOC_BUDGET` to about 40 (1.6 times the figure) in a change that also reads the recorded figures of `lh` over several runs.

### grep is printed by bench-budget without a maximum
- Location: `Makefile` (`bench-budget`, the last `bench/run.sh grep` line), `bench/run.sh`.
- Why: grep allocates 774.4 objects a key in each recent measurement and has no budget, so a doubled figure passes, as the float, finder, and palette figures no longer do.
- Fix: add `grep:1200` to `PICKER_BUDGETS` (about 1.6 times 774.4), run at 20 and 120 keys as the line does now, and drop the printing-only line or keep it for the time per key.

### The finder budget adds about 25 seconds to bench-budget
- Location: `Makefile` (`bench-budget`, `PICKER_BUDGETS`), `bench/keys.rb` (`FINDER_FILES`, 10,000).
- Why: the finder scenario builds a 10,000-file fixture for each run, and `--budget` runs it twice at the development flags, which is the longest part of the stage.
- Fix: run the finder budget at a smaller file count through an environment variable of `bench/keys.rb` and keep the full count for `make bench`, after checking that the allocations per key at that count match the full one.

### An empty PICKER_BUDGETS passes bench-budget without checking a picker
- Location: `bench/run.sh` (`--budgets`), `Makefile` (`PICKER_BUDGETS`).
- Why: `make bench-budget PICKER_BUDGETS=` runs `--budgets ""`, which checks no scenario and exits 0, so an override can turn the gate off without a message.
- Fix: refuse an empty list in `--budgets` with exit 2 and a message, with a `tools/tools_test.sh` case.
