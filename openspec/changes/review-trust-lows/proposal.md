# Proposal

## Why

A check, security, or quality pass stays current across a later commit that touches only the records-only paths (`RECORDS_RE`, `tools/rules.sh`), since no check reads them. `docs/goals.md` is one of those paths, yet agents act on its rules (the tiers, the budgets, the critical-change routing), so a pass followed by an edit of it is treated as current although nothing reviewed the edit: the security Low "A security review stays current after later instruction-file commits". This is the first part of the queue item `review-trust-lows`, split at its start as the queue line asks: the `tools/gates.sh:112` list, alone. Outside the roadmap of `docs/architecture.md` section 12: a T1 pipeline defect.

## What Changes

- `tools/gates.sh` names the instruction records, `INSTRUCTION_RECORDS_RE` (`docs/goals.md`), and `settled_at` refuses a records-only diff that touches one, so the `security`, `stages`, `passed`, and `records` gates report a pass before such a commit as stale ("code changed since"). The backlog, findings, metrics, queue, OpenSpec, and groom sprint-row commits still keep a pass current.
- `tools/run_state.sh` keeps the same line, and the two readers that mirror the merge gates follow it: `settled` (`settled_round`, review-lite) no longer settles a round that changed `docs/goals.md`, and `reviewed-edits` (`reviewed_edits`) names `docs/goals.md` when it changed since the security review, so the package step restores it instead of failing at the push. A tools-test case keeps the two lines equal.
- Tests in `tools/tools_test.sh`: the security and stages gates stale after a `docs/goals.md` commit and current after a backlog and findings commit; `settled` refusing a `docs/goals.md` round; `reviewed-edits` naming it; the two lines equal.
- Docs: `README.md` and `docs/codebase-map.md` (area 1) say a pass stands after a records-only diff but one touching `docs/goals.md`.

## Capabilities

### New Capabilities

None: the change alters the delivery gates, no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Out of scope

- No `tools/rules.sh` edit: `RECORDS_RE` keeps `docs/goals.md`, so CI's scope and the checker's scope still treat it as documentation; only the settle of a pass excludes it.
- The other ten headings of the queue item, queued as `review-trust-lows-b` and `review-trust-lows-c`.
- `plan-apply` still copies a planned `goals.md` in the package step; such a copy now makes the security pass stale, so `reviewed-edits` names it. Recorded in the change's findings.
- No file of the feature lane.

## Impact

- README.md: changed, the sentence on a review standing after a records-only diff.
- CLAUDE.md: unchanged, it does not describe which records a pass settles across.
- docs/architecture.md: unchanged, section 10 does not name the records-only paths or the settle.
- docs/codebase-map.md: changed, area 1's `tools/run_state.sh` and `tools/gates.sh` entries.
- docs/compatibility.md, docs/actions.md: unchanged, no Neovim command and no action.
