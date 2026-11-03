# Design

## Context

`tools/run_state.sh` is the one writer of `build/pipeline/<change>.json` (delivery-pipeline, "One writer for run state and stage logs"), but nothing limits who calls it: `set` writes any key (line 441), `phase` any name, and `review` any kind, at `HEAD`. `tools/gates.sh` trusts `review.security` before the push and the merge and `stage.*` before the push. The workflow keeps its own copy of the phases and reviews in memory (`deliver-change.js` lines 189 to 312) from the schema-checked results of the agents, and the file copy comes from the agents themselves: three reviewers write `review`, six agents write `phase`. Every no-edit agent has a bare `Bash`, and the contributor has no `tools:` line.

## Goals and non-goals

Goals: only the workflow's results become `phase.*` and `review.*` lines; no agent of the delivery but the contributor's script pushes and none but the merger's tool merges; the merger refuses a run state that differs from what the workflow received; each rule that is a script has a test.

Non-goals: a sandbox (an agent that hides a command from its own text is not stopped by a text guard); the other keys (`ci`, `merged`, `pushes`, `metric.*`, `note.*`), whose writers stay; the configuration findings at 16cdcf7 (queued as `project-config-guards`).

## Decisions

### `set` refuses the owned keys; `phase` and `review` validate

`set` refuses `review.*`, `phase.*`, and `stage.*`: each has a command that gives it its meaning (`review`, `phase`, `stage` and `check`), and `stage.*` is trusted by the pre-push gate exactly as `review.security` is. `phase NAME [COMMIT]` takes a name of `PHASES` (now without `report`, which nothing reads: `status` only names a change that is not merged, and the report runs on every run); `review KIND RESULT SUMMARY [COMMIT]` takes a kind of `security quality bench periodic-security periodic-quality`. A given commit must be hexadecimal and name a commit, and is stored as its twelve-digit form, like `HEAD` was. The optional commit keeps the old calls working, so agents of a session that started before this change still record.

Alternative: a secret the workflow holds and `run_state.sh` checks. Rejected: the script has no randomness and no file access (a resumed run must replay), so the secret would pass through an agent and a file that every agent can read.

### The workflow records through one plain agent

The workflow queues each record as a command line it builds itself: `sh tools/run_state.sh phase <change> <name> <commit>` and `... review <change> <kind> pass|blocked "<counts>" <commit>`, where the change matches `[a-z0-9-]+`, the commit `[0-9a-f]{7,40}`, the kind and name are literals of the script, and the counts are integers. `flush()` hands the queued lines, joined with `&&`, to one agent without an agent type and with nothing else to read, and stops the run when it fails. It runs at the end of `verify()` (the push gate needs `review.security` in the file) and before the report, so a run spends two to three small agent calls on it; a run killed between flushes repeats the unrecorded phases on resume, as a run killed mid-phase does today. `periodic-review.js` flushes its two results once. The reviewers keep writing `note.*` lines (their findings for the planner), the checker keeps `check` (which runs the stages it records), and the benchmark keeps `metrics`.

### The merger compares through a `records` gate

The workflow builds `RECORDS="security:pass:<commit> quality:pass:<commit> bench:pass:<commit>"` from its state and gives the merger the gate command line. `gate_records` reads each `review.KIND` and fails when its result or its commit (both resolved with `git rev-parse`) differs. A run state edited around the guard after the record (a review moved to a later commit, a blocked result turned into a pass) then stops the merge. A resumed run took its state from the file, so for it the gate compares the file with itself; the guard covers that run's agents. Without `RECORDS` the gate prints a notice and passes, only so that this change's own delivery, run by the workflow it replaces, can merge (backlog entry).

### A guard per agent, as a PreToolUse hook

Every agent file gets a `hooks:` block whose PreToolUse hook runs `sh "$CLAUDE_PROJECT_DIR/tools/agent_guard.sh" <profile>` on `Bash` (and, for the contributor, on `Edit`, `Write`, and `NotebookEdit`). The script reads the hook's JSON, takes the first `"command"` (or `"file_path"`) string and undoes its JSON escapes, and exits 2 with the reason on stderr to refuse. Rules, by profile:

- read (scout, planner, checker, quality-reviewer, security-reviewer, benchmark, ci-watcher, reporter, retrospective): no `git` command that writes the history, the index, or a remote (`push commit add merge rebase reset tag cherry-pick revert am stash restore rm mv clean`, after any global options such as `-C dir`); no `gh` command (the agents use the GitHub tools); no `run_state.sh` `phase`, `review`, `stage`, `push`, `history`, or `init`; no `MAKE=`, `STAGES=`, `RUN_STATE_DIR=`, `STAGE_DIR=`, or `METRICS_FILE=` beside `run_state.sh` (a fake `make` would record passed stages); no command naming the run state's directory.
- merger: the read rules, but `git merge` (the fast-forward of `main`), `git push origin --delete <type>/<name>` (a Conventional Branch, never `main`), and the body file `build/pipeline/<change>.body.md` are allowed.
- contributor: no `git push` (it pushes through `tools/run_state.sh push`, which runs the gates first), no `gh`, no `run_state.sh` `phase`, `review`, `stage`, or `init`, no environment override, and no Bash command or file edit naming the run state's directory.
- an unknown profile refuses everything.

Alternative: `Bash(...)` patterns. A subagent's `tools:` line lists tools, and the prefixes the agents need (git reads with options, make targets, shell pipelines for logs) would either miss commands or allow all of `git`. A deny list in `.claude/settings.json` applies to every session, the contributor and the merger included, so it holds only `Bash(gh pr merge:*)`, which no session runs (the merger merges through the GitHub tool).

The guard reads text, so a variable or an `eval` hides a command from it; it is the narrowing the backlog entry asked for, with the `records` gate and branch protection behind it. A false refusal costs the agent one retry with the Grep or Read tool, which the message names.

### The contributor's tools

`tools: Read, Edit, Write, Glob, Grep, Bash, Skill, mcp__github__create_pull_request, mcp__github__pull_request_read, mcp__github__update_pull_request`: what its modes use, without the merge tool, as the merger and the CI watcher already name their GitHub tools.

## Risks

- Agent definitions are read when a session starts, so this change's own delivery runs the old agents: they record as before (the optional commit keeps their calls valid) and the old merger passes no `RECORDS` (the gate's notice). If a session loads the new definitions mid-run, the reviewers stop recording while the old workflow does not record either, and the push refuses until `/deliver` resumes with the new script, which reruns the reviews and records them.
- The guard can refuse a legitimate read whose text looks like a write (a `grep` for `git push` through Bash); the agent retries with the Grep tool.
- A change that edits `tools/agent_guard.sh` runs its later phases under the edited guard; the security review reads that diff like any other.
