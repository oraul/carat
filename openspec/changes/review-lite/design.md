# Design

## Context

`rounds` in `.claude/workflows/deliver-change.js` loops: the check unless it passed at the head this start (`doneAtHead`), then the quality and security reviews not passed at the head (`reviews`, `reviewedAtHead`), then the benchmark. When nothing blocks and the reviews returned findings in the change's own files, a round of its own offers them to the contributor (`inPlaceRound` returns `alone`), and the loop starts again at the new head, where nothing has passed, so everything reruns. The merge gates (`gate_stages`, `gate_security`, `gate_passed` in `tools/gates.sh`) already accept a pass at an earlier commit when every file changed since it matches `RECORDS_RE` (`settled_at`).

## Goals / Non-Goals

Goals: an advisory-only round with a records-only fix reruns only the quality review, scoped to its commits, its skip recorded. Non-goals: widening the records-only paths (`review-lite-docs`), any change to the merge gates or `tools/rules.sh`.

## Decisions

- The workflow cannot run git, so the decision is a script's: `tools/run_state.sh settled CHANGE COMMIT`, run first by the checker's run start, the start that would have run the check (no extra start). It uses `RECORDS_RE`, the same paths as `settled_at`, but refuses `docs/sprints.tsv` outright (the gates accept only groom's row, which no delivery fix writes), a dirty tracked tree, and a COMMIT that is not an ancestor of HEAD, so it is never wider than the gates.
- The workflow trusts only a `settled:` line naming the settled commit and the head (`settled`, like `carried`). A forged line can only stop the run: the pre-push and merge gates check the same records with `settled_at`, from main's copy at the merge.
- The settled commit (`settleFrom`) is this start's `phase.check`, when this start's security review and benchmark passed at that same commit and the round offers no security finding (a security finding fixed in place needs the security reviewer to confirm it). It is computed only on the `alone` path, so a round with a blocking finding never settles.
- `settleRound` keeps `{ at: head, from }`; `doneAtHead('check')` and `reviewedAtHead` of `security` and `bench` read it, never `quality`. The pass records stay at the settled commit, so `mergeRecords` and the run state agree and the gates settle them. It queues a `settled-round` note naming both commits (closable, flushed with the quality record).
- The quality review needs no new scope: it passed at the settled commit this start, so `priorQuality` already returns `git diff <that commit> HEAD` (`narrowedFrom`); a test case proves it for this round.
- The package step's prompt names the settled commit for Testing (`settledTesting`) only while the settled round is at the head; a full round after it, in the same start, leaves the check and the security review at the head, as usual.
- The in-place fix asks the next check to settle only when it moved the head (`settleAfter`); `settleBase` drops the settle after a merge of a moved main, and `checkOutcome` and `roundSettle` hold the verdict and alone-path decisions so test cases prove them as behavior.
- In a settled round the run's metric line leads the settle line instead of the check line, so its figures are recorded once whether or not the check then runs.

## Risks / Trade-offs

- After a settled round, quality and security pass at different commits, so a merge of a moved main reruns both reviews (`carryFrom`), the conservative path.
- Acceptance is narrowed to records-only fixes until `review-lite-docs` widens `settled_at`.
