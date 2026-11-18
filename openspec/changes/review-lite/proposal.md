# Proposal

## Why

A fix round that answers only advisories, with nothing blocking, reruns the whole verification at its head: the checker rebuilds and reruns every fast stage (`rounds` in `.claude/workflows/deliver-change.js`) and the security reviewer reads the branch again (`reviews`), even when the fix changed no code. sign-colors spent rework 2 with 0 blocking and 71,651 output tokens after its first check pass, its security review finding 0 each time; three backlog entries record the same cost (facet-palette, guide-colors, sprint-17-records). The brief is `brief.md`; outside the roadmap of `docs/architecture.md` section 12, the user-approved exception of Sprint 19 in `docs/queue-backlog.md`.

## What Changes

- An advisory-only round (the fix-in-place round of its own, offered when nothing blocked, offering no security finding) whose fix changed only records-only paths since the commit where this start's check, security review, and benchmark passed is settled: the workflow runs no check and no security review and no benchmark at its head, records the skip in the run state as a `settled-round` note naming that commit, and runs only the quality review, scoped to the commits since its pass (`narrowedFrom`, already in place).
- The checker's run start runs a new `sh tools/run_state.sh settled CHANGE COMMIT` first in such a round and returns its line, running the check only when it exits 1; the workflow skips only on a `settled:` line naming that commit and the head.
- `settled` exits 0 only when the tracked tree is clean, COMMIT is an ancestor of HEAD, and every file changed since COMMIT matches `RECORDS_RE` of `tools/rules.sh` (the paths main's merge gates already settle a pass across, `settled_at`), `docs/sprints.tsv` excluded; otherwise exit 1 names the files.
- A blocking finding, a security finding offered in place, or any change outside the records-only paths keeps the full round.
- The guard's read profile allows `settled CHANGE COMMIT`; the checker's Mode run section names the line.
- The package step is told, after a settled round, to name the check and the security review in Testing at the commit where they ran.

Assumptions and narrowing, from the plan notes: the brief's "docs, comments, spec text" is narrowed to the records-only paths main's merge gates accept (`RECORDS_RE`: OpenSpec text, the findings files, the queues, goals, the lane metrics), since the merge gates (`settled_at` in `tools/gates.sh`) refuse a pass after any other change. A round editing README.md, `docs/architecture.md`, a `carat/` comment, or a test keeps the full round; widening that is `review-lite-docs`, which edits `tools/gates.sh` and `tools/rules.sh` and is not part of this change. A security finding offered in place keeps the security review, so a reviewer can confirm it fixed. After a settled round the quality and security passes stand at different commits, so a later merge of a moved main reruns both reviews (`carryFrom`), as before.

Out of scope: `tools/rules.sh` and `tools/gates.sh` are not edited; no file of the feature lane is touched.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the delivery pipeline is described by no spec under `openspec/specs/` (`skip_specs: true`).

## Impact

- `.claude/workflows/deliver-change.js`, `.claude/agents/checker.md`, `tools/run_state.sh`, `tools/agent_guard.sh`, `tools/tools_test.sh`, `docs/goals.md` (the in-place re-review rule).
- README.md: changed, pipeline step 5's sentence that the check and both reviews run again after an in-place round, and the run state paragraph's command list.
- docs/codebase-map.md: changed, the `tools/run_state.sh` and `tools/agent_guard.sh` descriptions; no file is added, moved, or removed.
- CLAUDE.md: unchanged, its Agents line ("fixed in place and re-reviewed") still holds, since the quality review always reruns.
- docs/architecture.md: unchanged, it does not describe the fix rounds.
