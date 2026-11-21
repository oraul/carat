# Proposal

## Why

A workflow start cannot continue a finished agent, so every failed check sent back to the contributor is a fresh fix start of about 97K tokens, and 7 of the last 12 failed checks were stages the implement session could have run itself (docs-lint budgets, gates on a stale README). Today the rules forbid it: the contributor's card says other agents own the checks, `tools/agent_guard.sh` refuses `run_state.sh check` from the contributor, and the workflow backs the checker's check with `phase.check` only, so a pass the contributor's check recorded at the head would be rerun anyway. The user decided on 2026-11-21 that implement, the quality tasks and fixes, and the checks and their fixes belong in the one running contributor. This runs in the backlog lane outside Sprint 25's 3 by the user-approved exception. It is outside the roadmap of `docs/architecture.md` section 12: it changes the delivery tooling, not the editor.

## What Changes

- `tools/agent_guard.sh` lets the contributor run `sh tools/run_state.sh check CHANGE`, with no commit argument; a COMMIT, `metric`, `settled`, and `moved` stay refused.
- `tools/run_state.sh check CHANGE COMMIT` refuses a COMMIT that is neither the recorded `phase.check` nor HEAD, and its header and comments say the workflow accepts a pass whoever started the check, only from the runner's own stage records.
- `tools/lane_facts.sh` prints a `machinery` line: `yes` when the diff from the merge base with origin/main touches `tools/`, the `Makefile`, or `test/runner/`, `no` otherwise, `unknown` without a merge base.
- `deliver-change.js`: the contributor's schema gains `check` (the verdict line of its last check, verbatim) and `check_runs`; an implement or fix result whose `check` says every stage passed at its returned head, over a lane whose `machinery` is `no`, makes the checker's check back that head, so the stages passed there are skipped and the checker still runs spent, bench, the metric line, and moved; any other claim leaves the backed commit at `phase.check`, and a false claim only costs the stage run. A `self_fix` metric sums each start's check runs after its first. `CALL_CAPS` implement 90 to 110 and fix 40 to 60; the self-check prompt and the card's rule 2 ask for the check.
- `.claude/agents/contributor.md`: maxTurns 140 to 170 (the caps formula), line 15 and card rule 2 reworded, implement step 5 and fix pointing at a new Checking section of `docs/contributor-notes.md`, within the file's budget.
- `openspec/config.yaml` apply guidance orders the session: tasks, quality tasks and fixes, commit, docs-lint and gates, merge-main if behind, the check and its fixes, return.
- `.claude/agents/checker.md`, CLAUDE.md (Git workflow and Agents), README.md (pipeline steps 3 to 5), `docs/goals.md`, and `docs/codebase-map.md` follow; `docs/queue-backlog.md` gets the Sprint 25 exception line.

Out of scope: `tools/rules.sh` (untouched); the handling of security findings (security-advisories-record's); the feature lane's files, `docs/metrics-feature.tsv` included, so `self_fix` stays a run-state metric with no history column (recorded in the findings file); the guard is read from main, so this delivery runs the old path and its tools-test proves the new one.

Assumptions:

- The brief asks both that the checker back the contributor's passing head and that a COMMIT other than `phase.check` be refused; the head the checker backs is never `phase.check` yet, so `check` accepts a COMMIT equal to `phase.check` or to HEAD. At HEAD it skips only the stage records the runner wrote there; any other commit, which could carry records forward, is refused.
- `self_fix` is the count of check runs after the first in each implement or fix start, as the contributor reports it in `check_runs`; a re-wait on exit 3 is no run.
- The brief's council paths under the session scratchpad are paraphrased in `brief.md`, which keeps no session path.

## Capabilities

### New Capabilities

None: the change alters the delivery tooling, not editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `tools/agent_guard.sh`, `tools/run_state.sh`, `tools/lane_facts.sh`, `tools/tools_test.sh`, `.claude/workflows/deliver-change.js`, `.claude/agents/contributor.md`, `.claude/agents/checker.md`, `docs/contributor-notes.md`, `openspec/config.yaml`, `docs/goals.md`, `docs/queue-backlog.md`.
- CLAUDE.md: the Git workflow line names the check's stages, push counts unchanged; Agents says the contributor checks itself and the checker confirms from its passing head.
- README.md: the pipeline steps 3 to 5 follow.
- docs/codebase-map.md: area 1's entries of `lane_facts.sh`, `run_state.sh`, `agent_guard.sh`, and `deliver-change.js` follow.
- docs/architecture.md: unchanged, section 10 names no phase of the delivery workflow; no layer, port, or roadmap item changes.
