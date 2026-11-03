# Design

## Context

`.claude/workflows/deliver-change.js` runs one agent per phase and records the run state through `tools/run_state.sh`, which only an agent can run, so the script queues command lines and one record agent runs them (`flush`). Its figures (`usage`, `firstPass`, `rework`, `ciMinutes`) lived in memory and reached the run state only as one `metric` line the retrospective and the reporter ran, so a resumed run lost everything measured before the restart. The scout plan listed every area the change "touches", the benchmark agent rebuilt `main` for a change that edits no compiled file, the CI watcher and the merger read the same pull request twice, and a fix commit at a new `HEAD` reran every stage.

## Goals and non-goals

Goals: fewer agent calls and stage runs per change with the same gates; whole history rows after a resume; a CI wait that does not give up while CI runs. Non-goals: changing what any gate decides, the security review (never skipped), the push rule, or the merge gates.

## Decisions

### Scouts and plan notes

The scout plan's prompt asks for the areas whose files the brief says the change edits, not the ones it reads or only records in the backlog, at most three; the workflow keeps at most three areas (current packs count) and logs any it drops. The planner's result gains `notes`: findings the change only records in `docs/backlog.md` and other bookkeeping. The workflow hands them to the contributor's implement step under "Plan notes"; the planner never turns them into a scout question.

### One agent for CI and the merge

The `merger` agent now holds the CI watcher's steps. It reads the pull request once for its head and title, checks the head against `pushed` and the local `HEAD` (`stale` otherwise), then polls the head's check runs with backoff (30, 60, 120, then 300 seconds) up to 30 minutes, never returning while a check is queued or in progress before that limit. It returns:

- `pending` with each check's name, status, and conclusion when the limit passes; the workflow calls it again, at most four calls, then stops with that state;
- `red` with the failing step and the last 80 lines of its log (or `conflict`), after `set ci "red <head>"`; the workflow sends it to the contributor's fix loop, verifies, pushes the fix, and calls the merger again;
- `green`, after `set ci "green <head>"`, then the merge: the merge gates exactly as given, on `build/pipeline/<change>.body.md`, the squash with the pull request title and that body plus the trailer, the check of `main`, `set merged`, and the branch cleanup.

The body file is written by the contributor's package step with the Write tool and checked there with `sh tools/gates.sh pr-body`; the merger does not reread the body from the pull request. `tools/agent_guard.sh` already allows the merger that one file of the run state's directory; the contributor profile gets the same allowance. Both now refuse the name when a `/` follows it, so a directory created under that name cannot reach the run state file.

The workflow records `ci` and `merge` phases from the one result; its usage key is `merge`.

### The benchmark from the check

`tools/run_state.sh bench CHANGE` needs `stage.metrics` passed at `HEAD`. It imports `build/metrics/current.tsv` (`METRICS_OUT`) as `metrics` does, writes main's rounds, allocations, and times as `build/metrics/last.tsv` (`rounds.NAME`, `allocs.NAME`, `us.NAME`): those of the newest merged change without a `docs/metrics.tsv` row (`newest_pending`, by its squash commit's time), from its run state's `metric.rounds.*`, `metric.allocs.*`, and `metric.us.*`, else the last row. A merged change's row is appended in the next change's package step, after this comparison, so the last row is one merged change behind `main` whenever one is pending; a pending change without recorded allocations or rounds is not compared, runs `make metrics-compare BASE_METRICS=build/metrics/last.tsv` for its report (time warnings included), and exits 0 with `bench: same` when every `allocs.*` and `rounds.*` value equals the base's, 1 with the differing names otherwise or when there is no base. The checker runs it once every stage passed and returns `bench_same` and its lines. The workflow records the `bench` review from a `true` without starting an agent; otherwise the benchmark agent runs as before, its prompt giving the base build's `PREFIX=$PWD/tmp/.toolchain` and `SPINEL_CACHE_DIR=$PWD/build/spinel-cache`.

### Figures stored as they happen

The workflow queues `metric` lines of numbers and fixed names only:

- `phase.<key>=<tokens>/<calls>` at the end of every measured call, the running total of that key;
- `first.<gate>=0|1` at each gate's first verdict (check, quality, security, bench, ci);
- `rework=<n>` at each fix, `ci_min=<minutes>` at each CI result.

On a resume the script seeds `usage`, `firstPass`, `rework`, and `ciMinutes` from those lines of the state it read. `withCalls` makes `tool_calls` required, so a result without it fails its schema instead of counting 0.

`history` builds the row from the state:

- first passes: for each of check, quality, security, bench, ci in that order, `metric.first.<gate>`, else that gate's entry of an older `metric.first_pass`, else nothing: the `stage.*`, `review.*`, and `ci` lines hold each gate's last result, which for a merged change is always a pass, so they say nothing of the first; then `gates` as before;
- phases: `metric.phase.*` grouped as `key=tokens/calls`, else the older `metric.phases`;
- out tokens and tool calls: the sums over `metric.phase.*`, else the older `metric.out_tokens` and `metric.tool_calls`.

The retrospective and the reporter no longer receive a metric command line; they read the run state.

### Test-only fix rounds

`check_stages` keeps a stage passed at `HEAD` as before. A stage not in `TEST_STAGES` (`test-build test-run diagnose metrics docs-lint gates`: the stages that read the test programs, `diagnose` because `make diagnose` runs `spinel-doctor` on the test runner, `metrics` because it reads the runner's rounds from `test-build`'s report, `docs-lint` because it reads `docs/*.md`, the planning records among them, and the `test/` paths the docs name, and the gates) that passed at another commit is carried when every path of `git diff --no-renames --name-only <commit> HEAD` (both paths of a rename, so a file moved under `test/` is no test-only change) is under `test/` or is one no carried stage reads (`openspec/`, `docs/backlog.md`, `docs/queue.md`, `docs/goals.md`, `docs/metrics.tsv`): its record becomes `0 0s HEAD UTC carried-from-COMMIT`, so `gates.sh stages` and a restart read it as passed at `HEAD`. Anything else changed, or a stage that failed, runs.

The quality reviewer records each blocking finding as a `quality-blocking` note headed by the reviewed commit, and a resumed run seeds them when their number matches the review's `blocking=N`. The reviewer's prompt names the commit and result of the last quality review; only when that commit is not `HEAD` and its findings are known (a pass has none) does it give the findings and offer the fix diff: when `git diff --name-only <commit> HEAD` lists at least one file and only files under `test/`, it reviews `git diff <commit> HEAD` against those findings, otherwise the whole branch diff. An unknown finding list or an empty fix diff never narrows the review.

### Report phase and flushes

`PHASES` gains `report`; the workflow queues `phase report` after the reporter. Flushes run at the end of `verify()` (the pre-push gates read the reviews), after the package step, after the merge, and once at the end after the report; plan, implement, ci, and retro lines wait for the next one. A crash between flushes repeats at most the phases since the last one; package and merge, which cannot run twice, are flushed at once.

## Risks and trade-offs

- A carried stage trusts the rule that files under `test/` and the planning records reach only `test-build`, `test-run`, `diagnose`, `metrics`, and `docs-lint`, which rerun, so the carried stages are those whose inputs a test-only commit leaves unchanged; `metrics` reruns because it reads the runner's rounds, so the benchmark never compares the figures of an earlier commit. The brief named three stages; `diagnose` was added because it analyzes the test runner, and CI leaves it out.
- A run state from before this change has no `metric.first.*` lines, so its row leaves out the gates its older `metric.first_pass` does not name; deriving them from the last results would record first passes that never happened, which the planner reads as rates.
- The merger now holds the GitHub read tools for CI as well as the merge; the guard profile is unchanged apart from the body-file rule.

## Measuring it

The next change's history row against this one's (`plugin-path-containment`: scout 211,029/124, bench 4,683/0, ci 9,629/24 and merge 4,078/17; `agent-authority`: ci and merge 7,473 of 7,968 tokens): the scout share, one `merge` key instead of `ci` and `merge`, no bench agent when allocations hold, and whole first passes and phase figures.

Before and after, measured while implementing it (no real run uses the new script until the next change):

- A dry run of the script at 6dfb3c4 and of this one with canned agent results: a run that passes everything first time starts 24 agents and 7 record flushes before, 18 and 4 after (one scout fewer of four asked for, no benchmark agent, one merger instead of the watcher and the merger, three record agents fewer); a quality fix round 27 and 7 before, 21 and 4 after; CI still running at the first look stopped the old run as `stalled` with no merge, the new one merges after two waits.
- `tools/run_state.sh history` on `agent-authority`'s run state: `ci:1,gates:1` before and after; the derived `check:1,quality:1,security:1,bench:1,ci:1,gates:1` of an earlier commit of this change was dropped after review, since those lines show the last results, not the first.
