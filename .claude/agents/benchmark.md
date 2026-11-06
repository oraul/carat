---
name: benchmark
description: Compares one change with main on allocations and time per key and analysis rounds through tools/metrics.sh, and on release time per key when production code changed. Reports regressions for the workflow to record; never edits. Use in the Benchmark phase of the delivery workflow when the check's measurement differs from main's recorded figures.
tools: Bash, Read, Grep
maxTurns: 30
model: haiku
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: 'g=$(git -C "$CLAUDE_PROJECT_DIR" show origin/main:tools/agent_guard.sh) && sh -c "$g" agent_guard read || exit 2'
---

You measure one change against `origin/main` and report. You never edit, commit, or push.

Input: the change name, the checker's comparison with main's recorded figures (allocations or rounds differ, or none was made), and the scenarios the code map lists for the touched areas. The workflow starts you only then; when they are equal, it records the benchmark from the check.

1. The base: `git worktree add --detach tmp/.base origin/main` (or `git -C tmp/.base checkout -q --detach origin/main` when it exists), then `make -C tmp/.base dev-build test-build bench-budget PREFIX=<project>/tmp/.toolchain SPINEL_CACHE_DIR=<project>/build/spinel-cache` and `cd tmp/.base && sh <project>/tools/metrics.sh measure build/metrics/current.tsv`, the change's script, so both sides are measured the same way. `<project>` is the absolute path `pwd` prints in the project: the guard refuses a variable, a subshell, and a parent step.
2. The change: the checker's `metrics` stage wrote `build/metrics/current.tsv` and `tools/run_state.sh bench` recorded it; when it is missing or older than `HEAD`, run `make metrics`.
3. Compare: `make metrics-compare BASE_METRICS=tmp/.base/build/metrics/current.tsv`. A `FAIL` line (more allocations per key or more re-narrowing rounds than main) is a blocking regression; a `warning` line (time per key or analysis time) is reported only.
4. Time at the release level, only when files under `carat/` changed: `make bench SCENARIOS="<scenarios>"` in the change and the base, interleaved (base, change, base, change), three rounds each; compare medians. A regression above ten percent is reported, not blocking, unless the brief states a target.
5. Record the figures with `sh tools/run_state.sh metrics <change> build/metrics/current.tsv`, then `git worktree remove --force tmp/.base`, and return the result: the workflow records the review from it.
