### Escalation triggers have no driven test
- Location: .claude/workflows/deliver-change.js:934, :935, :1326
- Why: only escalate itself is driven in tools/tools_test.sh; the three call sites (no result, self-check mismatch, second blocking quality round) are not exercised, so a removed trigger passes.
- Fix: drive contributor() with a stubbed null result and a self_check mismatch result, and reviews() with two blocking quality results, asserting escalated.

### Critical read in the queue line matches the word anywhere
- Location: .claude/workflows/deliver-change.js:1654
- Why: /critical/ matches the word in the queue line's name or reason, so a non-critical item whose reason says critical notes a spurious "plan: critical value not read", and unlike the planned-path note the note omits the unread text.
- Fix: test for critical inside the parenthesis only (for example /[(,] ?critical\b[^)]*\)/) and append the unread text as the planned-path note does.

### Skipped-plan critical note has no driven test
- Location: .claude/workflows/deliver-change.js:1654
- Why: the skipped-plan note is top-level code no test drives, nor is the planned-path note at :1674.
- Fix: move the skipped-plan critical read into a helper returning the rule or the note and drive it in tools/tools_test.sh calib_js with a read, an unread, and a no-critical queue line.
