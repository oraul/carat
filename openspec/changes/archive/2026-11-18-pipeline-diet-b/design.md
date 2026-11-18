# Design

## Context

A workflow script has no shell of its own: every command runs in an agent start. The checker start today runs the metric line, the check, `spent`, and `bench`, then reads `show` and every stage's record and returns a report, though the workflow decides from the verdict line alone. The quality reviewer is told only how to scope a re-review, so a first pass may stop at the first blocking finding. Advisories and security Lows are handed to `docs/findings/<change>.md` even when they lie in the change's own files. The records change's budget reads `metric.total_tokens`, to which the sprint's whole cost was added.

## Decisions

- Check: `checkLines(change, backed, movedFrom, metric)` builds three plain lines (the figures and the check; `spent` and `bench`; `moved`), each a form the read profile of `tools/agent_guard.sh` already allows, so the guard, fetched from main, needs no change. The run start keeps the checker's agent type for the guard and the cheap tier but reads nothing (fixed cap `run`, 8 calls). `checkerNeeded(v)` is true only for a failed stage; a refusal's message is its own log. Running the lines in an unguarded start was rejected: `bench` prints text the branch's metrics produce.
- Quality: `qualityTask(scope, more)` adds the first-pass request only when no earlier review scopes the start; the re-review's scope already narrows to the fix diff.
- Fix in place: findings are offered once each (`offered`), so a finding the contributor leaves is not offered again; an in-place-only round runs only when a round remains after it (`inPlaceRound`), so a blocking finding the fix brings still has one; the fix rides in the contributor's `fix` mode prompt (`inPlaceTask`), leaving contributor.md at its byte limit untouched. A finding leaves the hand-over only when a reviewer at the new head lists it, verbatim, in `fixed_in_place`; a paraphrase keeps it recorded, so a mistake records a fixed finding again rather than drops one. The quality reviewer's own `quality-advisory` notes stay in the run state, so a resumed run may hand a fixed advisory over again, never lose one. A resume past the push (`verify(false)`) offers none.
- Records budget: the split is by label in `add_tokens`, the one place that sees each start, rather than an output-token share, which would estimate the input side. The sprint-planning labels that named no sprint get a `sprint:` prefix.

## Risks

- The in-place round adds rounds to runs that had advisories: bounded by `ROUNDS`, and it never takes the last one.
- A reviewer that never echoes `fixed_in_place` leaves every in-place fix recorded as a finding, the old behavior.
