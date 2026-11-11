# Proposal

## Why

CI took 4.6 to 17.0 minutes over #95 to #109, but the run state keeps only the merger's one `ci_min` figure, so nobody can say which step grew; a pull request that already passed CI runs every build and test step again after a commit that touches only its OpenSpec records or docs; `tools/ci_scope.sh` counts `.claude/agents/`, `.claude/workflows/`, and `.claude/settings.json` as documentation, though `make tools-test` reads all three (the Low (4) of #104); the merger's minutes waiting on CI are known but not the tool calls they cost; and the history's raw total tokens (748,665 to 3,782,399) treat a cheap-tier token like a session-tier one, so no cost item can show an effect. This change delivers queue item `ci-time` with decisions 4 and 9 of `tmp/briefs/pipeline-skeptic.md`. It is outside the roadmap of `docs/architecture.md` section 12: it is delivery process.

## What Changes

- `tools/ci_scope.sh`: `.claude/agents/`, `.claude/workflows/`, and `.claude/settings.json` are code; on a pull request whose changes are not all documentation, the checks are still skipped when the merge commit differs from the newest earlier head of the pull request whose spin check passed only in documentation no test reads. `.github/workflows/ci.yml` passes the pull request's number and head.
- New `sh tools/run_state.sh ci-stages CHANGE COMMIT`: reads the spin job of the newest ci run at the commit with `gh api` and records each step's seconds as `metric.ci.STEP`, replacing the previous run's; it never fails the line it is in. The merger's green and red lines run it first, and the guard's merger profile allows it.
- The merger's CI waits are counted from the minutes it returns (3, 4, then 5 minute waits, two calls each: the wait and the read after it) as `metric.ci_wait_calls`.
- New `sh tools/run_state.sh tokens CHANGE DIR`: reads one Workflow run's agent transcripts, sums each start's input, cache-write, cache-read, and output tokens, prices them by its tier (`TIER_PRICES`), and records `metric.start.N`, `metric.weighted.KEY` per phase, and `metric.weighted_tokens`; a directory is counted once. `/deliver` runs it after each Workflow start, beside `usage`.
- `docs/metrics.tsv` gains columns 19 to 22, `ci_stages`, `ci_wait_calls`, `weighted_tokens`, and `weighted_phases`, the existing rows padded with `-`.
- CLAUDE.md's Commands, the map, and the deliver command follow.

Out of scope: any change to the CI steps themselves or their caches (the latest pull request run, 43093596432, took 7.6 minutes with warm caches; the recorded stages will show where a slow run spends its time); judging the 3-run acceptance (CI under 10 minutes, docs-only under 60 seconds), which the next rows show; `docs/goals.md`, which no part of the brief asks to change; other `.claude/` paths, which only `make docs-lint` reads and which stay as they are.

Assumptions:

- The workflow script sees only output tokens (`budget.spent()`), so the per-start totals come from the transcripts the runtime writes for each Workflow run (`agent-*.jsonl` with each message's usage, `agent-*.meta.json` with its label and phase), read by the main session, which alone knows the run's directory.
- The tier prices are per million tokens in tenths of a cent, input, cache write, cache read, output: the session tier 4000/5000/200/20000 and the cheap tier 100/125/10/500, from the current price list; a cache write is priced at the five-minute rate. The weighted figure is in session-tier input tokens, so it stays near the raw totals and the budgets.
- A transcript's model is the cheap tier when its name contains a tier alias of an agent file's `model:` line, else the session tier, so no model name is written in the repository.
- A start's phase key is its workflow phase in lowercase, and `record` for the record starts.

## Capabilities

### New Capabilities

None: the change is delivery process and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `tools/ci_scope.sh`, `.github/workflows/ci.yml`, `tools/run_state.sh`, `tools/agent_guard.sh`, `tools/tools_test.sh`, `.claude/workflows/deliver-change.js`, `.claude/commands/deliver.md`, `docs/metrics.tsv`, `docs/codebase-map.md`.
- CLAUDE.md: changed, the Commands line of `tools/run_state.sh` (`ci-stages`, `tokens`).
- README.md: unchanged, no user-visible command, binding, option, or target changes; the run state commands are listed in CLAUDE.md and the script's header.
