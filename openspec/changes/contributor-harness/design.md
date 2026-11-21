# Design

## Context

The workflow has no shell, so it reads the lane's head in a start of the record profile (`recordStart`), which runs one command. Today that command is `git -C tmp/.lane-<change> rev-parse --short=12 HEAD`, and `headProblem` refuses any reported head that is not twelve lowercase hex characters or not that lane head; each refusal escalates the run (`escalate`) and restarts the start once.

## Decisions

- One script, `tools/lane_facts.sh`, is the source of a lane's facts for agents and the workflow alike. It finds the main checkout from `git rev-parse --git-common-dir`, as `run_state.sh main_top` does, so it gives the same lines in the main checkout and in the lane. It reads the check verdict from the last line of `build/stages/<change>/check.log`, the line `run_state.sh check` ends with, and prints `none` for anything else, so a forged or partial log never yields a commit that is not hex.
- The record start runs `sh tools/lane_facts.sh <change>` from the repository root instead of the bare git command; `parseLaneFacts` keeps only a twelve-character hex head and a whole-number dirty count, `-1` when unknown. One start still reads both facts, so the cost stays one record start.
- `headForm(reported, lane)` is pure and decides the form-only case: the lane's head read, its dirty count exactly 0, and the reported head either containing a non-hex character (a placeholder, after lower-casing), empty, or a lower-cased hex string of seven or more characters that is a prefix of the lane head or that the lane head is a prefix of. Then the result's head is replaced by the lane's before `resultProblems`, a `head-form` note is queued (closable, the reported text through `safeText`), and nothing escalates or restarts. Every other case reaches `headProblem` unchanged, so a dirty lane and a foreign commit refuse as before.
- A continued start (cap reached) also reads the lane head and keeps it as the run's head when read, else the reported well-formed one as before.
- The guard gets a `tools/lane_facts.sh` form for every profile taking exactly one change name, since the script writes nothing.

## Risks

- The script runs in the record start from the main checkout, whose `tools/` is main's copy until this change merges; until then the workflow on main still runs the old command, and after the merge both agree.
- `pushed` reads the remote-tracking ref as the last fetch left it; it does not fetch, so it costs no network and writes nothing.
