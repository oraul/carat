# Design

## Context

`deliver-change.js` starts `resume` (fixed cap 12) and `record` (cap 3) with no `agentType`, so they run as the default agent on the session's model at low effort (`CALIBRATION` `session/low`) and no hook guards them. `sprint-planning.js` starts `due`, `notes`, `skeptic notes`, `record`, and `records-merged` the same way, the notes starts as `quality-reviewer`. Each of these runs commands the workflow wrote or a fixed recipe. The guard (`tools/agent_guard.sh`) knows the profiles `read`, `close`, `merger`, and `contributor`, every hook running main's copy.

## Goals / Non-Goals

**Goals:**

- The bookkeeping starts run on the cheapest tier at low effort, under a guard profile that allows the commands their prompts name and nothing to write.
- No remote branch delete by the merger; the local cleanup stays.
- A squash commit whose last line is not exactly the trailer is refused where the merge phase accepts it.

**Non-Goals:**

- Any judgment start's tier; rewriting history on main.

## Decisions

- One agent file, `runner`, for all those starts, `tools: Bash`, `model:` the cheapest tier's alias like the checker's; its `maxTurns` is the larger of the resume and record caps at a large estimate plus the margin, which tools-test computes.
- `CALIBRATION.resume` and `.record` become `agent/low`: the tier is the agent file's, the effort stays low. tools-test's pair list gains `runner:resume` and `runner:record`, so the tier keeps matching the file's `model:` line.
- The `runner` profile: the shared forms (reads, `cd` to the project or a worktree, `git fetch -q origin`, `git -C tmp/.lane-X rev-parse`, `echo`), `make doctor` and `make toolchain` with no option or variable but `-s`, and `tools/run_state.sh` verbs: the reads `show get trusted plan-needed review-due`, `lane-open` and `init` as CHANGE BRANCH (BRANCH a Conventional Branch or `main`), and the records `phase review metric ci-stages note` and `set CHANGE records skip`, the note text being data as for `read`. It refuses `tools/gates.sh` and every write target, since it has no DIR. The records it writes are the ones the workflow already wrote through an unguarded start, which the merger's records gate compares with the script's.
- sprint-planning's due, record, and records-merged starts set `agentType: 'runner'` and keep `effort: 'low'`; that file has no calibration table.
- The notes and skeptic notes starts stay on the quality reviewer's record mode under the `read` profile, which records `note` (never a late, held, or unpushed finding) and the reads, and no `review`, `phase`, `metric`, `ci-stages`, `init`, or `lane-open`: their commands carry finding text quoting reviewed code, which could steer a low-effort start, and the `runner` profile records reviews (`review_due` reads a sweep's) and phases of any change. This departs from the user's answer listing the notes starts for the runner, by the change's security review (Medium, confidence 5); the two starts are short, so the tier saving lost is small. The `runner` profile's `note` refuses the late, held, and unpushed finding kinds as `read`'s does (security Low, confidence 4).
- The merger's step 7 runs `set merged && lane-close && checkout main && merge --ff-only && branch -D` as one call; the guard's `git push` branch for the merger and its `--delete` form go, the merger refusing every `git push`.
- The trailer check is in `merged_at` of `tools/run_state.sh`, which both `set CHANGE merged` and the `merged` word of `phase` call: after the commit is resolved, the last non-blank line of `git log -1 --format=%B` must equal the trailer, else it dies naming the line. The hook's comparison already refuses a stray quote (two guard cases prove it), so the gap was a merge that did not pass through the hook, and the run state is the next point that sees every merge.

## Risks / Trade-offs

- Until this change is on main the hooks run main's guard, which has no `runner` profile; the workflow that hands starts to `runner` lands in the same squash commit, so no run sees one without the other.
- A refused merged commit leaves the merge done and the run stopped at the record; the merger reports the refusal as its problem, as for any other refusal of `set merged`.
- A cheaper tier may miss steps in the resume recipe; the keep rule (next 5 rows) decides.
