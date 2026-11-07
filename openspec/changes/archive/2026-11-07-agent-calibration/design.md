# Design

## Context

`.claude/workflows/deliver-change.js` starts twelve kinds of agent: resume, planner, the scout plan (`areas`), scout, contributor (implement, fix, package, push), checker, quality, security, benchmark, record, merger, and the closing start. Their profiles before this change, as the code and the agent files set them:

| Kind | Tier | Effort |
| --- | --- | --- |
| resume, areas, record | session | low |
| scout | cheap (`model:` line) | session |
| checker, bench, merger | cheap (`model:` line) | low |
| planner, contributor, quality, security, close | session | session |

`measured()` adds each start's output tokens and reported tool calls to a phase key, `verdict()` keeps each gate's first verdict, and `metricLine()` writes them as `metric.phase.KEY=TOKENS/CALLS` and `metric.first.GATE=0|1`; `tools/run_state.sh history` turns them into the `phases` and `first_pass` columns of `docs/metrics.tsv`. Nothing records the profile.

## Decisions

### One table, profiles as words

`CALIBRATION` is a one-line constant like `CALL_CAPS`, so `tools/tools_test.sh` reads it with the same `table` helper: `KIND: 'TIER/EFFORT'`. The tier is `cheap` or `session`, never a model name, because CLAUDE.md allows a model name only on an agent file's `model:` line; the workflow cannot pass a model of its own, so `cheap` means the agent file carries that line, and a test compares the two. The effort is `low` or `session`; `calibrate(kind, opts)` adds `effort` to a start's options unless it is `session`, and stores the profile in `calibrated[kind]`. Every agent start goes through it, so no start sets an effort by hand.

### The first move: the scouts' effort

The rule of the brief is one kind at a time, so the first table equals the profiles above except for one kind. The scouts move from `cheap/session` to `cheap/low`:

- They are the largest mechanical cost left at a default: above 33,000 output tokens on 18 of the last 22 rows, up to 116,958 (`diagnostics-display`), the main part of the 26 to 37 percent plan and scout share.
- Their output is facts read from files and cited by line, the kind of work the other mechanical starts already do at low effort; the checker, the benchmark, and the merger run `cheap/low` with check first passes of 21 in 22 over the same rows.
- A worse result shows directly in the history: the contributor's implement calls and the quality first pass, which a thin pack would raise or lower, are recorded beside the profile.

The record start's move to the cheap tier is left for a later change: it has no agent file, and a tier is named only there.

### Recording beside the figures

`metricLine()` adds `calib.KIND=TIER/EFFORT` for every kind started, and `seed()` reads `metric.calib.*` back without replacing a profile this start already used. `tools/run_state.sh history` appends one column, `calibration`, from `group calib`, after `wall_min` so every column number the tools and tests read stays; rows written before it get `-`, as rows before `pipeline-speed` hold `-` for total tokens. The profile keys are the start kinds, the token keys the phase keys and the verdicts the gates; the reviews, checker, and benchmark kinds are named like their gates.

### Keeping or reverting a move

The rule lives in `docs/goals.md`, which the planner reads every run: a move is kept when, over the next five rows with its profile, the first-pass rates of the gates and the rework rounds are no worse than over the five rows before it; otherwise the planner queues its revert. The security reviewer is never moved, and a test keeps it `session/session`.

## Risks

- Low effort on a cheap tier may change nothing measurable; the history then says so, and the next move goes elsewhere.
- A restart that resumes after an earlier start of the same kind keeps one profile per kind; with one move at a time the two are equal.
