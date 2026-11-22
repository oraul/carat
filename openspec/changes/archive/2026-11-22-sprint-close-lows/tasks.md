# Tasks

## 1. Continuations of both sprint reviews

- [x] 1.1 `.claude/workflows/sprint-planning.js`: `pathKey`, `stillLeft`, used by `mergeSecurity`, keeping a differently spelled file left. Test: `tools/tools_test.sh` "sprint: a continuation's file left in another spelling stays left".
- [x] 1.2 `.claude/workflows/sprint-planning.js`: `qualityDone`, `mergeQuality`, and `reviewContinued` starting either reviewer once more over the files it left; the overrun notes count every start. Test: "sprint: the quality continuation's findings merge and only its files stay left", "sprint: both sprint reviewers get one more start, their results merged".

## 2. Security findings both reviewers missed

- [x] 2.1 `.claude/workflows/sprint-planning.js`: `SKEPTIC.security_missed`, the prompt asking for it, `missedSecurity`, the `missed by both:` notes in the skeptic's record start, `blockingOf` over both. Test: "sprint: a security finding both reviewers missed is recorded and counts as blocking", "sprint: the skeptic is asked for the security findings both missed".
- [x] 2.2 `.claude/agents/quality-reviewer.md`: the skeptic returns what both missed in `security_missed`; a security matter named in one line, unexamined. Test: "agents: the quality reviewer leaves security points unexamined and returns missed ones in security_missed".

## 3. The records change held by a blocking security finding

- [x] 3.1 `.claude/workflows/sprint-planning.js`: `recordsHeld`, the gate, and the report's held line; `.claude/commands/sprint.md`. Test: "sprint: a blocking security finding or the plan's security first holds the records change", "sprint: the records change starts only when nothing holds it".

## 4. No duplicate security note on a rerun

- [x] 4.1 `tools/run_state.sh` `add_note`: a `security` note already recorded with the same text is not recorded again. Test: "run_state: a rerun's security note is recorded once", "run_state: a disputed security note beside its finding is still recorded".

## 5. Docs and checks

- [x] 5.1 README.md step 11, `docs/codebase-map.md` area 1. Test: `make docs-lint`, `make gates`, `make spec-validate`, `make tools-test`.

## Quality review

- [x] 6.1 `proposal.md` and task 2.2 said the quality reviewer's sprint mode gained the continuation at its cap, which its step 6 already states; the file's budget trims (step 4, the sprint and skeptic wording) were not named. Corrected. Fixed.
- [x] 6.2 `design.md` did not say that the whole-tree sweep's blocking security findings hold the records change only through the plan's `security_first`, which the planner writes from the sweep's run state; stated. Fixed.
