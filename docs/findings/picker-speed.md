
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
### lh-winbar and n stay out of the default scenario list at bench/run.sh:69 (picker-speed plan, rest of sprint-26 sweep quality note 31)
- Location: `bench/run.sh:69`; scenarios at `bench/keys.rb:123` (`lh-winbar`), `:147` (`n`).
- Why: the sprint-26 heading names four scenarios the default list omits; picker-speed's item covers `lh-float` and `palette` only, so `lh-winbar` and `n` still run only when named and no budget covers them.
- Fix: run both by default with a budget; accepted when `make bench` runs them and `bench-budget` fails on a doubled figure.

### The check-pass output-token note fires in runs that end under the total budget (ui-groups retro note 3)
- Location: `tools/run_state.sh` `spent` (`spent_line`, `OUTPUT_SHARE`); `.claude/workflows/deliver-change.js` (the check-pass note).
- Why: output through the check passed 200,000 in 7 of the last 10 feature rows (ui-groups 396,622) while only 3 of 10 totals went over 1.2M, so the note changes no decision.
- Fix: accepted when over the next 5 feature runs every check-pass overrun note matches a final total over the medium budget, or only the final total-token budget line remains.

### The merge phase output varies 14 times at a constant call count with a green first CI (ui-groups retro note 4, evidence for backlog Pool 15 merge-wait-bound)
- Location: `.claude/workflows/deliver-change.js` (merge phase), `.claude/agents/merger.md`.
- Why: ui-groups merge 95,842/13, 18.0 percent of 532,429 output tokens, ci_wait_calls 6, CI 13.1 min, 0 CI fixes; last 10 feature merges 6,972 to 57,187 at 12 to 14 calls; drivers-lsp-lows 78,615/13.
- Fix: accepted when 5 consecutive runs with a first-pass green CI keep the merge phase under 20,000 output tokens.

### A scout reads the half a delivery-time split moved out (sprint-close-lows retro note 2)
- Location: `.claude/workflows/deliver-change.js` (scout question and locations from the queue item).
- Why: sprint-close-lows scout 55,071/23, 13.7 percent of 402,224 output tokens, the highest of the last 10 backlog rows; 5 of its 9 locations and all 4 Gaps lay in merge-path-lows, already split off.
- Fix: accepted when, after a delivery-time split, every scout location and Gap lies in the delivered part.

### The size check runs only in the delivery planner, so an oversized queue item costs a delivery-time split (sprint-close-lows retro note 3)
- Location: `.claude/agents/planner.md` (sprint mode step 2), `docs/goals.md` (size check).
- Why: sprint-close-lows was queued with 10 headings in 3 areas and split at delivery; its plan 35,540/13, 8.8 percent of output tokens, the highest of the last 10 backlog rows (others 7,690 to 20,300).
- Fix: accepted when the sprint queue holds no item over about four headings and no delivery of the next sprint records a Split decision, its plan under 20,300 output tokens.
