### Escalation triggers have no driven test
- Location: .claude/workflows/deliver-change.js:934, :935, :1326
- Why: only escalate itself is driven in tools/tools_test.sh; the three call sites (no result, self-check mismatch, second blocking quality round) are not exercised, so a removed trigger passes.
- Fix: drive contributor() with a stubbed null result and a self_check mismatch result, and reviews() with two blocking quality results, asserting escalated.
