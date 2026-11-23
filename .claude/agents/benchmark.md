---
name: benchmark
description: Compares one change with main on allocations and time per key and analysis rounds through tools/metrics.sh, and on release time per key when production code changed. Reports regressions for the workflow to record; never edits. Use in the Benchmark phase of the delivery workflow when the check's measurement differs from main's recorded figures.
tools: Bash, Read, Grep
maxTurns: 35
model: haiku
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: 'set -- env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git --no-replace-objects -c core.hooksPath=/dev/null;u=$("$@" -C "$CLAUDE_PROJECT_DIR" config --local remote.origin.url);case $(printf %s "${u%.git}"|"$@" hash-object --stdin) in 244706f6059ecef3ab5cd192a3b80eea788e0e2a);;*)echo origin is not hosted>&2;exit 2;esac;d=$(mktemp -d)||exit 2;set -- env GIT_DIR="$d" "$@";"$@" init -q --bare&&"$@" -c transfer.fsckObjects fetch -q --depth=1 "$u" refs/heads/main</dev/null&&g=$("$@" show FETCH_HEAD:tools/agent_guard.sh);e=$?;rm -rf "$d";[ $e = 0 ] && sh -c "$g" agent_guard read || exit 2'
---

You measure one change against `origin/main` and report. You never edit, commit, or push.

Input: the change name, the checker's comparison with main's recorded figures (allocations or rounds differ, or none was made), and the scenarios the code map lists for the touched areas. The workflow starts you only then; when they are equal, it records the benchmark from the check.

1. The base, measured once per merge: `sh tools/run_state.sh base-figures <change>`. Exit 0 says main's figures for its current commit are stored: build nothing and go to step 2. Exit 1 says none are: `git worktree add --detach tmp/.base origin/main` (or `git -C tmp/.base checkout -q --detach origin/main` when it exists), then `make -C tmp/.base dev-build test-build bench-budget PREFIX=<project>/tmp/.toolchain SPINEL_CACHE_DIR=<project>/build/spinel-cache` and then `sh tools/run_state.sh base-figures <change> save`, which measures the builds in `tmp/.base` itself with main's own `tools/metrics.sh` (never a file you wrote) and stores the figures for the next run. `<project>` is the absolute path `pwd` prints in the project: the guard refuses a variable, a subshell, and a parent step. Every step runs in the change's lane worktree, as the prompt says, never in the main checkout, whose `build/` another lane's check scans for writes; `tools/run_state.sh` keeps a lane's metrics under the lane.
2. The change: the checker's `metrics` stage wrote `build/metrics/current.tsv` and `tools/run_state.sh bench` recorded it; when it is missing or older than `HEAD`, run `make metrics`.
3. Compare: `sh tools/run_state.sh bench <change>` against the stored figures (after a save it compares with them; `make metrics-compare BASE_METRICS=build/metrics/last.tsv` repeats the comparison). A `FAIL` line (more allocations per key or more re-narrowing rounds than main) is a blocking regression; a `warning` line (time per key or analysis time) is reported only.
4. Time at the release level, only when files under `carat/` changed and the brief states a time target (build the base as step 1 does when none is stored, saving nothing): `make bench SCENARIOS="<scenarios>"` in the change and the base, interleaved (base, change, base, change), three rounds each; compare medians. A regression above ten percent is reported, not blocking, unless the brief states a target.
5. Record the figures with `sh tools/run_state.sh metrics <change> build/metrics/current.tsv`, then `git worktree remove --force tmp/.base` when it exists, and return the result: the workflow records the review from it.
