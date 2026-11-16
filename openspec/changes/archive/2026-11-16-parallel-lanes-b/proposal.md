# Proposal

## Why

A feature delivery and a backlog delivery still cannot run at once (T1 pipeline, user request, estimated medium, Sprint 10's approved exception): parallel-lanes (#156) separated the two lanes' records, but both deliveries still share the main checkout's one working tree, so a second delivery would check out its branch under the first. This change delivers the rest of the brief: a worktree per delivery, merging a moved main into a running delivery, and the README's rule for starting two deliveries at once.

## What Changes

- `sh tools/run_state.sh lane-open CHANGE BRANCH`, new: makes the change's own git worktree of the main checkout at `tmp/.lane-CHANGE` (hidden, since `spin` reads every visible directory as source) on its branch: the local branch, else origin's, else a new one from `origin/main`. It keeps the worktree on a resume, replaces one standing on another branch (a replaced run), and links the main checkout's toolchain (`tmp/.spinel`, `tmp/.toolchain`), compile cache (`build/spinel-cache`), run states, stage logs, and plans (`build/pipeline`, `build/stages`, `build/plan`) into it, so the run state stays the main checkout's and nothing is built twice.
- `sh tools/run_state.sh lane-close CHANGE`, new: removes the worktree, its links first so no removal reaches their targets; nothing when none stands. The merger runs it after the merge, before it deletes the local branch.
- `sh tools/run_state.sh merge-main CHANGE`, new: in the worktree, fetches origin's main and, when it moved, merges it into the branch (never a rebase or a force-push) with a commit carrying the trailer; the appended records (`docs/metrics-*.tsv`, `docs/findings/*.md`, `docs/sprints.tsv`) merge by git's union driver, given by an attributes file of that merge alone, so both sides' rows are kept; any other conflict aborts the merge and names its files.
- The delivery workflow: the resume start runs `lane-open` from the main checkout, which stays on main, and reads `trusted`, `plan-needed`, and the head in the worktree; every agent start's introduction names the worktree and tells the agent to run every command there; each implement or fix start first runs `merge-main`, so the checks and reviews cover the merge; the merger's green line enters the worktree, so its merge gates are a worktree under the lane's own `tmp/` and two deliveries never share a merge-gates path.
- `tools/agent_guard.sh`: the contributor runs `merge-main`, the merger `lane-close`.
- The contributor's push mode names `merge-main` for a conflict with main; the merger's step 7 runs `lane-close`.
- README.md: each delivery's worktree, the shared toolchain and records, the rule that the main session may start one feature-lane and one backlog-lane delivery at once, never two of one lane, and a `sprint-N-records` change beside no other, and `merge-main`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the delivery pipeline has no spec under `openspec/specs/`; `skip_specs: true`.

## Impact

- `tools/run_state.sh`, `tools/agent_guard.sh`, `tools/tools_test.sh`, `.claude/workflows/deliver-change.js`, `.claude/agents/contributor.md`, `.claude/agents/merger.md`.
- `tools/rules.sh`: unchanged; the new cases read no repository path beyond what TOOLS_RE holds (an earlier draft's `.gitattributes` would have needed a TOOLS_RE line, so the union rule lives in `merge-main` instead).
- CLAUDE.md: unchanged, since an agent's instruction does not authorize an edit of CLAUDE.md; the brief's part 3 asks to bring its Agents section's Sprints, Backlog, and Run state bullets up to date with #156 and to add the two-lanes rule, so the proposed wording, which fits the 30 KiB budget, is in design.md for the user to approve and apply.
- README.md: changed, as above, and step 9 says the merge gates run in the delivery's worktree.
- docs/architecture.md: unchanged, it describes the editor's architecture and the test machinery, not the delivery workflow.
- docs/codebase-map.md: changed, area 1's `tools/run_state.sh` entry names the lane commands; no file is added, moved, or removed.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline change (T1) the user requested, by Sprint 10's approved exception. One reviewable pull request, kept whole as the brief says.

Minor assumptions: the worktree is `tmp/.lane-CHANGE` rather than the brief's example `tmp/.lanes/CHANGE`, since the agent guard already admits `cd`, `git -C`, and `make -C` into a worktree `tmp/.NAME` of the project, so no guard path rule changes; "the merge gates keep their own worktree (tmp/.merge-gates)" is kept literally, under each lane's `tmp/`; a stopped run keeps its worktree, and a run is replaced when `lane-open` finds the change's worktree on another branch; the compile cache is `build/spinel-cache` (the Makefile's `SPINEL_CACHE_DIR`).

## Out of scope

- The queue edits the brief lists, applied by this change's package step from the planner's `build/plan/parallel-lanes-b/queue-backlog.md`, and the `planner-split-rule` item itself (queued, not delivered).
- Any change to `tools/rules.sh`, the merge gates themselves, the check clone, or the budgets; the sprint-planning and periodic-review workflows, which run no delivery worktree.
