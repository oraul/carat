# Proposal

## Why

Three security Lows and two parsing defects of the delivery pipeline remain open: a late-finding note anyone can write reaches the backlog verbatim through `history`, the open-pr job keeps a token in its checkout, `open_pr.sh wait` takes the highest pull request on the pushed commit so a fork's pull request on the same commit wins, `staleRed` misreads a check name holding a comma (`spin (ubuntu, 4)`), and the merger returns checks in two shapes with no stated source for the workflow field.

## What Changes

- `tools/run_state.sh note CHANGE late-finding TEXT` records the note only once the run's `merged` commit is on main, stamped with that commit (`late-finding MERGED TEXT`); `history` appends a late finding to the findings file only when its stamp is the run's merged commit and its text has the shape the workflow's `noteText` writes (its characters, at most 400), so a note written before the merge, or in any other form, stays out.
- The workflow records its late findings only for a merged run (`if (state.merged) recordLate()`), since the note now refuses an unmerged run and the close's record line is one `&&` chain.
- `.github/workflows/open-pr.yml`: the `Check out main` step sets `persist-credentials: false`; the repository is public, so the read step's anonymous fetch of the branch still works.
- `tools/open_pr.sh wait` records a pull request only when exactly one `refs/pull/N/head` is the pushed head, or the one the run state already records is among them; two or more others are refused, none recorded.
- `staleRed` reads a check as the first field (the workflow file), the last two (status and conclusion), and the name between them, commas included.
- `.claude/agents/merger.md` step 2 and the merger schema's `checks` description: one form, `workflow, name, status, conclusion`, for every result, pending included, the workflow being the `path` of the head's workflow run whose check suite holds the check run, read once with `actions_list` before a red or pending return; a green return, which needs no file, gives `-`.
- `tools/tools_test.sh` cases prove each.

Outside the roadmap of `docs/architecture.md` section 12: a T1 pipeline defect of the backlog lane (docs/queue-backlog.md, Sprint 12 item 1).

Out of scope: an integrity proof of the run state against a process that edits the file directly after the merge, a same-repository test of a pull request over GitHub's API (the contributor holds no GitHub tool), the merger's call cap, and `tools/rules.sh` (not edited).

## Capabilities

### New Capabilities

None: the delivery pipeline has no spec; `skip_specs: true`.

### Modified Capabilities

None.

## Impact

- `tools/run_state.sh` (`add_note`, `late_findings`, header), `tools/open_pr.sh` (`wait`, header), `.github/workflows/open-pr.yml`, `.claude/workflows/deliver-change.js` (`staleRed`, `recordLate` call, merger schema), `.claude/agents/merger.md`, `tools/tools_test.sh`, `docs/codebase-map.md` (area 1 lines of `run_state.sh` and `open_pr.sh`).
- CLAUDE.md: unchanged, its Agents and Commands lines describe the merger, `wait`, and `history` at a level these fixes leave true.
- README.md: unchanged, no command or user-facing behavior changes.
- docs/architecture.md: unchanged, section 10 does not describe late findings, the open-pr checkout, or the checks list.
