# Backlog: tools/ci_wait.sh

## The CI wait's header and the merger's step 2 carry run history

- Where: the header of `tools/ci_wait.sh` (lines 6 to 8 at `run-budgets`) and step 2 of `.claude/agents/merger.md` (line 20), which the merger reads on every start. Quality advisory of `run-budgets`, raised twice.
- Why it matters: they record every run since `guard-hardening` (3,476 to 6,841 output tokens), which goes stale, duplicates the archived design, and costs input tokens on every merger start.
- Fix outline: keep only the 180, 240, 300 schedule and the harness behavior in both, the history in the archived design.
- Also: .claude/agents/merger.md
- Category: pipeline
- Added: 2026-11-06
