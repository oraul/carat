# Proposal

## Why

The sprint close keeps six gaps (the sprint-planning half of the queue's `sprint-close-lows` item, split by the planner): the security continuation drops a file its second start names left in another spelling (`./a.rb` for `a.rb`), so a partial review is recorded as complete (security Low (5)); a sprint quality review at its cap gets no second start, so it is recorded `partial` on every large sprint; the skeptic's prompt asks it to return only the security findings it disputes, so one both reviewers missed may never be returned or recorded, nor count as blocking; the quality reviewer spends its calls tracing points that belong to the security reviewer; the sprint's records change is delivered, and its queue applied, past a blocking sprint security finding or the plan's `security_first`; and a `/sprint` rerun records every security finding again.

## What Changes

- `.claude/workflows/sprint-planning.js`:
  - `pathKey` and `stillLeft`: a continuation's files left are matched to the first start's by a normalized key (quotes and blanks trimmed, a leading `./`, doubled slashes, a trailing slash or `:line[:column]` dropped, a prefix such as a worktree or absolute path matched at a path boundary), the first start's spelling kept; `mergeSecurity` uses it.
  - The quality review gets the security review's continuation: `qualityDone`, `mergeQuality`, and one `reviewContinued` helper starting either reviewer once more over the files its first start left, or over the whole diff when it returned no result, its starts counted for the overrun notes.
  - The skeptic returns each security finding both reviewers missed in `security_missed`, findings of the reviewer's schema; the prompt asks for them; the workflow records each as a `security` note `missed by both: <finding>` with the skeptic's notes, and counts a High or Medium at confidence 8 or above among the blocking findings of the review record, the report, and the records gate.
  - `recordsHeld`: the records change is not started while the sprint has a blocking security finding or the plan names `security_first`; the report's Records line says it is held and why, and to resume it with `/deliver` once the fix merged.
- `tools/run_state.sh` `add_note`: a `security` note whose text is already recorded for the change is not recorded again (the precedent of `quality-advisory`), so a `/sprint` rerun adds no duplicate.
- `.claude/agents/quality-reviewer.md`: a possible security matter is named in one advisory line, unexamined, and left to the security reviewer; the skeptic returns what both missed in `security_missed`; to stay within the file's 8192-byte budget, step 4 drops "not only the first" and the sprint and skeptic modes say the same in fewer words (its step 6 already names the continuation at the cap).
- `.claude/commands/sprint.md`: a held records change is resumed only after its security fix merged.
- `tools/tools_test.sh` cases for each heading, each failing before its fix.

Outside the roadmap of `docs/architecture.md` section 12: a T1 pipeline defect of the backlog lane (docs/queue-backlog.md, Sprint 28 item 1), narrowed by the planner's split.

Out of scope: the merge path's four headings (the periodic review's security Lows at 186ddfb in `deliver-change.js`, `tools/agent_guard.sh`, and `tools/spec_validate.sh`; the moved-main merge; the package step's prose edit; the budget line), queued as `merge-path-lows`; `deliver-change.js` and `tools/agent_guard.sh` are not edited. `tools/rules.sh` is not edited. The security notes' runner start (`sprint: notes`), already recorded by pipeline-lows-a, is unchanged.

Minor assumptions: a continuation's file that matches none of the first start's files is dropped, as before, since the first start reviewed it by its own account; a blocking finding the skeptic disputes still holds the records change, since a dispute is a note for the planner, not a resolution; a held records change leaves the plan waiting in `build/plan/`, so `review-due` stays not due until `/deliver sprint-N-records` applies it.

## Capabilities

### New Capabilities

None: the delivery pipeline has no spec; `skip_specs: true`.

### Modified Capabilities

None.

## Impact

- `.claude/workflows/sprint-planning.js`, `tools/run_state.sh` (`add_note`), `.claude/agents/quality-reviewer.md`, `.claude/commands/sprint.md`, `tools/tools_test.sh`, `docs/codebase-map.md` (area 1).
- README.md: delivery step 11 names the continuation of both sprint reviews, the security findings both missed, and the held records change.
- CLAUDE.md: unchanged, its Sprints line describes the sprint review at a level these fixes leave true.
- docs/architecture.md: unchanged, section 10 does not describe the sprint review's starts or the records change.
