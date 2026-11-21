# Proposal

## Why

Agents are asked to remember `git rev-parse --short=12 HEAD` and copy the hash into their result by hand. In #265 a contributor returned a placeholder head over committed work: the workflow refused it, escalated every later contributor start of the run to the session's model, and restarted a start that had nothing left to redo. The user asked on 2026-11-21 for a script that reads the correct data, so the pipeline has a harness instead of a rule to remember. This runs in the backlog lane outside Sprint 25's 3 by the user-approved exception and folds the backlog's `head-form-restart` (Pool 11). It is outside the roadmap of `docs/architecture.md` section 12: it changes the delivery tooling, not the editor.

## What Changes

- Add `tools/lane_facts.sh CHANGE`, which prints a lane's facts as `key value` lines read from git and the check log, never typed: `head` (the lane's `git rev-parse --short=12 HEAD`), `branch`, `base` (the merge base with origin/main, 12 characters), `pushed` (yes when origin's branch is the head), `dirty` (the count of uncommitted paths), and the last check's verdict and commit (`check`, `check_at`). It runs from the main checkout or the lane, and exits 2 on a bad name or a missing lane.
- `deliver-change.js` reads the lane's facts through that script (`laneHead`, one record start, after every contributor start, a continued one included) and uses the head it reads. A done result whose head differs from a committed lane head only in form (a placeholder, a short or full hash of it, or upper case) is noted `head-form` and taken from git: no refusal, no escalation, no restart. A lane with uncommitted work, or an unknown dirty count, keeps today's refusal of such a head; a well-formed head that is not the lane's is refused as today; an unread lane keeps today's `head-unread` path.
- The contributor's rules card (agent file and workflow copy), the head restart text, the resume prompt, and the contributor's schema point at the `head` line of `tools/lane_facts.sh` instead of a hand-copied `git rev-parse`.
- `tools/agent_guard.sh` lets every profile run `sh tools/lane_facts.sh CHANGE`, which writes nothing (the merger only from the main checkout, never the branch's copy after a cd into a worktree), so the card's instruction is not refused once main has it.
- `tools/tools_test.sh` proves the script's lines on a test repository with a lane worktree and the workflow's handling over a stubbed agent.
- `docs/goals.md` (the escalation paragraph), `docs/codebase-map.md` area 1, and CLAUDE.md Commands name the script and the form rule.
- The Sprint 25 exception line and the removal of `head-form-restart` from Pool 11 come through this change's plan, which the package step's `plan-apply` copies over `docs/queue-backlog.md`.

Out of scope: `tools/rules.sh` (untouched); the feature lane's files; the merger's and the quality reviewer's `git rev-parse --short=12 origin/main` and main `HEAD` reads, which name main, not a lane, so the lane script does not describe them; the shared `HEAD` schema of the checker, reviewers, and merger.

Assumptions:

- A placeholder is a reported head with a character that is not a hex digit, or an empty one; a short form is a hex prefix of seven or more characters of the lane's full hash; a hex value that is neither the lane's nor a prefix of it names another commit and stays refused.
- "A lane with uncommitted work still refuses as today" keeps today's refusal of a malformed head when the lane is dirty; a correct head over a dirty lane is accepted as today, the check refusing the tree.

## Capabilities

### New Capabilities

None: the change alters the delivery tooling, not editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `tools/lane_facts.sh` (new), `.claude/workflows/deliver-change.js`, `tools/agent_guard.sh`, `tools/tools_test.sh`, `.claude/agents/contributor.md`, `docs/goals.md`.
- CLAUDE.md: the Commands section names `tools/lane_facts.sh`, the bytes taken from duplicate text so it stays within its budget.
- README.md: the "Rules are checked, not remembered" paragraph names `tools/lane_facts.sh` and the head-form rule.
- docs/codebase-map.md: area 1 lists `tools/lane_facts.sh`, and the entries of `deliver-change.js`, `agent_guard.sh`, and `tools_test.sh` follow.
- docs/architecture.md: unchanged, section 10 names no head check; no layer, port, or roadmap item changes.
