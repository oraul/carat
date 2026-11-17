### The benchmark phase measures records and docs-only runs that build nothing it measures
- Location: `.claude/workflows/deliver-change.js` (the benchmark phase's start condition)
- Why: sprint-12-records bench took 6,460 of 36,282 output tokens (17.8%) and 10 of 79 tool calls, stopped at its cap; over the three sprint records runs bench took 15,099 of 127,367 output tokens (11.9%) and 23 of 222 calls, each finding allocations and rounds equal to main (bench first pass 3 of 3), so its result changed no decision (sprint-12-records retro note 4).
- Fix: record the bench phase as skipped, with its reason and 0 tool calls, on a run touching no file under `carat/`, `bin/`, `bench/`, or the Makefile; accepted when the next records or docs-only run shows it skipped and a change touching those paths is still measured.

### Groom output needs a hand edit and draws the records runs' quality advisories
- Location: `tools/run_state.sh` (`groom`, `folded_backlog` near :1851)
- Why: sprint-12-records hand-edited `docs/backlog.md:6714` after groom because docs-lint refused a backticked path to a findings file groom had just removed (sprint-10-records the same, 2 of the last 3 records runs); all 3 of its 3 quality advisories were groom output (headings folded twice from a double append at :6775 and :6787; no blank line before folded headings at :6751, :6765, :6861); reviews took 9,975 of 36,282 output tokens (27.5%) (sprint-12-records retro note 5).
- Fix: accepted when a tools-test case shows groom leaving no backticked path to a removed findings file, no repeated folded heading, and a blank line before each folded heading, and the next records run applies groom with no hand edit and no advisory on groom output.
