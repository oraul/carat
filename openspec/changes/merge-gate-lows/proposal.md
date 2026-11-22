# Proposal

## Why

Four security Lows stay open on the merger's green line, the one command that judges every merge (`.claude/workflows/deliver-change.js`, `mergeLines`): its refs/replace stop pipes `git for-each-ref refs/replace` into `wc -l`, so a failing for-each-ref prints nothing, `wc` says 0, and the stop passes (Low (3)); the comment above the line says fsck stops a planted object, but an object planted before the worktree add and swapped back before the fsck leaves the planted text in the copy while fsck passes (Low (5)); and the copy's `tools/gates.sh`, or any file it reads, can be rewritten on disk after the fsck, which reads only the object store (Low (5)). The fourth heading, fork pull requests sharing the branch name in `tools/open_pr.sh` (Low (5), two entries), is re-verified below.

## What Changes

- The green line's refs/replace stop lists `refs/replace` and `refs/remotes/origin/main` together, newest name first, and passes only when the whole output is origin/main's one line: a for-each-ref that fails prints no such line, and any replace entry sorts before it, so the stop fails closed.
- After the fsck the green line reads origin/main's tree into the copy's index afresh (`git read-tree origin/main`, no stat data) and runs `git diff --quiet` there, which hashes every tracked file of the copy and fails on any whose content is not the blob main's tree names; main's merge gates run only after it, so a text left by a swapped-back object or written after the add, during the fsck included, stops the line.
- `tools/agent_guard.sh` admits the merger's `git read-tree origin/main` in a worktree `tmp/.NAME` (it writes that worktree's index only); its header names the form.
- The comment above `MERGE_GATES` and the docs that describe the green line (README.md delivery step 9, `.claude/agents/merger.md` step 4, `docs/codebase-map.md` area 1) say what each step stops and what stays out of reach.
- `tools/tools_test.sh` cases, each failing before its fix: a failing for-each-ref stops the line before the worktree add; an object swapped back before the fsck stops the line before the merge gates; a gates file rewritten after the fsck stops the line before the merge gates; the guard admits the green line exactly as `mergeLines` builds it.

Re-verified on main: the `tools/open_pr.sh` heading "Fork pull requests sharing the branch name block open_pr.sh (security Low (5))", both entries, no longer holds: `7cbcf29` (#268) made `open` list the branch's pull requests with `isCrossRepository` and keep only same-repository ones, creating ours, or editing and reading back the one left by its number. Its cases ("open_pr: open opens its own pull request beside a fork's on the branch's name" and the three after it) fail with `7cbcf29^`'s script (run here: it refuses "gh pr list printed no count", and against a real `--jq length` it counts the forks and refuses two) and pass at main. This change does not edit `tools/open_pr.sh`. The brief's line numbers had drifted: `tools/open_pr.sh:180` is the `message` arm, the filter is at `:254-264`, and the green line and its comment are at `.claude/workflows/deliver-change.js:738-793`.

Outside the roadmap of `docs/architecture.md` section 12: a T1 pipeline defect of the backlog lane (docs/queue-backlog.md, Sprint 27 item 1).

Out of scope: a process of the same user that outlives the checks and rewrites the copy in the instant between the diff and the shell's read of `gates.sh`, or swaps a tree object between the fsck and the read-tree, still races the line; no shell line closes that window, since the merger runs as the same user (design, Risks). `tools/open_pr.sh wait`, which counts pull requests by the pushed head and refuses more than one, is unchanged. `tools/rules.sh` is not edited.

## Capabilities

### New Capabilities

None: the delivery pipeline has no spec; `skip_specs: true`.

### Modified Capabilities

None.

## Impact

- `.claude/workflows/deliver-change.js` (`mergeLines`, the comment above `MERGE_GATES`), `tools/agent_guard.sh` (`git_form`, header), `tools/tools_test.sh`, `.claude/agents/merger.md` (step 4), `docs/codebase-map.md` (area 1).
- README.md: delivery step 9 names the fail-closed refs/replace stop and the content check of the copy after the fsck.
- CLAUDE.md: unchanged, its Agents and Commands lines describe the merger and the merge gates at a level this fix leaves true.
- docs/architecture.md: unchanged, section 10 does not describe the green line's steps.
