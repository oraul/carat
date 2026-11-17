
### A change touching no carat/, bench/, or test/ file still runs the benchmark phase
- Location: .claude/workflows/deliver-change.js, the benchmark phase (sprint-10-records retro note 4)
- Why: the records-only sprint-10-records spent 4,848 output tokens and 6 calls on the benchmark (9.3% of 52,240 output tokens, 7% of 86 calls) plus a base and a change build, while its check scoped the metrics stage out; bench first pass 117 of 118 over the history, allocations and rounds unchanged on every key.
- Fix: skip the benchmark phase, recording the skip, when the committed diff touches no file under carat/, bench/, test/, or the Makefile; accepted when the next records change shows a recorded skip and no skipped change later shows an allocation or rounds difference.

### The ProcessPort row still names capture(argv)
- Location: docs/architecture.md:213
- Why: the port takes capture(argv, environment) since #160, so the binding architecture table misstates the port.
- Fix: name the environment argument in the row.
