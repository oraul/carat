# Proposal

## Why

The merge and pre-push gates trust the run state's `review.security` line, yet any agent with Bash can write it: `tools/run_state.sh set` takes any key and `review` any kind, so text in an untrusted tree that leads one agent astray can record a review that never ran. The agents meant never to edit carry a bare `Bash`, so the same text can make one run `git push`, `gh pr merge`, or a `gh api` write past the gates, and the contributor has no `tools:` line, so it inherits the pull request merge. These are the periodic security Lows (5) `tools/run_state.sh:441`, (4) `.claude/agents/scout.md:3`, and (4) `.claude/agents/contributor.md:1` at 389c118, item 1 of `docs/queue.md`.

## What Changes

- `tools/run_state.sh set` refuses the keys other commands own the meaning of: `review.*`, `phase.*`, and `stage.*`. `phase` takes only a phase of the list and an optional commit, `review` only a known kind, a `pass` or `blocked` result, and an optional commit; a given commit must exist and is stored at twelve digits.
- The workflow script writes the `phase.*` and `review.*` lines from the results it receives: it builds each command from a schema-checked result (a fixed name, a commit, counts) and one agent that reads nothing else runs them, at the end of the verification rounds and before the report. `periodic-review.js` records the periodic reviews the same way. The nine agents that recorded a phase or a review stop doing so.
- The merger compares: the workflow hands it `RECORDS`, the review results it received, and a new `records` gate in the `merge` group fails when the run state's `review.*` lines differ from them.
- New `tools/agent_guard.sh PROFILE`, a PreToolUse hook in the frontmatter of every agent: the read profile (scout, planner, checker, the two reviewers, benchmark, ci-watcher, reporter, retrospective) refuses git commands that write history, the index, or a remote, every `gh` command, the run state commands only the workflow or the contributor runs, an environment override of the run state script, and any command naming the run state's directory; the contributor profile refuses `git push` (it pushes through `tools/run_state.sh push`, which runs the gates), `gh`, the workflow's records, and an edit of the run state's directory; the merger profile is the read profile plus the fast-forward of `main`, the deletion of the change branch, and the body file the merge gates read.
- The contributor gets an explicit `tools:` list without the merge tool; `.claude/settings.json` denies `gh pr merge` to every session.
- `tools/tools_test.sh` cases for each refusal of the run state, the guard's profiles, and the `records` gate; the docs (README, `CLAUDE.md`, the code map) and the three backlog entries this change fixes.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a tooling and agent change with no change to the editor's behavior; `skip_specs` is set.

## Impact

- New: `tools/agent_guard.sh`.
- Changed: `tools/run_state.sh`, `tools/gates.sh`, `tools/tools_test.sh`, `.claude/workflows/deliver-change.js`, `.claude/workflows/periodic-review.js`, every agent under `.claude/agents/`, `.claude/commands/review.md`, `.claude/settings.json`, `CLAUDE.md`, `README.md`, `docs/codebase-map.md`, `docs/backlog.md`.
- No file under `carat/`, `bin/`, `test/`, or `bench/` changes; the editor binary is unchanged.

This change is outside the roadmap of `docs/architecture.md` section 12: it is a security fix of the delivery pipeline from the periodic review, which `docs/goals.md` puts first.

Out of scope: the two Low findings of the periodic review at 16cdcf7 (a project `.caratrc` unbinding the reserved keys, and its read following a link swapped in after the stat) belong to configuration and file access, not to the delivery agents, and stay queued as `project-config-guards`; the `ci`, `merged`, `pushes`, and `metric.*` keys keep their writers, since the brief names the review and phase records; a sandbox for the agents' shells, which Claude Code's permissions do not offer per agent.

Assumptions recorded instead of asked:

- The workflow script cannot run a command or write a file, so "the workflow writes" means it builds the exact command lines and a plain workflow agent, given no other input, runs them; the guard keeps the agents of the delivery from running the same commands.
- "Narrowed Bash" is a PreToolUse hook per agent file rather than `Bash(...)` patterns in `tools:`, because the agents run many read commands (git, make, grep) that a list of prefixes would either miss or widen to all of git, and a hook is a script with tests; a deny rule in `.claude/settings.json` applies to every agent and the main session alike, so only `gh pr merge`, which no session runs, is denied there.
- The guard reads the command's text: it stops an agent that text in the tree led astray, not one that hides a command behind a variable. The `records` gate and branch protection stand behind it.
- The `records` gate passes with a notice when no `RECORDS` are given, so the delivery of this change, whose running workflow predates it, can merge; a backlog entry makes it refuse once every run passes them.
