# Proposal

## Why

Two starts of a delivery repeat work the run state already holds. The benchmark agent builds and measures main on every run it is started for (finder-rows: 110,265 output tokens and 22 calls, the base built twice), though main's figures only change at a merge. The checker start runs the check, the budget line, and the benchmark comparison even when every stage is already recorded passing at the head (cheap-tier 29,235 output tokens and 4 calls, finder-rows 25,756 and 4, merge-path-lows 17,192 and 4, every stage carried). The change is the user's request to use the caches the pipeline has more.

## What Changes

- Add `run_state.sh base-figures CHANGE [save]` and the stored figures of main (`build/pipeline/main-figures.tsv`, the commit of main and its measured figures): the benchmark agent builds and measures main only when none are stored for main's current commit, then saves them (`save` takes the measurement itself with main's own script), so one measurement serves every run until main moves.
- Change `run_state.sh bench` to compare with the stored figures first: no more allocations or rounds than main exits 0 (no benchmark agent), more exits 1 as a regression; without stored figures it compares with the recorded ones as before.
- Change `.claude/agents/benchmark.md` to read the stored figures and build the base only when none are stored (and for the release timing, only when the brief states a time target).
- Add `run_state.sh carried CHANGE COMMIT`: when COMMIT is HEAD and every stage of `make stages` holds a pass record at HEAD (`diagnose` only when scoped out), it prints that every stage passed with the spent line and the benchmark comparison the checker would have returned; otherwise it says why not and exits 1.
- Change the workflow's check round to ask a runner start for `carried` when the contributor's pass at the head is the backing and no settle or moved line is asked, and to record the check itself from the result, starting no checker; any other result starts the checker as before.
- Add the runner profile's `carried` form and the read profile's `base-figures` form to `tools/agent_guard.sh`.
- Document both in the header of `tools/run_state.sh`, README.md, and CLAUDE.md.

Assumptions: the stored figures live in the shared run state directory, which no lane's check scans for writes; main's current commit is `origin/main` (`BASE` in tests); the release-level timing comparison of the benchmark agent is kept only when the brief states a time target, since it is reported, never blocking, and needs the base build this change removes from the common path; the carry accepts the same trust as the existing backing (the contributor's own check at the head over a change that leaves the check's machinery alone), and `diagnose` still reruns unless scoped out, as `check` does; brief parts (3), the pull request text check in the package start, and (4), the stable prefix of prompts, are the planned change cache-reuse-b.

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- Code: `tools/run_state.sh`, `tools/agent_guard.sh`, `.claude/workflows/deliver-change.js`, `.claude/agents/benchmark.md`, `.claude/agents/checker.md`.
- Tests: `tools/tools_test.sh` (stored figures, the carried command, its guard forms, the workflow's carry helpers).
- Docs: README.md (the checker and the benchmark paragraphs), CLAUDE.md (the phases bullet).
- docs/architecture.md: unchanged, no spec changed and the pipeline's tools are described in README.md and the script's header.
- docs/codebase-map.md: unchanged, no file added, moved, or removed.
- No edit of `tools/rules.sh`.
