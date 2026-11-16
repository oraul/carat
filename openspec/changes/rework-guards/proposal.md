# Proposal

## Why

Rework is the delivery pipeline's largest cost (T1 pipeline defect, user request, estimated medium): over the last 41 deliveries the quality review failed the first pass 14 times, a run with a fix round averaging 1.18M total tokens and 87 minutes against 0.86M and 62 minutes clean. Of 119 recorded quality-blocking findings about 20% were a behavior change without its test and 20 to 35% documents left out of date, both mechanical; and three post-push defects each turned a nearly finished change into a redelivery: a resume past the push that found a new blocking review could only stop (review-coverage, backlog-lane-a), a change edited the merge gate's own rules that main's gate still judged it by (backlog-lane-a), and a recurring change reused a merged name (spinel-bump replaying pull request 95).

## What Changes

- The contributor's pre-review self-check, in `.claude/agents/contributor.md` and in the workflow's implement and fix prompts: before returning, every behavior the change adds or alters has a test that proves it, every document describing that behavior (README.md, docs/architecture.md, CLAUDE.md, docs/codebase-map.md, docs/compatibility.md, docs/actions.md) is updated, and the diff is compared against the brief, anything extra named.
- A resume past the push that finds a blocking quality or security review at the pushed head runs one fix round instead of stopping: the contributor fixes it, the check and both reviews run again at the new head, the security review over the whole branch diff (never narrowed in that round), and the contributor pushes once more with `sh tools/run_state.sh push <change> --review-fix`. The push needs a recorded push and a head other than it, counts `review_fixes`, and is allowed once per run; a second such round, in the same start or a later one, is refused and the run stops. A failed check or benchmark on a resume still stops. `tools/gates.sh` `pushes` allows one push plus one per CI fix plus at most one review fix.
- A planner rule in `.claude/agents/planner.md`: a change that edits the merge gate's own rules (`tools/rules.sh` RECORDS_RE and the other patterns main's `tools/gates.sh merge` reads) lands that rule edit first as its own small change, since main's merge gate judges a branch by main's rules.
- `sh tools/run_state.sh init CHANGE BRANCH` refuses a delivery (a branch other than `main`) whose change name already merged, by a lane history row or a run state with `merged` set, telling it to take a unique name such as `spinel-bump-<7-char commit>`; an unmerged run state of the name still resumes. Sprint and review run states, created at `main`, are untouched.
- CLAUDE.md's Agents section names the contributor's self-check, the review fix, the planner's gate-rules rule, and the merged-name refusal.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `.claude/workflows/deliver-change.js`, `tools/run_state.sh`, `tools/gates.sh`, `tools/tools_test.sh`, `.claude/agents/contributor.md`, `.claude/agents/planner.md`.
- `tools/rules.sh`: TOOLS_RE names CLAUDE.md, since a tools-test case now reads its Agents section; this is the ci_scope pattern, not one the merge gate reads.
- CLAUDE.md: changed, the Agents section names the four rules; other lines shortened to stay within its budget.
- README.md: changed, the pipeline section names the contributor's self-check, the planner's gate-rules rule, the review fix push of a resume past the push, and the refusal of a merged change name.
- docs/architecture.md: unchanged, it describes the editor's architecture and the test machinery, not the delivery workflow's fix rounds or run state guards.
- docs/codebase-map.md: unchanged, no file is added, moved, or removed.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline defect (T1) the user requested, Sprint 10's second pipeline change by the user's approved exception; it absorbs the pool items `resume-fix-round` and `merged-name-guard`. One reviewable pull request.

Minor assumptions: a "review" that earns the resume fix round is the quality or security review, not the check or the benchmark, which keep stopping; the review-fix push needs a recorded push and a head other than it, the only condition `run_state.sh` can check, since the reviews pass again before it; the merged-name refusal lives in `init`, which the deliver workflow's resume start runs, and applies only to a branch other than `main`, so the sprint and review run states (`init NAME main`, then `merged` set) keep resuming; this run never uses the review-fix push itself, since main's `tools/gates.sh` judges it; the budgets of CLAUDE.md and the two agent files are kept by trimming wording, not raised.

## Out of scope

- Changing `tools/docs_lint.sh` sprint limits, the queue budgets, or any file budget.
- Any change to how the first pass of the reviews runs, or to the CI fix path.
