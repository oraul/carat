# Proposal

## Why

A delivery takes 67 to 105 minutes and about 2M tokens (#99 to #102), and the user's complaint is the time. The waste is inside the run: #102 ran CI twice because a docs-only commit recorded late findings; the checker's `make check` took about 8 minutes and CI then ran nearly the same stages; the refs/backup step never produced a ref in #91 to #102; a CI run superseded by a green re-run started a fix round with no code change (#102) and stopped #103 twice; a fix round re-reviewed everything and blocked on a re-rated finding (#100) or an earlier advisory (#97); a resume re-ran the check and every review for 369,424 tokens with only the package step's records after them (#103); the per-change quality review blocked on broad points (first pass 23 of 61). This change applies decisions 11, 14, and 16 of `tmp/briefs/pipeline-skeptic.md`. It is outside the roadmap of `docs/architecture.md` section 12: it is delivery process.

## What Changes

- One push per run: a finding that arrives after the package step is recorded in the run state as a `late-finding` note, never pushed; `tools/run_state.sh history`, which the next change's package step runs, appends each merged run's late findings to `docs/backlog.md` with its metrics row. The CI-fix push no longer appends findings.
- Checks once: the checker runs `FAST_STAGES` (docs-lint, the builds and tests the benchmark comparison reads, diagnose, gates) and CI runs every other stage of `CHECK_STAGES`, the release build and its smoke test now on pull requests too; while origin/main's Makefile has no `FAST_STAGES`, the check runs main's `CHECK_STAGES`, which main's merge gates require. CI is never skipped for code (`tools/ci_scope.sh` unchanged).
- The per-change quality reviewer blocks only on a correctness bug or a behavior change without its test; style, naming, architecture and the layer rule, duplication, and docs currency are advisories until `sprint-planning` lands.
- The refs/backup step is removed: `backup`, `restore`, and `abandon` leave `tools/run_state.sh`, the guard, the gates, the agents, and the workflow (closes `backup-records`).
- The merger reads only the latest run of each check name on the head; a red run superseded by a green run of the same check starts no round (`staleRed` in the workflow as a second check).
- A fix round's reviews cover the commits since the last passed review of the same start; a blocking quality finding at the location of an earlier advisory (a re-raise) is kept as an advisory. A security finding is never re-rated to non-blocking: the CLAUDE.md hard rule makes every High or Medium at confidence 8 or above in the change block, so item 6's re-rating applies to quality only.
- The record agent start runs only when a check or review record is pending before a push or the merge gates, which read them and which only an unguarded start may write; every other record waits for the closing start, and the close's fallback record start is removed.
- The pull request as created equals the gated body file: the contributor passes the file's text unchanged, compares the created body, and restores it; the pr-body gate refuses a session line. `.claude/settings.json` already sets no pull request text and no session link, so a footer the creation still adds comes from outside the repository; the Notes say what the user changes.
- A resume trusts the check and reviews recorded at a commit when the pushed head's only later commits are records (`tools/gates.sh passed` exits 0), instead of running them again.
- A red CI only on the scan of the pull request body is fixed by a contributor `body` start (the body file corrected, gated, and set on the pull request, no commit, no push) and the merge continues without a fix round, once per run.

Out of scope: the sprint model, the queue's self-contained items, the broad review at sprint end, and `docs/goals.md` (`sprint-planning`); CI caches (`ci-time`); the price-weighted measurement (decision 4). The queue's bookkeeping is the planner's `build/plan/queue.md`, copied in the package step.

Assumptions:

- Item 2: the checker running fast stages is picked over the checker's pass standing for CI, since CI cannot see a local pass without trusting the run state and CI is never skipped for code; the evidence is the checker's 8 minutes against CI's 6 with both caches. The fast set keeps `metrics` and its builds because the benchmark phase reads the checker's measurement; it drops doctor, the release build, config-current, no-cruby, and tools-test, which CI runs on every pull request.
- Item 7: the pre-push and merge gates read the check and review records, and the guard lets no guarded agent write them, so one record start stays where those records are pending before a push; removing it entirely would let a guarded agent write review records, which this change does not do. The start is removed everywhere else.
- Item 9 trusts records of the run state, which branch code run by the checks can write; it is limited to records at a commit the merge gates' settled check accepts at the pushed head, and the merge gates still run main's copy.

## Capabilities

### New Capabilities

None: the change is delivery process and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `.claude/workflows/deliver-change.js`, `.claude/agents/checker.md`, `merger.md`, `quality-reviewer.md`, `contributor.md`, `tools/run_state.sh`, `tools/gates.sh`, `tools/agent_guard.sh`, `tools/tools_test.sh`, `Makefile`, `.github/workflows/ci.yml`.
- CLAUDE.md: changed, the run_state commands, the checks, and the agents' steps.
- README.md: changed where it names the backup step or the check stages.
- docs/architecture.md: changed where section 10 names the stages the checker runs.
