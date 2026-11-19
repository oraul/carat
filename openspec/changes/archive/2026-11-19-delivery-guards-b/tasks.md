## 1. Implementation

- [x] 1.1 Refuse a placeholder or non-lane head on a done contributor result, note, escalate, and restart once (`.claude/workflows/deliver-change.js` HEAD12, safeText, headProblem, laneHead, contributor; proved by the tools-test cases of 2.1)

## 2. Tests and docs

- [x] 2.1 Tools-test cases running the real `contributor()`: a placeholder and a wrong head refused, restarted once, noted, escalated; a second refusal stops; an unread lane head; a hostile head kept out of the queued line (`tools/tools_test.sh`)
- [x] 2.2 Name the refused head as an escalation trigger in `docs/goals.md` (checked by `make docs-lint`)

## 3. Review fixes

- [x] 3.1 Extract `recordStart(command, label)`, the one start of the record profile, called by `flush` and `laneHead` (`.claude/workflows/deliver-change.js`; the tools-test cases running `contributor()` and the flush cases pass through it)
- [x] 3.2 Keep the lane-head prompt in the tools-test stub and assert it runs `git -C tmp/.lane-c rev-parse --short=12 HEAD` (`tools/tools_test.sh`)
- [x] 3.3 Queue a closable `note <change> head-unread "contributor <mode> start <n>: lane head not read"` beside the report note when the lane head is unread, asserted by the unread tools-test case (`.claude/workflows/deliver-change.js`, `tools/tools_test.sh`)
