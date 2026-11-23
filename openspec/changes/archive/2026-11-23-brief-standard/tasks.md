# Tasks

## 1. The standard and the tool

- [x] 1.1 Write `docs/brief-standard.md` (the fields in order, the queue item labels, the check)
- [x] 1.2 Add `tools/brief.sh` with `build` and `check`; prove it in `tools/tools_test.sh` (brief: build cases, and the check refusing a brief without WHERE, one with no path:line, one with no failing-before test in ACCEPTED WHEN, two changes, an empty field)
- [x] 1.3 Point the planner's queue item shape at the standard (`.claude/agents/planner.md`, within its byte budget)

## 2. Docs

- [x] 2.1 Update README.md and the tools area of `docs/codebase-map.md`

## Quality review

- [x] 3.1 `check_brief` held an unused awk function; removed, fixed
- [x] 3.2 The out-of-order field and the missing run state refusals had no case; added to `tools/tools_test.sh`, fixed
