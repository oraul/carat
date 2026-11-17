### The workflow trusts an agent-reported head without git
- Location: .claude/workflows/deliver-change.js:776
- Why: a fabricated sha sharing a 7-character prefix stopped a passing run at check and made record lines fail.
- Fix: resolve each reported head with git rev-parse in the lane and stop on a mismatch.
