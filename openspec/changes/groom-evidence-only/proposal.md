# Proposal

## Why

`groom` (`tools/run_state.sh`) removes backlog entries by the proofs of `groom.txt`. Two of them remove an entry without evidence that its problem was addressed: `stale HEADING` (groom-stale-prune, #264) only for its age, which at the present pace marked 1,322 of 1,772 entries in the sprint-24 plan, real bugs included, and `closed COMMIT HEADING` whenever a later commit touches a file the entry names, whether or not it fixed the entry. A path absent at HEAD (`gone`) does not show either that the problem went with it. The user's rule of 2026-11-21: an entry leaves the backlog only with evidence, never because it is old. The brief is `brief.md`; outside the roadmap of `docs/architecture.md` section 12, a pipeline defect run first in the backlog lane by the user-approved exception.

## What Changes

- `groom` refuses a `stale` or a `closed` line of `groom.txt` by name, so a plan holding one writes nothing and names the line, as any failed proof does.
- `groom` accepts a `gone` line only as `gone HEADING -- REASON`, the reason after the line's last ` -- ` saying why the problem no longer applies, and refuses one without a reason or with a blank one before any other proof; the path proof (every named path the history held absent at HEAD) stays.
- `backlog-oldest` and backlog-pick's groomed set (`ENTRY_AWK`'s `load_groomed`) read a gone line's heading before its ` -- REASON`, so an entry a gone line removes is still left out.
- Removed, used only by `stale` and `closed`: `entry_added`, `stale_mark`, `named_history`, `named_since`, `sprint_next`, `PRUNE_ALL_SPRINT` and the whole-backlog scan it switched on. `backlog-oldest` stays, `PRUNE_COUNT` entries (50), since `tools/agent_guard.sh` (the planner's read profile) and the sprint planner's prompt read it: the planner checks those entries against HEAD for evidence (`fixed` in the sprint, `gone` with a reason).
- Kept unchanged: `listed`, `fixed`, `merged`, and `duplicate`.
- The `tools/run_state.sh` header and comments, `.claude/agents/planner.md` step 1, CLAUDE.md's Agents Backlog line, README.md pipeline step 11, `docs/codebase-map.md` (`tools/run_state.sh`), and `.claude/workflows/sprint-planning.js` (the prompt line naming the oldest entries) name the evidence kinds and no pruning by age.
- `tools/tools_test.sh`: the `stale` and `closed` cases become refusals, the gone cases carry reasons, a gone line without a reason and one with a blank reason are refused, the whole-backlog scan cases are removed, and the sprint plan's accepted lines (listed, fixed, merged, duplicate, gone with a reason) still apply.
- `docs/queue-backlog.md`: the Sprint 25 heading carries the user-approved exception line for this change, from the plan's queue, applied at the package step by `plan-apply`.

Out of scope: no backlog entry is removed; `tools/rules.sh` and `tools/agent_guard.sh` are not edited; no file of the feature lane is touched.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the delivery pipeline is described by no spec under `openspec/specs/` (`skip_specs: true`).

## Impact

- `tools/run_state.sh` (`groom`, `backlog_oldest`, `ENTRY_AWK`, the header, the pruning constant, five helpers removed), `tools/tools_test.sh`, `.claude/agents/planner.md`, `.claude/workflows/sprint-planning.js`.
- README.md: changed, the grooming sentence of pipeline step 11.
- CLAUDE.md: changed, the Backlog line names the evidence kinds.
- docs/codebase-map.md: changed, the `backlog-oldest` and `groom` descriptions of `tools/run_state.sh`; no file is added, moved, or removed.
- docs/architecture.md: unchanged, it names none of groom's kinds.
