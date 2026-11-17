# Proposal

## Why

The planner's size check splits only a brief of "more than about four separate fixes", so four-part briefs run whole and overrun: rework-guards and backlog-lane-b had four parts each and ran over budget or stopped; #166 (4 fixes) used 3 of 3 rework rounds with a quality first pass of 0; the T1 rows of the last 10 backlog rows used 9 rework rounds over 5 changes. Separately, the user approved verbatim the CLAUDE.md Agents-section wording for parallel lanes drafted in the archived `parallel-lanes-b` design, which no agent may apply without that approval. Delivered as Sprint 12's user-approved exception (T1 pipeline defect, user request), beyond the sprint, in the backlog lane.

## What Changes

- `.claude/agents/planner.md` step 3: a brief of three or more independently testable parts or map areas, or large outside the roadmap, is split into balanced changes; the estimate goes one size up when the last two comparable rows of its lane went over budget; on a stop at the round limit, the planner's `notes` propose the split of what is left. The file stays within its 8,192-byte budget by tightening wording elsewhere with no other rule changed: the intro's "never edit, stage, or commit" becomes "never a tracked file", the description drops its repeat of that rule, step 1 says `quality-*` notes, the sprint grooming drops "(read with `git show`)", and step 5 drops the pointer to `tools/docs_lint.sh`.
- CLAUDE.md: the Agents section's contributor, planner, Sprints, Backlog, and Run state bullets and the Commands section's run state bullet replaced, and a Lanes bullet added, exactly as drafted under "## Proposed CLAUDE.md wording" in `openspec/changes/archive/2026-11-16-parallel-lanes-b/design.md` (30,714 of 30,720 bytes). The split rule is not added to the planner bullet: 6 bytes of headroom do not fit it.
- README.md: the delivery's planner step states the new split rule, the size-up rule, and the round-limit split.
- `tools/tools_test.sh`: a case that planner.md step 3 holds the three rules, and one that the CLAUDE.md Agents section holds the Lanes bullet.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the delivery pipeline has no spec under `openspec/specs/`; `skip_specs: true`.

## Impact

- `.claude/agents/planner.md`, `tools/tools_test.sh`.
- CLAUDE.md: changed, by the user's approval of the drafted wording ("Approve, with planner-split-rule (Recommended)").
- README.md: changed, the planner step of the delivery description.
- docs/architecture.md: unchanged, it describes the editor's architecture and the test machinery, not the delivery workflow's planner.
- docs/codebase-map.md: unchanged, no file is added, moved, or removed.
- `tools/rules.sh`: unchanged.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline defect (T1) the user requested, as Sprint 12's user-approved exception. One reviewable pull request, the two parts kept together as the brief says.

Minor assumptions: "three or more map areas" is written "three or more independently testable parts or map areas" to fit the budget; "the last two comparable rows of its lane" is written "the last two" after "comparable rows of its lane's history" in the same sentence; the draft's Commands-section bullet is applied too, since the draft names it and the user approved the draft verbatim (its removed command descriptions stay in the script's header, which the bullet points to).

## Out of scope

- `docs/goals.md` line 24 still states the older "more than about four separate fixes" size check; the goals charter is rewritten only by the planner when asked, so it is left and named in the summary for the main session.
- The queue edit the brief gives (the pool line out, the exception line under Sprint 12), applied in the package step; any feature-lane file.
