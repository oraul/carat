# Contributor notes

Prose the contributor reads when a step needs it, moved out of `.claude/agents/contributor.md` to keep that file within its docs-lint budget. The rules card at the top of the agent file is the short form.

## Context

Read in order until you know what the change touches: the locations the change edits, which the plan notes give, else its queue entry or the brief (read each file at those lines first); the map sections of the touched areas (`docs/codebase-map.md`); the files, tests, and designs they name; the touched sections of `docs/architecture.md`. A file added, moved, or removed is placed in its map area.

## Conflicts with main

On its conflicts merge `origin/main` by hand (the trailer of `CLAUDE.md`): keep both sides of appended files, regenerate generated ones with `make`, and stop and name a conflict where both sides changed the same logic. The fix stays in the push start; the checks and reviews rerun.

## Propose

Propose with the `openspec-propose` skill (a change with no behavior change sets `skip_specs: true`), minor assumptions in the proposal. A change past one reviewable pull request is split, its first part delivered. Fix every finding of `openspec validate "<change>" --strict --no-interactive` and `make spec-validate`.

## Iterating

Run only targeted checks through `make`: `make test-one T=test/NAME.rb`, `diagnose-one T=path`, `lint`, `docs-lint`. Only `make snapshots` rewrites a snapshot, and its diff is read.

## Body

Write the body with the Write tool by CLAUDE.md's Pull request description section: its Testing names only checks and reviews that ran, with results, the security review first. Check it with `sh tools/gates.sh pr-body` on that file before `open_pr.sh write`.

## Findings

Append each finding to `docs/findings/<change>.md` with `>>`, as a `### title` heading and three lines: `- Location:`, `- Why:`, `- Fix:`.

## Edge-case checklist

The self-check of the implement mode and of the fix mode walks these points, each from findings the quality review blocked a first pass on. A behavior the change touches that one of them concerns gets a test, or the reason it cannot arise is stated in the test or the proposal.

- Empty range: a count, range, or selection of zero lines or characters, and a start past the end.
- CRLF: a line ending in a carriage return survives an edit, a motion, and a write.
- UTF-16 and multi-byte: a column, a width, or a language server position over a multi-byte or surrogate-pair character is counted in the unit its consumer expects.
- Trailing blanks: a line ending in spaces or tabs, and a blank line at the end of a range.
- Last line: the cursor or the range on the final line, with and without a final newline.
- Empty buffer: one empty line, and no line at all, where a port can return one.
- A test per behavior change: every added or altered branch has a test, a raise or error branch included, and a test expectation the change made stale is updated.
- An existing helper searched first: grep `carat/` for one before writing a new one.
- Comments, docs, and spec text match the code: a comment, a doc row, or a spec scenario the change made untrue is corrected in the same change.

## Checking

Implement and fix end with the check of the head (card rule 2), so a failing stage is fixed in the same session instead of a new fix start. In order, after the quality step and a commit:

- Run `make docs-lint` and `make gates` by hand first; they are cheap and catch the budgets and a stale README.
- Run `sh tools/run_state.sh merge-main <change>` when the lane is behind `origin/main`.
- Run `sh tools/run_state.sh check <change>`, never with a commit, in one Bash call with the timeout 600000: it waits up to `CHECK_WAIT`, 540 s, and exits 3 while the stages still run; run it again on exit 3, which is a wait, not a run.
- While the check runs, edit, commit, and write nothing: the check refuses a dirty tree, and a write outside its clone voids it.
- On a failed stage read its log as the checker's log mode does: the first 20 lines holding `FAIL`, `rror`, or `KILLED`, and `tail -n 60`. Fix the cause with its target (`make tools-test`, `make test-one`, `make docs-lint`), commit, and rerun the whole check.
- A refusal caused by another lane's files (a `stage none` verdict naming paths this change never touched) is rerun once unchanged; when it repeats, return naming those paths.
- At most three check runs per start: after the third failure, or at the cap, commit and return `partial` with the verdict and the failing stage in `remaining`.
- Return the check's last line verbatim as `check` and the number of runs as `check_runs`. The workflow backs the checker's check with your head when that line reads `check: every stage passed at` your returned head and the change leaves `tools/`, the `Makefile`, and `test/runner/` alone, so the checker skips the stages passed there but `diagnose`, which CI leaves out and which skips only at the recorded check, and still runs spent, bench, the metric line, and moved; its verdict is the one recorded. Each run after the first counts in `metric.self_fix`.

## Closing

Mode `close-advisories` runs once a run, after the last review passed with no blocking finding and before the package step, given the advisories the run raised and left open. Fix each that lies in a file the change itself edits and needs no new behavior and no design change: wording, a comment, a doc or spec text, a missing test for behavior the change already has, a name, a small duplication. Each fix is a task of `tasks.md` marked done, its delta spec updated when specified behavior moves, and committed on its own. Leave every other advisory untouched; the package step writes it to `docs/findings/<change>.md`. Run the touched tests and `make gates`. Make no commit when none qualifies, and return the schema. The check of the closing commit follows, and a security review again unless the commit changed only records and no security finding was offered; advisories that review raises are recorded, never given to a second closing start.

## Self-review

The quality step (card rule 10), in the start that finishes the tasks of `tasks.md` and before the archive: after the self-check, review the whole committed diff (`git diff origin/main...HEAD`) as the quality reviewer would, with the instructions of `.claude/agents/quality-reviewer.md`: a bug or an untested behavior change, and its advisory points. Append each finding as a task under a `## Quality review` heading of `tasks.md` and fix it in the same session; a finding you will not fix goes to the findings file with its reason (Findings), its task marked done as recorded there. Return `quality_review`: status `done` and the counts `added`, `fixed`, and `recorded`, fixed plus recorded equal to added; the workflow refuses an implement result that finished the tasks without it. No reviewer start of the delivery reviews quality; the sprint review does.

## Waiting

`sh tools/open_pr.sh wait <change>` polls up to 540 s, so the Bash call takes the timeout 600000.
