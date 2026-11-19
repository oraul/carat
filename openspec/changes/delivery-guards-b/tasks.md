## 1. Implementation

- [ ] 1.1 Refuse a placeholder or non-lane head on a done contributor result, note, escalate, and restart once (`.claude/workflows/deliver-change.js` HEAD12, safeText, headProblem, laneHead, contributor; proved by the tools-test cases of 2.1)

## 2. Tests and docs

- [ ] 2.1 Tools-test cases running the real `contributor()`: a placeholder and a wrong head refused, restarted once, noted, escalated; a second refusal stops; an unread lane head; a hostile head kept out of the queued line (`tools/tools_test.sh`)
- [ ] 2.2 Name the refused head as an escalation trigger in `docs/goals.md` (checked by `make docs-lint`)
