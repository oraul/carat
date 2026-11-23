### Stale first-tab scenarios of the buffer-tabs spec
- Location: `openspec/specs/buffer-tabs/spec.md`, the scenarios "One file has the row under 2" and "The open file's modified mark follows its name under 2".
- Why: they read row 0 as "  • a.txt" and "  • a.txt ●", a dot before the name the tabs dropped with the file icon, so the spec disagrees with "A tab is a name and a mark, with no icon" and the shipped row.
- Fix: a delta spec modifying the requirement "Buffer tabs take the top row from two buffers or two tab pages" with "  a.txt" and "  a.txt ●", and the test that names them.
### The tab bar re-scans the list for a shared name on every width
- Location: `carat/adapters/tab_bar.rb`, `shares_name?` called by `tab_width` and `paint_tab`.
- Why: each tab width compares its name with every other file tab, and the overflow loops call `span_width` repeatedly, so a row with many listed files costs about the cube of the tab count in byte compares per frame (most end on the length test); no allocation, but it grows with the buffer list.
- Fix: compute once per paint a count of tabs per last segment, or cache a shared flag on `BufferList` flushed on open, close, and rename, and read it in `tab_width`.
### A delivery's package step rewrote the feature queue to an older plan (tab-name-parent planner)

- Location: `docs/queue-feature.md` at 69e59b6 (#330, explorer-rows), against 092d282; `build/plan/tab-focus-mark/queue-feature.md`.
- Why: explorer-rows ran with no plan directory of its own, and its squash commit set the feature queue to the tab-focus-mark plan less its own line: `## Sprint 32` became `## Sprint 31`, the full `ui-groups-c` item and Pool 1 to 3 (`sidebar-head-tidy`, `tab-float-mark`, `explorer-look`) and the sprint-32 decisions were lost; only a later planner's diff against history caught it.
- Fix: the backlog lane's `plan-apply-stale` (Pool 17): plan-apply refuses a lane queue from a plan directory not the change's own, or one whose base blob differs from the lane's HEAD; a tools-test case with a stale plan fails before.

### Overrun notes repeat within a run (explorer-rows retro 14)

- Location: `tools/run_state.sh` budget notes; explorer-rows notes 8, 11, 12.
- Why: 3 output overrun notes (205,733, 257,796, 263,364 against medium's 200,000) in one run changed no decision while the total stayed under 1.2M; 4 of the last 6 feature rows exceed 200,000 output.
- Fix: near the backlog lane's `budget-recalibrate` (Pool 18): at most one overrun note per budget per run; accepted when a tools-test case with two passes over the output budget records one note.

### Medium estimate too small for a change crossing plugin API, presenter, domain, and plugin (explorer-rows retro 15)

- Location: the planner's size check (`.claude/agents/planner.md` step 3); explorer-rows 49 files, 280,557 output, implement 193,556 (69 percent), 113 of 203 calls, rework 2.
- Why: a host request plus its renderer and its plugin consumer ran 1,412,911 total against medium's 1.2M.
- Fix: near `split-at-placement` (Pool 18): size by the layers a change crosses; a brief adding a host request, a presenter path, and a plugin consumer is split or sized large; accepted when the next such brief's parts stay under 200,000 output each.

### A self-check mismatch recorded at stage none (explorer-rows notes 3, 4)

- Location: `.claude/workflows/deliver-change.js` self-check comparison; explorer-rows notes 3, 4 at 2f2a0f8e5692.
- Why: the check is said to have failed "at stage none", so an escalation is recorded with no failing stage, which `docs/goals.md` Escalation counts only for a failed stage of the contributor's own tree.
- Fix: near `check-escape-lane-build` (Pool 15): no escalation without a named failing stage; accepted when a tools-test case with a refusal and no stage records no escalation.
