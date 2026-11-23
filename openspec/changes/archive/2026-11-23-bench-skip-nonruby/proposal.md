# Proposal

## Why

The Benchmark phase compares allocations and Spinel rounds with main's figures, but a change that edits no Ruby code cannot change either. `sprint-review-coverage` edited no `carat/` file and still lost a fix round to allocation noise from `grep` (685.3 against 685.0, three reruns at 685.0). The user decided on 2026-11-23 to skip the benchmark when a change does not change any Ruby code.

## What Changes

- Add a `ruby` line to `tools/lane_facts.sh`: `yes` when a path changed from the merge base to HEAD lies under `carat/`, `bin/`, `bench/`, `config/`, or `tools/spinel/` or is `carat.rb`, `Makefile`, or `tools/metrics.sh`, `no` otherwise, `unknown` without a base or when `git diff` fails.
- Read it in `deliver-change.js` (`parseLaneFacts`, strictly: `yes` or `no`, else `unknown`) and add `noRubyAt` and `benchWithoutRuby`: in the Benchmark phase, after the equal-figures branch and before the benchmark agent, the workflow reads the lane's facts in a record start and, when the check passed at the head and the lane is clean at that head with `ruby no`, records `verdict('bench', true)`, a note naming the reason (no Ruby code changed), and `reviewed('bench', true, head, { blocking: 0 })`, starting no agent. Any other reading keeps today's gate.
- Add tools-test cases: the `ruby` line over carat/, bin/, bench/, config/, tools/spinel/, `carat.rb`, `Makefile`, `tools/metrics.sh` (yes) and docs, tools, test files (no); the strict parse; a docs-and-tools-only diff recording the bench review with no agent start; a diff touching Ruby code, an unknown fact, a dirty or unread lane, another head, or a check not at the head keeping the gate; the order of the branches in the phase.
- Document it in README.md and the `tools/lane_facts.sh` entry of `docs/codebase-map.md`.

Assumptions: `test/` is not Ruby code for this purpose (the brief names `carat/`, `bin/`, `bench/`, `config/`, `carat.rb`; the benchmark runs `bench/`, not tests); the fact reaches the workflow through the same record start as `machinery`, so it is read from git, never from a contributor's claim, and a missing or malformed line reads `unknown`, which keeps the gate; the review record stays `review.bench pass HEAD`, so the merge gates are unchanged; the check's own `metrics` stage and CI's are unchanged.

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- Code: `.claude/workflows/deliver-change.js`, `tools/lane_facts.sh`.
- Tests: `tools/tools_test.sh`.
- Docs: README.md (the benchmark step and the facts sentence), `docs/codebase-map.md` (the `tools/lane_facts.sh` entry).
- docs/architecture.md: unchanged, it does not describe the delivery workflow's phases.
- CLAUDE.md: unchanged, its Agents text already says the benchmark runs when figures exceed main's, and it has no room under its budget.
- No edit of `tools/rules.sh`.
