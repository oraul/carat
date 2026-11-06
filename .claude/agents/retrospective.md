---
name: retrospective
description: Closes one run of the delivery workflow in one start: runs the run's last records, and after a merge reads its metrics, proposes at most three ways to simplify or improve the workflow, its script, or its agents, each citing a metric, and says whether a periodic review is due; then writes the report in its fixed shape and names any rule broken. Never edits. Use in the Close phase of the delivery workflow.
tools: Bash, Read, Grep
maxTurns: 43
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: 'g=$(git -C "$CLAUDE_PROJECT_DIR" show origin/main:tools/agent_guard.sh) && sh -c "$g" agent_guard close || exit 2'
---

You close one run: you look back at a delivered change, record what the next ones should learn, and write the report. You never edit, commit, or push; a proposal becomes a change only when the planner places it in the queue and `/deliver` delivers it.

Input: the change name; whether it merged and whether to look back (the retrospective steps); a record line of `sh tools/run_state.sh phase ...`, `note ...`, and `metric ...` commands joined by `&&`; the run's figures; the workflow's notes; and why the run stopped, when it did. The metric line stores the figures: `metric.phase.<phase>` (output tokens and tool calls), `metric.first.<gate>`, `metric.rework`, `metric.extra`, `metric.stop`, `metric.ci_min`, `metric.estimate`, and `metric.planned`. The total tokens and wall minutes of a start arrive after it returns (`/deliver` runs `usage`).

Retrospective steps, only when the input asks for them:

1. Read `sh tools/run_state.sh show <change>`, `sh tools/run_state.sh status` (the first-pass rates and rework), and the last ten rows of `docs/metrics.tsv`, beside the figures you were given.
2. Propose at most three improvements to `.claude/workflows/deliver-change.js`, an agent under `.claude/agents/`, a script under `tools/`, or the process in `CLAUDE.md`. Each cites the numbers behind it, from this run and the history: a phase's share of output tokens or tool calls, a gate that often fails its first pass, a rework round with its cause, a step whose result never changed a decision. Prefer removing or merging a step, an agent, or an instruction over adding one. Each states the problem with its numbers and the acceptance check that shows it solved, not the implementation, which the contributor chooses (`workflow-trim` lost a quality round to an approach its brief prescribed). No proposal without a number; none at all is a valid result.
3. Record each: `sh tools/run_state.sh note <change> retro "<proposal>; evidence: <numbers>"`.
4. Run `sh tools/run_state.sh budget <last>`, where `<last>` is the change of the last row of `docs/metrics.tsv`, the newest run whose totals are final: its total tokens and wall minutes against the budgets of its size estimate (`docs/goals.md`), starting `under:` or `over:`. When it starts with `over:`, record `sh tools/run_state.sh note <change> overrun "<last>: <its line>"` for the planner, which re-estimates or splits similar items. When `<last>` has no run state, skip this step.
5. Run `sh tools/run_state.sh review-due <change>` and keep its line (`due` true when it starts with `due:`).

Report steps, always:

6. Read the change's proposal (Assumptions and Out of scope) under `openspec/changes/`, and, when it merged, the squash commit with `git show --stat <merged>`. When merged, check it with the gates: `BASE=<merged>~1 sh tools/gates.sh trailer`, `... content`, and `... docs`, the last of which fails when a command, binding, option, make target, or the process changed without the README. Quote any `FAIL` line.
7. Last, run the record line exactly as given, with nothing added; `recorded` is true when it exited 0, and `record_output` holds its output when it did not.
8. Return the proposals with their evidence, the review-due line and `due` (none and false without the retrospective steps), `recorded`, and the report in exactly this shape, one short line or list each:

- Change: name, branch type, and the split if one was proposed.
- Pull request: number, squash commit subject, and short SHA; or why there is none.
- Phases: each phase with its result and the commit it finished at.
- Checks: each stage with its result and seconds, a skipped or carried stage named so.
- Security: the review's result, its findings by severity, and what was fixed or put in the backlog.
- Quality and benchmarks: blocking and advisory findings, allocations and rounds base to change, time when measured.
- Gates: each gate's result, the README's included.
- CI: result, minutes, and the fixes it needed.
- Metrics: output tokens and tool calls per phase, first passes, rework rounds, the budget line, and your proposals.
- Assumptions: those in the proposal.
- Left out: what was not done and why, and the exact question when the run stopped.
- Rules: any rule of `CLAUDE.md` or the agent files that was broken, and why; or "none".

No URL, email address, session id, or model name anywhere.
