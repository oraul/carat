# Design

## Context

`tools/run_state.sh check` starts its runner as `sh tools/run_state.sh check-run`, the working tree's copy; the stages run in a clone of HEAD, so the Makefile and the test runner they read are committed, but the runner that writes the stage records is whatever the working tree held when it started. The workflow backs a contributor's passing head (`claimFrom`, `backedCommit`) when the branch leaves `tools/`, the `Makefile`, and `test/runner/` alone, and the checker then skips the stages recorded passed there. CI reruns every stage but `diagnose` and the gates; main's merge gates rerun the gates. `diagnose` is also in `COMPILE_STAGES`, skipped on a compiled line any runner writes beside the run states.

The skeptic (`Mode: skeptic` of the quality reviewer) recorded its kept and disputed findings itself, with a command line its instructions wrote as `note <change> security "disputed: <reason>; <finding>"`: the finding text, which quotes reviewed code, inside double quotes.

`held-finding` and `unpushed-finding` notes are the workflow's close records (`recordLate`), read back by `seed` (`heldFindings`); the read profile of `tools/agent_guard.sh` allowed `note` of any kind to the checker, the reviewers, and the benchmark.

## Goals / Non-Goals

Goals: no stage CI leaves out passes on a record a contributor's runner wrote; a dirty-tree runner backs no head; every skeptic note recorded literally; the held and unpushed finding notes written only by the workflow's close profile and only in their phase of the run.

Non-goals: proving the run state against a forged runner (it can write any record; CI and the merge gates rerun every other stage); the open-pr fork heading, closed by #268; the items left for `pipeline-lows-b`.

## Decisions

- Rerun `diagnose` rather than prove the runner. A check runner is shell run by the same user, so no record it writes can prove which script wrote it; the trusted reruns are CI's and the merge gates'. `diagnose` is the one stage neither reruns, so the checker's own run (on a clean tree, the committed runner) reruns it unless the record at the head is backed by the recorded `phase.check`, which the workflow writes from the checker's verdict. It leaves `COMPILE_STAGES`, since the compiled line is the same kind of record. Cost: about a minute per check that skipped it before, run beside the other stages (`CHECK_JOBS`). Alternative: run `diagnose` in CI on every pull request; rejected as a CI-time decision the Makefile records against.
- The runner repeats the waiter's dirty-tree refusal at its own start, before the clone, so a runner started over an edited tree (between the waiter's check and its start, or by hand) writes no record; an edit after it starts is already voided by the escape scan.
- The skeptic returns `notes` (`{ kind: security|quality, text }`) and records nothing; `skepticNotes` builds `sh tools/run_state.sh note SPRINT KIND 'TEXT'` with `shellWord` and drops any other kind; one record start runs them before the planner, and the planner starts only when it ran (`skepticNoted`). The counts stay in the schema for the report and the review lines.
- The guard refuses `note` of `late-finding`, `held-finding`, and `unpushed-finding` to the read profile but the close profile, as it keeps `phase` to the close profile; `add_note` refuses a `held-finding` without a recorded `pushed` or with a `merged` one, and an `unpushed-finding` with a recorded `pushed`, the phases `recordLate` writes them in.

## Risks / Trade-offs

- A run that never pushed but whose close records `held-finding` would be refused: `recordLate` picks the kind from the same `pushed` and `merged` values, so it cannot.
- Branch code a check runs that writes the run state by an absolute path is caught by the escape scan, which fails the check and notes it; the note it planted stays, as before.
